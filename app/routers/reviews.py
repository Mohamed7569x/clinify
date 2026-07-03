"""
DOCTOR REVIEWS
Patient leaves a review after a completed appointment.
Updates the doctor's average rating.
"""

from fastapi import APIRouter, Depends, HTTPException, status
from typing import Annotated
from uuid import UUID

from app.schemas import models
from app.schemas.models import UserRole, AppointmentStatus
from app.dependencies import (
    db_depends, require_patient, get_current_user, verify_same_clinic,get_current_patient_profile,get_current_doctor_profile
)
from app.schemas.api_schemas import ReviewCreate, ReviewResponse

router = APIRouter(prefix="/api/v1/appointments/{appointment_id}/review", tags=["Reviews"])


# ─────────────────────────────────────────────
# POST — Patient submits a review
# ─────────────────────────────────────────────

@router.post("/", response_model=ReviewResponse, status_code=status.HTTP_201_CREATED)
async def create_review(
    appointment_id: UUID,
    payload: ReviewCreate,
    current_user: Annotated[models.User, Depends(require_patient)],
    db: db_depends,
):
    appointment = db.query(models.Appointment).filter(
        models.Appointment.id == appointment_id
    ).first()

    if not appointment:
        raise HTTPException(status_code=404, detail="Appointment not found.")

    verify_same_clinic(current_user, appointment.clinic_id)

    # ── Must be completed ──
    if appointment.status != AppointmentStatus.COMPLETED:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You can only review completed appointments.",
        )

    # ── Must be the patient of this appointment ──
    patient_profile = get_current_patient_profile(db, current_user)

    if not patient_profile or appointment.patient_id != patient_profile.id:
        raise HTTPException(status_code=403, detail="Not your appointment.")

    # ── One review per appointment ──
    existing = db.query(models.DoctorReview).filter(
        models.DoctorReview.appointment_id == appointment.id
    ).first()

    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="You have already reviewed this appointment.",
        )

    review = models.DoctorReview(
        appointment_id=appointment.id,
        patient_id=patient_profile.id,
        doctor_id=appointment.doctor_id,
        rating=payload.rating,
        comment=payload.comment,
    )
    db.add(review)
    db.flush()

    # ── Update doctor's average rating ──
    doctor_profile = get_current_doctor_profile(db, current_user)

    if doctor_profile:
        new_total  = doctor_profile.total_reviews + 1
        new_rating = (
            (doctor_profile.rating * doctor_profile.total_reviews) + payload.rating
        ) / new_total
        doctor_profile.rating        = round(new_rating, 2)
        doctor_profile.total_reviews = new_total

    db.flush()
    db.refresh(review)
    return review


# ─────────────────────────────────────────────
# GET — View review for an appointment
# ─────────────────────────────────────────────

@router.get("/", response_model=ReviewResponse)
async def get_review(
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

    review = db.query(models.DoctorReview).filter(
        models.DoctorReview.appointment_id == appointment.id
    ).first()

    if not review:
        raise HTTPException(status_code=404, detail="No review found for this appointment.")

    return review
