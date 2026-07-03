"""
WEB DASHBOARD — Doctor Management
Manager creates, lists, updates, activates/deactivates doctors.
"""

from fastapi import APIRouter, Depends, HTTPException, status
from typing import Annotated
from uuid import UUID

from app.schemas import models
from app.schemas.models import UserRole, SubscriptionPlan
from app.dependencies import (
    db_depends, require_manager, get_current_user,
    verify_same_clinic, get_password_hash,get_current_doctor_profile
)
from app.schemas.api_schemas import (
    DoctorCreate, DoctorUpdate, DoctorFullResponse,
    UserResponse, DoctorProfileResponse, SpecialtyResponse,
)

router = APIRouter(prefix="/api/v1/doctors", tags=["Doctors"])


# ─────────────────────────────────────────────
# Helper — build full doctor response
# ─────────────────────────────────────────────

def _doctor_response(user: models.User) -> DoctorFullResponse:
    profile = user.doctor_profile
    specialty_resp = None
    if profile and profile.specialty:
        specialty_resp = SpecialtyResponse.model_validate(profile.specialty)

    return DoctorFullResponse(
        user=UserResponse.model_validate(user),
        profile=DoctorProfileResponse.model_validate(profile),
        specialty=specialty_resp,
    )


# ─────────────────────────────────────────────
# GET  /doctors — List all doctors in my clinic
# ─────────────────────────────────────────────

@router.get("/", response_model=list[DoctorFullResponse])
async def list_doctors(
    current_user: Annotated[models.User, Depends(get_current_user)],
    db: db_depends,
):
    doctors = (
    db.query(models.User)
    .join(
        models.ClinicMembership,
        models.ClinicMembership.user_id == models.User.id
    )
    .filter(
        models.ClinicMembership.clinic_id == current_user.current_clinic_id,
        models.ClinicMembership.role == UserRole.doctor,
        models.ClinicMembership.is_active == True,
    )
    .all()
)

    return [_doctor_response(d) for d in doctors]


# ─────────────────────────────────────────────
# GET  /doctors/{id} — Single doctor detail
# ─────────────────────────────────────────────

@router.get("/{doctor_user_id}", response_model=DoctorFullResponse)
async def get_doctor(
    doctor_user_id: UUID,
    current_user: Annotated[models.User, Depends(require_manager)],
    db: db_depends,
):
    doctor = db.query(models.User).filter(
        models.User.id == doctor_user_id,
        models.User.role == UserRole.doctor,
    ).first()

    if not doctor:
        raise HTTPException(status_code=404, detail="Doctor not found.")

    verify_same_clinic(current_user, doctor.clinic_id)
    return _doctor_response(doctor)


