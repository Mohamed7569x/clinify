"""
APPOINTMENTS
- GET  /appointments/available-slots  → Patient: get open slots for a doctor on a date
- POST /appointments/                 → Patient: book an appointment
- GET  /appointments/                 → List appointments (filtered by role)
- GET  /appointments/{id}             → View single appointment
- PUT  /appointments/{id}/status      → Doctor/Manager: update status (confirm, complete, cancel, etc.)
"""
import uuid
from datetime import date, time, datetime, timedelta
from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import Annotated, Optional
from uuid import UUID
from pydantic import BaseModel
from decimal import Decimal
from sqlalchemy import or_
from app.schemas import models
from app.schemas.models import (
    UserRole, AppointmentStatus, DayOfWeek,
)
from math import ceil
from app.dependencies import (
    db_depends, get_current_user, require_patient,
    get_current_doctor_profile, verify_same_clinic,get_current_patient_profile
)
from app.schemas.api_schemas import (
    AppointmentBook, AppointmentUpdateStatus, AvailableSlot,
    AppointmentStatusEnum,
)
from app.services.notification_service import (
    notify_appointment_booked,
    notify_appointment_confirmed,
    notify_appointment_cancelled,
    notify_appointment_completed,
)

router = APIRouter(prefix="/api/v1/appointments", tags=["Appointments"])


# ─────────────────────────────────────────────
# Enriched Response (includes doctor/patient names)
# ─────────────────────────────────────────────

class AppointmentDetailResponse(BaseModel):
    id:                  UUID
    clinic_id:           UUID
    appointment_number: str
    doctor_id:           UUID
    patient_id:          UUID
    doctor_name:         str = ""
    patient_name:        str = ""
    specialty_name:      Optional[str] = None
    date:                date
    start_time:          time
    end_time:            time
    status:              AppointmentStatusEnum
    consultation_notes:  Optional[str] = None
    cancellation_reason: Optional[str] = None
    created_at:          datetime
    fee_amount: float | None = None
    discount_amount: float | None = None
    total_due_amount: float | None = None
    total_paid_amount: float | None = None
    balance_amount: float | None = None
    payment_status: models.PaymentStatus | None = None
    payment_note: str | None = None

    class Config:
        from_attributes = True

class AppointmentListResponse(BaseModel):
    items: list[AppointmentDetailResponse]
    total: int
    page: int
    limit: int
    pages: int
    
def _enrich(appointment: models.Appointment, db) -> dict:
    """Build enriched response dict with doctor/patient names."""
    data = {
        "id": appointment.id,
        "clinic_id": appointment.clinic_id,
        "appointment_number": appointment.appointment_number,
        "doctor_id": appointment.doctor_id,
        "patient_id": appointment.patient_id,
        "date": appointment.date,
        "start_time": appointment.start_time,
        "end_time": appointment.end_time,
        "status": appointment.status.value if hasattr(appointment.status, 'value') else appointment.status,
        "consultation_notes": appointment.consultation_notes,
        "cancellation_reason": appointment.cancellation_reason,
        "created_at": appointment.created_at,
        "doctor_name": "",
        "patient_name": "",
        "specialty_name": None,
        "fee_amount": appointment.fee_amount,
        "discount_amount": appointment.discount_amount,
        "total_due_amount": appointment.total_due_amount,
        "total_paid_amount": appointment.total_paid_amount,
        "balance_amount": appointment.balance_amount,
        "payment_status": appointment.payment_status,
        "payment_note": appointment.payment_note,
        
    }

    # Doctor name + specialty
    doctor_profile = db.query(models.DoctorProfile).filter(
        models.DoctorProfile.id == appointment.doctor_id
    ).first()
    if doctor_profile:
        doctor_user = db.query(models.User).filter(
            models.User.id == doctor_profile.user_id
        ).first()
        if doctor_user:
            data["doctor_name"] = doctor_user.name
        if doctor_profile.specialty:
            data["specialty_name"] = doctor_profile.specialty.name

    # Patient name
    patient_profile = db.query(models.PatientProfile).filter(
        models.PatientProfile.id == appointment.patient_id
    ).first()
    if patient_profile:
        patient_user = db.query(models.User).filter(
            models.User.id == patient_profile.user_id
        ).first()
        if patient_user:
            data["patient_name"] = patient_user.name

    return data

