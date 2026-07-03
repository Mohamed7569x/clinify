from __future__ import annotations

from typing import Annotated, Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field

from app.schemas import models
from app.dependencies import db_depends, require_manager


router = APIRouter(
    prefix="/api/v1/clinic-group",
    tags=["Clinic Group"],
)


# =========================================================
# Schemas
# =========================================================

class ClinicGroupResponse(BaseModel):
    id: UUID
    name: str
    slug: str
    logo_url: Optional[str]
    website: Optional[str]
    main_phone: Optional[str]
    is_active: bool

    class Config:
        from_attributes = True


class ClinicGroupUpdate(BaseModel):
    name: str = Field(..., min_length=2, max_length=150)
    logo_url: Optional[str] = Field(default=None, max_length=500)
    website: Optional[str] = Field(default=None, max_length=500)
    main_phone: Optional[str] = Field(default=None, max_length=30)


# =========================================================
# Helpers
# =========================================================

def get_current_group_or_404(current_user: models.User, db) -> models.ClinicGroup:
    clinic = getattr(current_user, "current_clinic", None)

    if clinic is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Current clinic context is missing."
        )

    group_id = getattr(clinic, "group_id", None)
    if not group_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="This clinic is not linked to a clinic group yet."
        )

    group = (
        db.query(models.ClinicGroup)
        .filter(models.ClinicGroup.id == group_id)
        .first()
    )

    if not group:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Clinic group not found."
        )

    return group


# =========================================================
# Endpoints
# =========================================================

@router.get("/me", response_model=ClinicGroupResponse)
def get_my_clinic_group(
    current_user: Annotated[models.User, Depends(require_manager)],
    db: db_depends,
):
    group = get_current_group_or_404(current_user, db)
    return group


@router.put("/me", response_model=ClinicGroupResponse)
def update_my_clinic_group(
    payload: ClinicGroupUpdate,
    current_user: Annotated[models.User, Depends(require_manager)],
    db: db_depends,
):
    group = get_current_group_or_404(current_user, db)

    group.name = payload.name.strip()
    group.logo_url = payload.logo_url.strip() if payload.logo_url else None
    group.website = payload.website.strip() if payload.website else None
    group.main_phone = payload.main_phone.strip() if payload.main_phone else None

    # keep parent brand name synced into all branches if you want
    branches = (
        db.query(models.Clinic)
        .filter(models.Clinic.group_id == group.id)
        .all()
    )
    for branch in branches:
        branch.name = group.name

    db.flush()
    db.refresh(group)
    return group