# ─────────────────────────────────────────────
# POST /doctors — Register a new doctor
# ─────────────────────────────────────────────
@router.post("/", response_model=DoctorFullResponse, status_code=status.HTTP_201_CREATED)
async def create_doctor(
    payload: DoctorCreate,
    current_user: Annotated[models.User, Depends(require_manager)],
    db: db_depends,
):
    clinic_id = current_user.current_clinic_id
    current_clinic = current_user.current_clinic

    # ── Check subscription doctor limit ──
    subscription = db.query(models.Subscription).filter(
        models.Subscription.clinic_id == clinic_id
    ).first()

    if subscription:
        current_count = db.query(models.ClinicMembership).filter(
            models.ClinicMembership.clinic_id == clinic_id,
            models.ClinicMembership.role == UserRole.doctor,
            models.ClinicMembership.is_active == True,
        ).count()

        if current_count >= subscription.max_doctors:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=(
                    f"Doctor limit reached ({subscription.max_doctors}). "
                    f"Upgrade your plan to add more doctors."
                ),
            )

    # ── Check duplicate email in this branch ──
    if payload.email:
        existing_user = db.query(models.User).filter(
            models.User.email == payload.email
        ).first()

        if existing_user:
            existing_membership = db.query(models.ClinicMembership).filter(
                models.ClinicMembership.user_id == existing_user.id,
                models.ClinicMembership.clinic_id == clinic_id,
                models.ClinicMembership.role == UserRole.doctor,
            ).first()

            if existing_membership:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="A doctor with this email already exists in this branch.",
                )

    # ── Check duplicate phone in this branch ──
    if payload.phone_number:
        existing_user = db.query(models.User).filter(
            models.User.phone_number == payload.phone_number
        ).first()

        if existing_user:
            existing_membership = db.query(models.ClinicMembership).filter(
                models.ClinicMembership.user_id == existing_user.id,
                models.ClinicMembership.clinic_id == clinic_id,
                models.ClinicMembership.role == UserRole.doctor,
            ).first()

            if existing_membership:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="A doctor with this phone number already exists in this branch.",
                )

    # ── Validate specialty belongs to same branch ──
    if payload.specialty_id:
        specialty = db.query(models.Specialty).filter(
            models.Specialty.id == payload.specialty_id,
            models.Specialty.clinic_id == clinic_id,
        ).first()

        if not specialty:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Specialty not found in this branch.",
            )

    # ── Create User row ──
    user = models.User(
        role=UserRole.doctor,
        name=payload.name,
        email=payload.email,
        phone_number=payload.phone_number,
        password_hash=get_password_hash(payload.password),
        gender=payload.gender,
        date_of_birth=payload.date_of_birth,
        is_active=True,
    )
    db.add(user)
    db.flush()

    # ── Create clinic membership row ──
    membership = models.ClinicMembership(
        clinic_id=clinic_id,
        user_id=user.id,
        role=UserRole.doctor,
        is_active=True,
    )
    db.add(membership)
    db.flush()

    # ── Create DoctorProfile row ──
    profile = models.DoctorProfile(
        user_id=user.id,
        clinic_id=clinic_id,
        specialty_id=payload.specialty_id,
        bio=payload.bio,
        license_number=payload.license_number,
    )
    db.add(profile)
    db.flush()

    db.refresh(user)

    return _doctor_response(user)


# ─────────────────────────────────────────────
# PUT  /doctors/{id} — Update doctor info
# ─────────────────────────────────────────────

@router.put("/{doctor_user_id}", response_model=DoctorFullResponse)
async def update_doctor(
    doctor_user_id: UUID,
    payload: DoctorUpdate,
    current_user: Annotated[models.User, Depends(require_manager)],
    db: db_depends,
):
    doctor = db.query(models.User).filter(
        models.User.id == doctor_user_id,
        models.User.role == UserRole.doctor,
    ).first()

    if not doctor:
        raise HTTPException(status_code=404, detail="Doctor not found.")

    verify_same_clinic(current_user, doctor.clinic_id)

    update_data = payload.model_dump(exclude_unset=True)

    # Separate user-level vs profile-level fields
    user_fields    = {"name", "email", "phone_number", "gender", "date_of_birth"}
    profile_fields = {"specialty_id", "bio", "license_number"}

    for field, value in update_data.items():
        if field in user_fields:
            setattr(doctor, field, value)
        elif field in profile_fields and doctor.doctor_profile:
            setattr(doctor.doctor_profile, field, value)

    db.flush()
    db.refresh(doctor)
    return _doctor_response(doctor)


# ─────────────────────────────────────────────
# PATCH /doctors/{id}/activate
# PATCH /doctors/{id}/deactivate
# ─────────────────────────────────────────────

@router.patch("/{doctor_user_id}/activate", response_model=UserResponse)
async def activate_doctor(
    doctor_user_id: UUID,
    current_user: Annotated[models.User, Depends(require_manager)],
    db: db_depends,
):
    doctor = db.query(models.User).filter(
        models.User.id == doctor_user_id,
        models.User.role == UserRole.doctor,
    ).first()

    if not doctor:
        raise HTTPException(status_code=404, detail="Doctor not found.")

    verify_same_clinic(current_user, doctor.clinic_id)
    doctor.is_active = True
    db.flush()
    db.refresh(doctor)
    return doctor


@router.patch("/{doctor_user_id}/deactivate", response_model=UserResponse)
async def deactivate_doctor(
    doctor_user_id: UUID,
    current_user: Annotated[models.User, Depends(require_manager)],
    db: db_depends,
):
    doctor = db.query(models.User).filter(
        models.User.id == doctor_user_id,
        models.User.role == UserRole.doctor,
    ).first()

    if not doctor:
        raise HTTPException(status_code=404, detail="Doctor not found.")

    verify_same_clinic(current_user, doctor.clinic_id)
    doctor.is_active = False
    db.flush()
    db.refresh(doctor)
    return doctor
