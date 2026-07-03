"""
WEB DASHBOARD — Specialty Management
Manager creates/updates/deletes specialties for their clinic.
Mobile apps can also list specialties (read-only).
"""

from fastapi import APIRouter, Depends, HTTPException, status
from typing import Annotated
from uuid import UUID

from app.schemas import models
from app.dependencies import (
    db_depends, require_manager, get_current_user, verify_same_clinic,
)
from app.schemas.api_schemas import SpecialtyCreate, SpecialtyResponse

router = APIRouter(prefix="/api/v1/specialties", tags=["Specialties"])


# ─────────────────────────────────────────────
# GET  /specialties — List all specialties in my clinic
# ─────────────────────────────────────────────

@router.get("/", response_model=list[SpecialtyResponse])
async def list_specialties(
    current_user: Annotated[models.User, Depends(get_current_user)],
    db: db_depends,
):
    return (
        db.query(models.Specialty)
        .filter(models.Specialty.clinic_id == current_user.current_clinic_id)
        .all()
    )


# ─────────────────────────────────────────────
# POST /specialties — Create a new specialty
# ─────────────────────────────────────────────

@router.post("/", response_model=SpecialtyResponse, status_code=status.HTTP_201_CREATED)
async def create_specialty(
    payload: SpecialtyCreate,
    current_user: Annotated[models.User, Depends(require_manager)],
    db: db_depends,
):
    # Check for duplicate name within clinic
    exists = (
        db.query(models.Specialty)
        .filter(
            models.Specialty.clinic_id == current_user.clinic_id,
            models.Specialty.name == payload.name,
        )
        .first()
    )
    if exists:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Specialty '{payload.name}' already exists in this clinic.",
        )

    specialty = models.Specialty(
        clinic_id=current_user.clinic_id,
        name=payload.name,
    )
    db.add(specialty)
    db.flush()
    db.refresh(specialty)
    return specialty


# ─────────────────────────────────────────────
# PUT  /specialties/{id} — Rename a specialty
# ─────────────────────────────────────────────

@router.put("/{specialty_id}", response_model=SpecialtyResponse)
async def update_specialty(
    specialty_id: UUID,
    payload: SpecialtyCreate,
    current_user: Annotated[models.User, Depends(require_manager)],
    db: db_depends,
):
    specialty = db.query(models.Specialty).filter(
        models.Specialty.id == specialty_id
    ).first()

    if not specialty:
        raise HTTPException(status_code=404, detail="Specialty not found.")

    verify_same_clinic(current_user, specialty.clinic_id)

    specialty.name = payload.name
    db.flush()
    db.refresh(specialty)
    return specialty


# ─────────────────────────────────────────────
# DELETE /specialties/{id}
# ─────────────────────────────────────────────

@router.delete("/{specialty_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_specialty(
    specialty_id: UUID,
    current_user: Annotated[models.User, Depends(require_manager)],
    db: db_depends,
):
    specialty = db.query(models.Specialty).filter(
        models.Specialty.id == specialty_id
    ).first()

    if not specialty:
        raise HTTPException(status_code=404, detail="Specialty not found.")

    verify_same_clinic(current_user, specialty.clinic_id)

    # Nullify doctors linked to this specialty before deleting
    
    db.query(models.DoctorProfile).filter(
        models.DoctorProfile.specialty_id == specialty_id
    ).update({"specialty_id": None})

    db.delete(specialty)
    db.flush()