def generate_appointment_number(db, clinic_id):
    now = datetime.now()
    date_part = now.strftime("%y%m%d")
    suffix = uuid.uuid4().hex[:4].upper()
    return f"CLN-{date_part}-{suffix}"

def generate_unique_appointment_number(db, clinic):
    for _ in range(5):
        number = generate_appointment_number(db, clinic)
        exists = db.query(models.Appointment).filter(
            models.Appointment.appointment_number == number
        ).first()
        

        if not exists:
            return number

    raise Exception("Failed to generate unique appointment number")
# ─────────────────────────────────────────────
# Weekday map
# ─────────────────────────────────────────────

_WEEKDAY_MAP = {
    0: DayOfWeek.MONDAY,
    1: DayOfWeek.TUESDAY,
    2: DayOfWeek.WEDNESDAY,
    3: DayOfWeek.THURSDAY,
    4: DayOfWeek.FRIDAY,
    5: DayOfWeek.SATURDAY,
    6: DayOfWeek.SUNDAY,
}


# ─────────────────────────────────────────────
# GET /appointments/available-slots
# ─────────────────────────────────────────────

@router.get("/available-slots", response_model=list[AvailableSlot])
async def get_available_slots(
    doctor_id: UUID,
    target_date: date,
    current_user: Annotated[models.User, Depends(get_current_user)],
    db: db_depends,
):
    day_enum = _WEEKDAY_MAP[target_date.weekday()]

    schedule = db.query(models.DoctorSchedule).filter(
        models.DoctorSchedule.doctor_id == doctor_id,
        models.DoctorSchedule.day_of_week == day_enum,
        models.DoctorSchedule.is_active == True,
    ).first()

    if not schedule:
        return []

    full_day_block = db.query(models.BlockedSlot).filter(
        models.BlockedSlot.doctor_id == doctor_id,
        models.BlockedSlot.date == target_date,
        models.BlockedSlot.start_time == None,
    ).first()

    if full_day_block:
        return []

    slot_duration = timedelta(minutes=schedule.slot_duration)
    all_slots: list[tuple[time, time]] = []

    current_start = datetime.combine(target_date, schedule.start_time)
    end_boundary = datetime.combine(target_date, schedule.end_time)

    while current_start + slot_duration <= end_boundary:
        slot_end = current_start + slot_duration
        all_slots.append((current_start.time(), slot_end.time()))
        current_start = slot_end

    partial_blocks = (
        db.query(models.BlockedSlot)
        .filter(
            models.BlockedSlot.doctor_id == doctor_id,
            models.BlockedSlot.date == target_date,
            models.BlockedSlot.start_time != None,
        )
        .all()
    )

    def is_blocked(slot_start: time, slot_end: time) -> bool:
        for block in partial_blocks:
            if slot_start < block.end_time and slot_end > block.start_time:
                return True
        return False

    booked = (
        db.query(models.Appointment)
        .filter(
            models.Appointment.doctor_id == doctor_id,
            models.Appointment.date == target_date,
            models.Appointment.status.in_([
                AppointmentStatusEnum.PENDING,
                AppointmentStatusEnum.CONFIRMED,
            ]),
        )
        .all()
    )

    booked_starts = {appt.start_time for appt in booked}

    available = []
    for slot_start, slot_end in all_slots:
        if slot_start in booked_starts:
            continue
        if is_blocked(slot_start, slot_end):
            continue
        available.append(AvailableSlot(start_time=slot_start, end_time=slot_end))

    return available


