"""
PATIENTS
- GET  /patients/me         → Mobile: Patient views own profile
- PUT  /patients/me         → Mobile: Patient updates own profile
- GET  /patients/           → Web: Manager lists all patients in clinic
- GET  /patients/{id}       → Web/Mobile: View single patient (manager or own)

NOTE: Patient registration is handled in auth.py (POST /api/v1/auth/patient/register/)
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy import or_
from typing import Annotated
from uuid import UUID
from math import ceil
from pydantic import BaseModel
from app.schemas import models
from app.schemas.models import UserRole
from app.dependencies import (
    db_depends, require_manager, require_patient, get_current_user,
    verify_same_clinic,
)
from app.schemas.api_schemas import (
    PatientProfileUpdate, PatientFullResponse,
    UserResponse, PatientProfileResponse,
)
from app.services.notification_service import notify_account_approved

router = APIRouter(prefix="/api/v1/patients", tags=["Patients"])


# ─────────────────────────────────────────────
# Helper
# ─────────────────────────────────────────────

def _patient_response(user: models.User) -> PatientFullResponse:
    return PatientFullResponse(
        user=UserResponse.model_validate(user),
        profile=PatientProfileResponse.model_validate(user.patient_profile),
    )

class PatientListResponse(BaseModel):
    items: list[PatientFullResponse]
    total: int
    page: int
    limit: int
    pages: int
# ─────────────────────────────────────────────
# GET  /patients/me — Patient views own profile
# ─────────────────────────────────────────────

@router.get("/me", response_model=PatientFullResponse)
async def get_my_profile(
    current_user: Annotated[models.User, Depends(require_patient)],
    db: db_depends,
):
    return _patient_response(current_user)


# ─────────────────────────────────────────────
# PUT  /patients/me — Patient updates own profile
# ─────────────────────────────────────────────

@router.put("/me", response_model=PatientFullResponse)
async def update_my_profile(
    payload: PatientProfileUpdate,
    current_user: Annotated[models.User, Depends(require_patient)],
    db: db_depends,
):
    update_data = payload.model_dump(exclude_unset=True)

    user_fields    = {"name", "email", "phone_number", "gender", "date_of_birth"}
    profile_fields = {
        "blood_type", "allergies", "chronic_conditions",
        "emergency_contact_name", "emergency_contact_phone",
    }

    for field, value in update_data.items():
        if field in user_fields:
            setattr(current_user, field, value)
        elif field in profile_fields and current_user.patient_profile:
            setattr(current_user.patient_profile, field, value)

    db.flush()
    db.refresh(current_user)
    return _patient_response(current_user)


# ─────────────────────────────────────────────
# GET  /patients/ — Manager lists clinic patients
# ─────────────────────────────────────────────

@router.get("/", response_model=PatientListResponse)
async def list_patients(
    current_user: Annotated[models.User, Depends(require_manager)],
    db: db_depends,
    q: str | None = Query(None, alias="q"),
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
):
    query = (
        db.query(models.User)
        .join(
            models.ClinicMembership,
            models.ClinicMembership.user_id == models.User.id,
        )
        .filter(
            models.ClinicMembership.clinic_id == current_user.current_clinic_id,
            models.ClinicMembership.role == UserRole.patient,
            # models.ClinicMembership.is_active == True,
        )
    )

    if q:
        q = q.strip()
        query = query.filter(
            or_(
                models.User.name.ilike(f"%{q}%"),
                models.User.email.ilike(f"%{q}%"),
                models.User.phone_number.ilike(f"%{q}%"),
            )
        )

    total = query.count()
    offset = (page - 1) * limit

    patients = (
        query.order_by(models.User.created_at.desc())
        .offset(offset)
        .limit(limit)
        .all()
    )

    return PatientListResponse(
        items=[_patient_response(p) for p in patients],
        total=total,
        page=page,
        limit=limit,
        pages=ceil(total / limit) if total else 1,
    )


# ─────────────────────────────────────────────
# GET  /patients/{id} — View single patient
# ─────────────────────────────────────────────

@router.get("/{patient_user_id}", response_model=PatientFullResponse)
async def get_patient(
    patient_user_id: UUID,
    current_user: Annotated[models.User, Depends(get_current_user)],
    db: db_depends,
):
    """Accessible by managers and the patient themselves."""
    patient = db.query(models.User).filter(
        models.User.id == patient_user_id,
        models.User.role == UserRole.patient,
    ).first()

    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found.")

    verify_same_clinic(current_user, patient.clinic_id)

    # Patients can only view their own profile; managers can view any
    if current_user.current_role == UserRole.patient and current_user.id != patient.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You can only view your own profile.",
        )

    return _patient_response(patient)


# ─────────────────────────────────────────────
# PATCH /patients/{id}/activate — Manager approves patient
# ─────────────────────────────────────────────

@router.patch("/{patient_user_id}/activate", response_model=UserResponse)
async def activate_patient(
    patient_user_id: UUID,
    current_user: Annotated[models.User, Depends(require_manager)],
    db: db_depends,
):
    patient = db.query(models.User).filter(
        models.User.id == patient_user_id,
        models.User.role == UserRole.patient,
    ).first()

    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found.")

    verify_same_clinic(current_user, patient.clinic_id)
    patient.is_active = True
    db.flush()
    db.refresh(patient)

    # Notify patient that their account is approved
    notify_account_approved(db, patient.id)

    return patient


# ─────────────────────────────────────────────
# PATCH /patients/{id}/deactivate — Manager deactivates patient
# ─────────────────────────────────────────────

@router.patch("/{patient_user_id}/deactivate", response_model=UserResponse)
async def deactivate_patient(
    patient_user_id: UUID,
    current_user: Annotated[models.User, Depends(require_manager)],
    db: db_depends,
):
    patient = db.query(models.User).filter(
        models.User.id == patient_user_id,
        models.User.role == UserRole.patient,
    ).first()

    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found.")

    verify_same_clinic(current_user, patient.clinic_id)
    patient.is_active = False
    db.flush()
    db.refresh(patient)
    return patient