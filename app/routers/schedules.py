"""
MOBILE — Doctor Schedule & Blocked Slots
Doctor manages their weekly recurring schedule and one-off blocked slots.
Manager can also view schedules.
"""

from fastapi import APIRouter, Depends, HTTPException, status
from typing import Annotated
from uuid import UUID

from app.schemas import models
from app.schemas.models import UserRole
from app.dependencies import (
    db_depends, require_doctor, require_doctor_or_manager,
    get_current_doctor_profile, verify_same_clinic,
)
from app.schemas.api_schemas import (
    ScheduleCreate, ScheduleUpdate, ScheduleResponse,
    BlockedSlotCreate, BlockedSlotResponse,
)

router = APIRouter(prefix="/api/v1/schedules", tags=["Schedules"])


# ─────────────────────────────────────────────
# Helper — get doctor profile for current user
# ─────────────────────────────────────────────

def _get_doctor_profile(user: models.User, db) -> models.DoctorProfile:
    profile = get_current_doctor_profile(db, user)
    if not profile:
        raise HTTPException(status_code=404, detail="Doctor profile not found.")
    return profile


# ═══════════════════════════════════════════════
# WEEKLY SCHEDULE
# ═══════════════════════════════════════════════

# ─────────────────────────────────────────────
# GET  /schedules/ — List my schedules (doctor) or all in clinic (manager)
# ─────────────────────────────────────────────

@router.get("/", response_model=list[ScheduleResponse])
async def list_schedules(
    current_user: Annotated[models.User, Depends(require_doctor_or_manager)],
    db: db_depends,
    doctor_id: UUID | None = None,   # Manager can filter by doctor
):
    if current_user.current_role == UserRole.doctor:
        profile = _get_doctor_profile(current_user, db)
        return (
            db.query(models.DoctorSchedule)
            .filter(models.DoctorSchedule.doctor_id == profile.id)
            .all()
        )

    # Manager — list schedules for a specific doctor or all
    query = (
        db.query(models.DoctorSchedule)
        .join(models.DoctorProfile)
        .join(models.User, models.DoctorProfile.user_id == models.User.id)
        .filter(models.User.clinic_id == current_user.clinic_id)
    )
    if doctor_id:
        query = query.filter(models.DoctorSchedule.doctor_id == doctor_id)

    return query.all()


# ─────────────────────────────────────────────
# POST /schedules/ — Doctor creates a schedule entry
# ─────────────────────────────────────────────

@router.post("/", response_model=ScheduleResponse, status_code=status.HTTP_201_CREATED)
async def create_schedule(
    payload: ScheduleCreate,
    current_user: Annotated[models.User, Depends(require_doctor)],
    db: db_depends,
):
    profile = _get_doctor_profile(current_user, db)

    # Check duplicate day
    exists = db.query(models.DoctorSchedule).filter(
        models.DoctorSchedule.doctor_id == profile.id,
        models.DoctorSchedule.day_of_week == payload.day_of_week,
    ).first()
    if exists:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Schedule for {payload.day_of_week.value} already exists. "
                   f"Update it instead.",
        )

    schedule = models.DoctorSchedule(
        doctor_id=profile.id,
        day_of_week=payload.day_of_week,
        start_time=payload.start_time,
        end_time=payload.end_time,
        slot_duration=payload.slot_duration,
    )
    db.add(schedule)
    db.flush()
    db.refresh(schedule)
    return schedule


# ─────────────────────────────────────────────
# PUT  /schedules/{id} — Update schedule entry
# ─────────────────────────────────────────────

@router.put("/{schedule_id}", response_model=ScheduleResponse)
async def update_schedule(
    schedule_id: UUID,
    payload: ScheduleUpdate,
    current_user: Annotated[models.User, Depends(require_doctor)],
    db: db_depends,
):
    profile = _get_doctor_profile(current_user, db)

    schedule = db.query(models.DoctorSchedule).filter(
        models.DoctorSchedule.id == schedule_id,
        models.DoctorSchedule.doctor_id == profile.id,
    ).first()

    if not schedule:
        raise HTTPException(status_code=404, detail="Schedule not found.")

    update_data = payload.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(schedule, field, value)

    db.flush()
    db.refresh(schedule)
    return schedule


# ─────────────────────────────────────────────
# DELETE /schedules/{id}
# ─────────────────────────────────────────────

@router.delete("/{schedule_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_schedule(
    schedule_id: UUID,
    current_user: Annotated[models.User, Depends(require_doctor)],
    db: db_depends,
):
    profile = _get_doctor_profile(current_user, db)

    schedule = db.query(models.DoctorSchedule).filter(
        models.DoctorSchedule.id == schedule_id,
        models.DoctorSchedule.doctor_id == profile.id,
    ).first()

    if not schedule:
        raise HTTPException(status_code=404, detail="Schedule not found.")

    db.delete(schedule)
    db.flush()


# ═══════════════════════════════════════════════
# BLOCKED SLOTS
# ═══════════════════════════════════════════════

blocked_router = APIRouter(prefix="/api/v1/blocked-slots", tags=["Blocked Slots"])


@blocked_router.get("/", response_model=list[BlockedSlotResponse])
async def list_blocked_slots(
    current_user: Annotated[models.User, Depends(require_doctor)],
    db: db_depends,
):
    profile = _get_doctor_profile(current_user, db)
    return (
        db.query(models.BlockedSlot)
        .filter(models.BlockedSlot.doctor_id == profile.id)
        .all()
    )


@blocked_router.post("/", response_model=BlockedSlotResponse, status_code=status.HTTP_201_CREATED)
async def create_blocked_slot(
    payload: BlockedSlotCreate,
    current_user: Annotated[models.User, Depends(require_doctor)],
    db: db_depends,
):
    profile = _get_doctor_profile(current_user, db)

    slot = models.BlockedSlot(
        doctor_id=profile.id,
        date=payload.date,
        start_time=payload.start_time,
        end_time=payload.end_time,
        reason=payload.reason,
    )
    db.add(slot)
    db.flush()
    db.refresh(slot)
    return slot


@blocked_router.delete("/{slot_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_blocked_slot(
    slot_id: UUID,
    current_user: Annotated[models.User, Depends(require_doctor)],
    db: db_depends,
):
    profile = _get_doctor_profile(current_user, db)

    slot = db.query(models.BlockedSlot).filter(
        models.BlockedSlot.id == slot_id,
        models.BlockedSlot.doctor_id == profile.id,
    ).first()

    if not slot:
        raise HTTPException(status_code=404, detail="Blocked slot not found.")

    db.delete(slot)
    db.flush()
