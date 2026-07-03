"""
PRESCRIPTIONS
Doctor creates prescriptions attached to an appointment.
Doctor, patient (own), and manager can view them.
"""

from fastapi import APIRouter, Depends, HTTPException, status
from typing import Annotated
from uuid import UUID

from app.schemas import models
from app.schemas.models import UserRole
from app.dependencies import (
    db_depends, require_doctor, get_current_user, verify_same_clinic,get_current_doctor_profile
)
from app.schemas.api_schemas import PrescriptionCreate, PrescriptionResponse, BulkPrescriptionCreate, BulkPrescriptionResponse
from app.services.notification_service import notify_prescription_added

router = APIRouter(prefix="/api/v1/appointments/{appointment_id}/prescriptions", tags=["Prescriptions"])


# ─────────────────────────────────────────────
# Helper — fetch appointment and verify access
# ─────────────────────────────────────────────

def _get_appointment_or_404(appointment_id: UUID, current_user: models.User, db):
    appointment = db.query(models.Appointment).filter(
        models.Appointment.id == appointment_id
    ).first()

    if not appointment:
        raise HTTPException(status_code=404, detail="Appointment not found.")

    verify_same_clinic(current_user, appointment.clinic_id)
    return appointment


# ─────────────────────────────────────────────
# POST — Doctor adds prescription
# ─────────────────────────────────────────────

@router.post("/", response_model=PrescriptionResponse, status_code=status.HTTP_201_CREATED)
async def create_prescription(
    appointment_id: UUID,
    payload: PrescriptionCreate,
    current_user: Annotated[models.User, Depends(require_doctor)],
    db: db_depends,
):
    appointment = _get_appointment_or_404(appointment_id, current_user, db)

    # Verify doctor owns this appointment
    doctor_profile = get_current_doctor_profile(db, current_user)

    if not doctor_profile or appointment.doctor_id != doctor_profile.id:
        raise HTTPException(status_code=403, detail="Not your appointment.")

    prescription = models.Prescription(
        appointment_id=appointment.id,
        medication=payload.medication,
        dosage=payload.dosage,
        frequency=payload.frequency,
        duration=payload.duration,
        notes=payload.notes,
    )
    db.add(prescription)
    db.flush()
    db.refresh(prescription)

    # Notify patient
    notify_prescription_added(db, appointment)

    return prescription

@router.post(
    "/bulk",
    response_model=BulkPrescriptionResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_prescriptions_bulk(
    appointment_id: UUID,
    payload: BulkPrescriptionCreate,
    current_user: Annotated[models.User, Depends(require_doctor)],
    db: db_depends,
):
    appointment = _get_appointment_or_404(appointment_id, current_user, db)

    doctor_profile = get_current_doctor_profile(db, current_user)

    if not doctor_profile or appointment.doctor_id != doctor_profile.id:
        raise HTTPException(status_code=403, detail="Not your appointment.")

    created_prescriptions = []

    for item in payload.items:
        medication = (item.medication or "").strip()
        if not medication:
            raise HTTPException(
                status_code=400,
                detail="Medication name is required for every prescription."
            )

        prescription = models.Prescription(
            appointment_id=appointment.id,
            medication=medication,
            dosage=(item.dosage or "").strip() or None,
            frequency=(item.frequency or "").strip() or None,
            duration=(item.duration or "").strip() or None,
            notes=(item.notes or "").strip() or None,
        )
        db.add(prescription)
        created_prescriptions.append(prescription)

    db.flush()

    for prescription in created_prescriptions:
        db.refresh(prescription)

    notify_prescription_added(db, appointment)

    return BulkPrescriptionResponse(
        items=created_prescriptions,
        count=len(created_prescriptions),
    )
    
@router.put(
    "/bulk",
    response_model=BulkPrescriptionResponse,
    status_code=status.HTTP_200_OK,
)
async def replace_prescriptions_bulk(
    appointment_id: UUID,
    payload: BulkPrescriptionCreate,
    current_user: Annotated[models.User, Depends(require_doctor)],
    db: db_depends,
):
    appointment = _get_appointment_or_404(appointment_id, current_user, db)

    doctor_profile = get_current_doctor_profile(db, current_user)

    if not doctor_profile or appointment.doctor_id != doctor_profile.id:
        raise HTTPException(status_code=403, detail="Not your appointment.")

    if not payload.items:
        raise HTTPException(
            status_code=400,
            detail="At least one prescription is required."
        )

    try:
        db.query(models.Prescription).filter(
            models.Prescription.appointment_id == appointment.id
        ).delete(synchronize_session=False)

        created_prescriptions = []

        for item in payload.items:
            medication = (item.medication or "").strip()
            if not medication:
                raise HTTPException(
                    status_code=400,
                    detail="Medication name is required for every prescription."
                )

            prescription = models.Prescription(
                appointment_id=appointment.id,
                medication=medication,
                dosage=(item.dosage or "").strip() or None,
                frequency=(item.frequency or "").strip() or None,
                duration=(item.duration or "").strip() or None,
                notes=(item.notes or "").strip() or None,
            )
            db.add(prescription)
            created_prescriptions.append(prescription)

        db.flush()

        for prescription in created_prescriptions:
            db.refresh(prescription)

        notify_prescription_added(db, appointment)

        return BulkPrescriptionResponse(
            items=created_prescriptions,
            count=len(created_prescriptions),
        )

    except HTTPException:
        raise
    except Exception:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail="Failed to replace prescriptions."
        )
# ─────────────────────────────────────────────
# GET — List prescriptions for an appointment
# ─────────────────────────────────────────────

@router.get("/", response_model=list[PrescriptionResponse])
async def list_prescriptions(
    appointment_id: UUID,
    current_user: Annotated[models.User, Depends(get_current_user)],
    db: db_depends,
):
    appointment = _get_appointment_or_404(appointment_id, current_user, db)

    return (
        db.query(models.Prescription)
        .filter(models.Prescription.appointment_id == appointment.id)
        .all()
    )