"""
CHAT MESSAGES
Doctor ↔ Patient text chat scoped to an appointment.
"""

from fastapi import APIRouter, Depends, HTTPException, status
from typing import Annotated
from uuid import UUID

from app.schemas import models
from app.schemas.models import UserRole, ChatMessageSender
from app.dependencies import (
    db_depends, get_current_user, verify_same_clinic,get_current_patient_profile, get_current_doctor_profile
)
from app.schemas.api_schemas import ChatMessageCreate, ChatMessageResponse

router = APIRouter(prefix="/api/v1/appointments/{appointment_id}/chat", tags=["Chat"])


def _get_appointment_or_404(appointment_id: UUID, current_user: models.User, db):
    appointment = db.query(models.Appointment).filter(
        models.Appointment.id == appointment_id
    ).first()
    if not appointment:
        raise HTTPException(status_code=404, detail="Appointment not found.")
    verify_same_clinic(current_user, appointment.clinic_id)
    return appointment


def _sender_role(user: models.User) -> ChatMessageSender:
    if user.role == UserRole.doctor:
        return ChatMessageSender.DOCTOR
    elif user.role == UserRole.patient:
        return ChatMessageSender.PATIENT
    raise HTTPException(status_code=403, detail="Only doctors and patients can chat.")


# ─────────────────────────────────────────────
# POST — Send a message
# ─────────────────────────────────────────────

@router.post("/", response_model=ChatMessageResponse, status_code=status.HTTP_201_CREATED)
async def send_message(
    appointment_id: UUID,
    payload: ChatMessageCreate,
    current_user: Annotated[models.User, Depends(get_current_user)],
    db: db_depends,
):
    appointment = _get_appointment_or_404(appointment_id, current_user, db)
    sender_role = _sender_role(current_user)

    message = models.ChatMessage(
        appointment_id=appointment.id,
        sender_id=current_user.id,
        sender_role=sender_role,
        message=payload.message,
    )
    db.add(message)
    db.flush()
    db.refresh(message)
    return message


# ─────────────────────────────────────────────
# GET — List messages for an appointment
# ─────────────────────────────────────────────

@router.get("/", response_model=list[ChatMessageResponse])
async def list_messages(
    appointment_id: UUID,
    current_user: Annotated[models.User, Depends(get_current_user)],
    db: db_depends,
):
    appointment = _get_appointment_or_404(appointment_id, current_user, db)

    # Only doctor/patient of this appointment (or manager) can view
    if current_user.role == UserRole.patient:
        patient_profile = get_current_patient_profile(db, current_user)
        if not patient_profile or appointment.patient_id != patient_profile.id:
            raise HTTPException(status_code=403, detail="Not your appointment.")

    elif current_user.role == UserRole.doctor:
        doctor_profile = get_current_doctor_profile(db, current_user)
        if not doctor_profile or appointment.doctor_id != doctor_profile.id:
            raise HTTPException(status_code=403, detail="Not your appointment.")

    return (
        db.query(models.ChatMessage)
        .filter(models.ChatMessage.appointment_id == appointment.id)
        .order_by(models.ChatMessage.created_at.asc())
        .all()
    )


# ─────────────────────────────────────────────
# PATCH — Mark messages as read
# ─────────────────────────────────────────────

@router.patch("/read", status_code=status.HTTP_204_NO_CONTENT)
async def mark_messages_read(
    appointment_id: UUID,
    current_user: Annotated[models.User, Depends(get_current_user)],
    db: db_depends,
):
    """Marks all messages NOT sent by the current user as read."""
    appointment = _get_appointment_or_404(appointment_id, current_user, db)

    db.query(models.ChatMessage).filter(
        models.ChatMessage.appointment_id == appointment.id,
        models.ChatMessage.sender_id != current_user.id,
        models.ChatMessage.is_read == False,
    ).update({"is_read": True})

    db.flush()