# ─────────────────────────────────────────────
# POST /appointments/ — Book (enriched + notification)
# ─────────────────────────────────────────────
@router.post("/", response_model=AppointmentDetailResponse, status_code=status.HTTP_201_CREATED)
async def book_appointment(
    payload: AppointmentBook,
    current_user: Annotated[models.User, Depends(require_patient)],
    db: db_depends,
):
    doctor_profile = db.query(models.DoctorProfile).filter(
        models.DoctorProfile.id == payload.doctor_id,
        models.DoctorProfile.clinic_id == current_user.current_clinic_id,
    ).first()

    if not doctor_profile:
        raise HTTPException(status_code=404, detail="Doctor not found.")

    patient_profile = get_current_patient_profile(db, current_user)
    if not patient_profile:
        raise HTTPException(status_code=404, detail="Patient profile not found.")

    day_enum = _WEEKDAY_MAP[payload.date.weekday()]
    schedule = db.query(models.DoctorSchedule).filter(
        models.DoctorSchedule.doctor_id == doctor_profile.id,
        models.DoctorSchedule.day_of_week == day_enum,
        models.DoctorSchedule.is_active == True,
    ).first()

    if not schedule:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Doctor is not available on this day.",
        )

    slot_start_dt = datetime.combine(payload.date, payload.start_time)
    slot_end_dt = slot_start_dt + timedelta(minutes=schedule.slot_duration)
    end_time = slot_end_dt.time()

    conflict = db.query(models.Appointment).filter(
        models.Appointment.clinic_id == current_user.current_clinic_id,
        models.Appointment.doctor_id == doctor_profile.id,
        models.Appointment.date == payload.date,
        models.Appointment.start_time == payload.start_time,
        models.Appointment.status.in_([
            AppointmentStatusEnum.PENDING,
            AppointmentStatusEnum.CONFIRMED,
        ]),
    ).first()

    if conflict:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="This time slot is no longer available.",
        )

    appointment_number = generate_unique_appointment_number(
        db,
        current_user.current_clinic_id,
    )

    appointment = models.Appointment(
        clinic_id=current_user.current_clinic_id,
        appointment_number=appointment_number,
        doctor_id=doctor_profile.id,
        patient_id=patient_profile.id,
        date=payload.date,
        start_time=payload.start_time,
        end_time=end_time,
        status=AppointmentStatusEnum.PENDING,
    )
    db.add(appointment)
    db.flush()
    db.refresh(appointment)

    notify_appointment_booked(db, appointment)

    return _enrich(appointment, db)


# ─────────────────────────────────────────────
# GET /appointments/ — List (enriched)
# ─────────────────────────────────────────────

@router.get("/", response_model=AppointmentListResponse)
async def list_appointments(
    current_user: Annotated[models.User, Depends(get_current_user)],
    db: db_depends,
    status_filter: AppointmentStatus | None = Query(None, alias="status"),
    date_filter: date | None = Query(None, alias="date"),
    q: str | None = Query(None, alias="q"),
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
):
    query = db.query(models.Appointment).filter(
        models.Appointment.clinic_id == current_user.current_clinic_id
    )
    
    
    # ── Role filtering ──
    if current_user.current_role == UserRole.doctor:
        profile = get_current_doctor_profile(db, current_user)
        if not profile:
            raise HTTPException(status_code=404, detail="Doctor profile not found.")
        query = query.filter(models.Appointment.doctor_id == profile.id)

    elif current_user.current_role == UserRole.patient:
        profile = get_current_patient_profile(db, current_user)
        
        if not profile:
            raise HTTPException(status_code=404, detail="Patient profile not found.")
        query = query.filter(models.Appointment.patient_id == profile.id)
        
    
    # ── Filters ──
    if status_filter:
        query = query.filter(models.Appointment.status == status_filter)

    if date_filter:
        query = query.filter(models.Appointment.date == date_filter)

    if q:
        q = q.strip()
        query = (
            query.join(
                models.PatientProfile,
                models.PatientProfile.id == models.Appointment.patient_id
            )
            .join(
                models.User,
                models.User.id == models.PatientProfile.user_id
            )
            .filter(
                or_(
                    models.Appointment.appointment_number.ilike(f"%{q}%"),
                    models.User.name.ilike(f"%{q}%"),
                    models.User.phone_number.ilike(f"%{q}%"),
                )
            )
        )

    total = query.count()
    
    offset = (page - 1) * limit

    appointments = (
        query.order_by(
            models.Appointment.date.desc(),
            models.Appointment.start_time,
        )
        .offset(offset)
        .limit(limit)
        .all()
    )
    
    

    items = [_enrich(a, db) for a in appointments]
    
    return AppointmentListResponse(
        items=items,
        total=total,
        page=page,
        limit=limit,
        pages=ceil(total / limit) if total else 1,
    )
    
@router.get("/mobile", response_model=list[AppointmentDetailResponse])
async def list_appointments_mobile(
    current_user: Annotated[models.User, Depends(get_current_user)],
    db: db_depends,
    status_filter: AppointmentStatus | None = Query(None, alias="status"),
    date_filter: date | None = Query(None, alias="date"),
    q: str | None = Query(None, alias="q"),
):
    query = db.query(models.Appointment).filter(
        models.Appointment.clinic_id == current_user.current_clinic_id
    )
    
    

    if current_user.current_role == UserRole.doctor:
        profile = get_current_doctor_profile(db, current_user)
        if not profile:
            raise HTTPException(status_code=404, detail="Doctor profile not found.")
        query = query.filter(models.Appointment.doctor_id == profile.id)

    elif current_user.current_role == UserRole.patient:
        profile = get_current_patient_profile(db, current_user)
        if not profile:
            raise HTTPException(status_code=404, detail="Patient profile not found.")
        query = query.filter(models.Appointment.patient_id == profile.id)

    if status_filter:
        query = query.filter(models.Appointment.status == status_filter)

    if date_filter:
        query = query.filter(models.Appointment.date == date_filter)

    if q:
        q = q.strip()
        query = (
            query.join(
                models.PatientProfile,
                models.PatientProfile.id == models.Appointment.patient_id
            )
            .join(
                models.User,
                models.User.id == models.PatientProfile.user_id
            )
            .filter(
                or_(
                    models.User.name.ilike(f"%{q}%"),
                    models.User.phone_number.ilike(f"%{q}%"),
                )
            )
        )

    appointments = query.order_by(
        models.Appointment.date.desc(),
        models.Appointment.start_time,
    ).all()
    
    print(appointments)
    
    return [_enrich(a, db) for a in appointments]
# ─────────────────────────────────────────────
# GET /appointments/{id} (enriched)
# ─────────────────────────────────────────────

@router.get("/{appointment_id}", response_model=AppointmentDetailResponse)
async def get_appointment(
    appointment_id: UUID,
    current_user: Annotated[models.User, Depends(get_current_user)],
    db: db_depends,
):
    appointment = db.query(models.Appointment).filter(
        models.Appointment.id == appointment_id
    ).first()

    if not appointment:
        raise HTTPException(status_code=404, detail="Appointment not found.")

    verify_same_clinic(current_user, appointment.clinic_id)
    return _enrich(appointment, db)


# ─────────────────────────────────────────────
# PUT /appointments/{id}/status (enriched + notifications)
# ─────────────────────────────────────────────

@router.put("/{appointment_id}/status", response_model=AppointmentDetailResponse)
async def update_appointment_status(
    appointment_id: UUID,
    payload: AppointmentUpdateStatus,
    current_user: Annotated[models.User, Depends(get_current_user)],
    db: db_depends,
):
    appointment = db.query(models.Appointment).filter(
        models.Appointment.id == appointment_id
    ).first()

    if not appointment:
        raise HTTPException(status_code=404, detail="Appointment not found.")

    verify_same_clinic(current_user, appointment.clinic_id)

    # Patient can only cancel their own
    if current_user.current_role == UserRole.patient:
        patient_profile = get_current_patient_profile(db, current_user)
        if not patient_profile or appointment.patient_id != patient_profile.id:
            raise HTTPException(status_code=403, detail="Not your appointment.")
        if payload.status != AppointmentStatusEnum.CANCELLED:
            print(payload.status)
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Patients can only cancel appointments.",
            )

    appointment.status = payload.status

    if payload.cancellation_reason:
        appointment.cancellation_reason = payload.cancellation_reason
    if payload.consultation_notes:
        appointment.consultation_notes = payload.consultation_notes

    db.flush()
    db.refresh(appointment)

    # ── Send notifications based on new status ──
    if payload.status == AppointmentStatusEnum.CONFIRMED:
        notify_appointment_confirmed(db, appointment)

    elif payload.status == AppointmentStatusEnum.CANCELLED:
        cancelled_by = "patient" if current_user.current_role == UserRole.patient else "doctor"
        notify_appointment_cancelled(db, appointment, cancelled_by)

    elif payload.status == AppointmentStatusEnum.COMPLETED:
        notify_appointment_completed(db, appointment)

    return _enrich(appointment, db)