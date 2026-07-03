from __future__ import annotations

from typing import Annotated, Optional
from uuid import UUID
import re

from fastapi import APIRouter, Depends, HTTPException, status, Request
from pydantic import BaseModel, Field
from datetime import timedelta
from app.schemas import models
from app.dependencies import (
    db_depends,
    require_manager,
    create_access_token,
    create_refresh_access_token,
    ACCESS_TOKEN_EXPIRE_MINUTES,
)


router = APIRouter(
    prefix="/api/v1/branches",
    tags=["Branches"],
)


# =========================================================
# Schemas
# =========================================================

class BranchBase(BaseModel):
    branch_name: str = Field(..., min_length=2, max_length=120)
    phone: Optional[str] = Field(default=None, max_length=30)
    address: Optional[str] = Field(default=None, max_length=255)
    city: Optional[str] = Field(default=None, max_length=120)
    area: Optional[str] = Field(default=None, max_length=120)
    branch_slug: Optional[str] = Field(default=None, max_length=120)
    join_code: Optional[str] = Field(default=None, max_length=30)


class BranchCreate(BranchBase):
    pass


class BranchUpdate(BaseModel):
    branch_name: Optional[str] = Field(default=None, min_length=2, max_length=120)
    phone: Optional[str] = Field(default=None, max_length=30)
    address: Optional[str] = Field(default=None, max_length=255)
    city: Optional[str] = Field(default=None, max_length=120)
    area: Optional[str] = Field(default=None, max_length=120)
    branch_slug: Optional[str] = Field(default=None, max_length=120)
    join_code: Optional[str] = Field(default=None, max_length=30)
    is_discoverable: Optional[bool] = None
    is_active: Optional[bool] = None


class BranchResponse(BaseModel):
    id: UUID
    clinic_id: str
    group_id: Optional[UUID]
    name: str
    branch_name: Optional[str]
    branch_slug: Optional[str]
    phone: Optional[str]
    search_phone: Optional[str]
    address: Optional[str]
    city: Optional[str]
    area: Optional[str]
    join_code: Optional[str]
    is_discoverable: Optional[bool]
    is_default_branch: Optional[bool]
    is_active: bool

    class Config:
        from_attributes = True


# =========================================================
# Helpers
# =========================================================

def slugify(value: str) -> str:
    value = value.strip().lower()
    value = re.sub(r"[^a-z0-9]+", "-", value)
    value = re.sub(r"-+", "-", value).strip("-")
    return value or "branch"


def normalize_phone(phone: str | None) -> str | None:
    if not phone:
        return None
    digits = "".join(ch for ch in phone if ch.isdigit())
    return digits or None


def generate_join_code(branch_name: str) -> str:
    base = slugify(branch_name).replace("-", "").upper()
    return (base[:8] or "BRANCH")


def get_manager_group_id(current_user: models.User) -> UUID:
    clinic = getattr(current_user, "current_clinic", None)
    if clinic is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Current clinic context is missing."
        )

    if not getattr(clinic, "group_id", None):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="This clinic is not linked to a clinic group yet."
        )

    return clinic.group_id


def get_branch_in_group_or_404(
    branch_id: UUID,
    group_id: UUID,
    db,
) -> models.Clinic:
    branch = (
        db.query(models.Clinic)
        .filter(
            models.Clinic.id == branch_id,
            models.Clinic.group_id == group_id,
        )
        .first()
    )

    if not branch:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Branch not found."
        )

    return branch


def ensure_unique_branch_slug(
    slug: str,
    db,
    exclude_branch_id: UUID | None = None,
) -> str:
    candidate = slug
    counter = 2

    while True:
        q = db.query(models.Clinic).filter(models.Clinic.branch_slug == candidate)
        if exclude_branch_id:
            q = q.filter(models.Clinic.id != exclude_branch_id)

        exists = q.first()
        if not exists:
            return candidate

        candidate = f"{slug}-{counter}"
        counter += 1


def ensure_unique_join_code(
    join_code: str,
    db,
    exclude_branch_id: UUID | None = None,
) -> str:
    candidate = join_code
    counter = 2

    while True:
        q = db.query(models.Clinic).filter(models.Clinic.join_code == candidate)
        if exclude_branch_id:
            q = q.filter(models.Clinic.id != exclude_branch_id)

        exists = q.first()
        if not exists:
            return candidate

        candidate = f"{join_code}{counter}"
        counter += 1


# =========================================================
# Endpoints
# =========================================================

@router.get("/", response_model=list[BranchResponse])
def list_branches(
    current_user: Annotated[models.User, Depends(require_manager)],
    db: db_depends,
):
    group_id = get_manager_group_id(current_user)

    branches = (
        db.query(models.Clinic)
        .filter(models.Clinic.group_id == group_id)
        .order_by(
            models.Clinic.is_default_branch.desc(),
            models.Clinic.created_at.asc(),
        )
        .all()
    )

    return branches


@router.get("/{branch_id}", response_model=BranchResponse)
def get_branch(
    branch_id: UUID,
    current_user: Annotated[models.User, Depends(require_manager)],
    db: db_depends,
):
    group_id = get_manager_group_id(current_user)
    branch = get_branch_in_group_or_404(branch_id, group_id, db)
    return branch


@router.post("/", response_model=BranchResponse, status_code=status.HTTP_201_CREATED)
def create_branch(
    payload: BranchCreate,
    current_user: Annotated[models.User, Depends(require_manager)],
    db: db_depends,
):
    group_id = get_manager_group_id(current_user)
    current_clinic = current_user.current_clinic

    parent_group = (
        db.query(models.ClinicGroup)
        .filter(models.ClinicGroup.id == group_id)
        .first()
    )
    if not parent_group:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Clinic group not found."
        )

    base_slug = slugify(payload.branch_slug or payload.branch_name)
    unique_slug = ensure_unique_branch_slug(base_slug, db)

    base_join_code = (payload.join_code or generate_join_code(payload.branch_name)).upper()
    unique_join_code = ensure_unique_join_code(base_join_code, db)

    # keep old clinic_id compatibility alive
    clinic_public_id = unique_join_code

    branch = models.Clinic(
        clinic_id=clinic_public_id,
        group_id=group_id,
        name=parent_group.name,
        branch_name=payload.branch_name.strip(),
        branch_slug=unique_slug,
        phone=payload.phone,
        search_phone=normalize_phone(payload.phone),
        address=payload.address,
        city=payload.city,
        area=payload.area,
        join_code=unique_join_code,
        is_discoverable=True,
        is_default_branch=False,
        is_active=True,
    )

    db.add(branch)
    db.flush()

    # auto-add current manager to the new branch
    existing_membership = (
        db.query(models.ClinicMembership)
        .filter(
            models.ClinicMembership.user_id == current_user.id,
            models.ClinicMembership.clinic_id == branch.id,
        )
        .first()
    )

    if not existing_membership:
        db.add(
            models.ClinicMembership(
                clinic_id=branch.id,
                user_id=current_user.id,
                role=models.UserRole.clinic_manager,
                is_active=True,
            )
        )

    db.refresh(branch)
    return branch


@router.put("/{branch_id}", response_model=BranchResponse)
def update_branch(
    branch_id: UUID,
    payload: BranchUpdate,
    current_user: Annotated[models.User, Depends(require_manager)],
    db: db_depends,
):
    group_id = get_manager_group_id(current_user)
    branch = get_branch_in_group_or_404(branch_id, group_id, db)

    data = payload.model_dump(exclude_unset=True)

    if "branch_name" in data and data["branch_name"]:
        branch.branch_name = data["branch_name"].strip()

    if "phone" in data:
        branch.phone = data["phone"]
        branch.search_phone = normalize_phone(data["phone"])

    if "address" in data:
        branch.address = data["address"]

    if "city" in data:
        branch.city = data["city"]

    if "area" in data:
        branch.area = data["area"]

    if "is_discoverable" in data and hasattr(branch, "is_discoverable"):
        branch.is_discoverable = data["is_discoverable"]

    if "is_active" in data:
        branch.is_active = data["is_active"]

    if "branch_slug" in data and data["branch_slug"]:
        branch.branch_slug = ensure_unique_branch_slug(
            slugify(data["branch_slug"]),
            db,
            exclude_branch_id=branch.id,
        )

    if "join_code" in data and data["join_code"]:
        new_code = ensure_unique_join_code(
            data["join_code"].upper(),
            db,
            exclude_branch_id=branch.id,
        )
        branch.join_code = new_code
        # optional: keep old compatibility field aligned
        branch.clinic_id = new_code

    db.flush()
    db.refresh(branch)
    return branch


@router.patch("/{branch_id}/activate", response_model=BranchResponse)
def activate_branch(
    branch_id: UUID,
    current_user: Annotated[models.User, Depends(require_manager)],
    db: db_depends,
):
    group_id = get_manager_group_id(current_user)
    branch = get_branch_in_group_or_404(branch_id, group_id, db)

    branch.is_active = True
    db.flush()
    db.refresh(branch)
    return branch


@router.patch("/{branch_id}/deactivate", response_model=BranchResponse)
def deactivate_branch(
    branch_id: UUID,
    current_user: Annotated[models.User, Depends(require_manager)],
    db: db_depends,
):
    group_id = get_manager_group_id(current_user)
    branch = get_branch_in_group_or_404(branch_id, group_id, db)

    if branch.is_default_branch:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You cannot deactivate the default branch."
        )

    branch.is_active = False
    db.flush()
    db.refresh(branch)
    return branch


@router.patch("/{branch_id}/set-default", response_model=BranchResponse)
def set_default_branch(
    branch_id: UUID,
    current_user: Annotated[models.User, Depends(require_manager)],
    db: db_depends,
):
    group_id = get_manager_group_id(current_user)
    branch = get_branch_in_group_or_404(branch_id, group_id, db)

    all_branches = (
        db.query(models.Clinic)
        .filter(models.Clinic.group_id == group_id)
        .all()
    )

    for item in all_branches:
        item.is_default_branch = False

    branch.is_default_branch = True
    db.flush()
    db.refresh(branch)
    return branch

class BranchJoinAssetsResponse(BaseModel):
    branch_id: UUID
    branch_name: str | None = None
    branch_slug: str | None = None
    join_code: str | None = None
    join_url: str


@router.get("/{branch_id}/join-assets", response_model=BranchJoinAssetsResponse)
def get_branch_join_assets(
    branch_id: UUID,
    current_user: Annotated[models.User, Depends(require_manager)],
    request: Request,
    db: db_depends,
):
    group_id = get_manager_group_id(current_user)
    branch = get_branch_in_group_or_404(branch_id, group_id, db)

    base_url = str(request.base_url).rstrip("/")
    join_url = f"{base_url}/join/{branch.branch_slug}"

    return BranchJoinAssetsResponse(
        branch_id=branch.id,
        branch_name=branch.branch_name,
        branch_slug=branch.branch_slug,
        join_code=branch.join_code,
        join_url=join_url,
    )

class SwitchBranchContextResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    branch_id: UUID
    clinic_id: str
    branch_name: str | None = None
    branch_slug: str | None = None


@router.post("/{branch_id}/switch-context", response_model=SwitchBranchContextResponse)
def switch_branch_context(
    branch_id: UUID,
    current_user: Annotated[models.User, Depends(require_manager)],
    db: db_depends,
):
    current_clinic = getattr(current_user, "current_clinic", None)
    if current_clinic is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Current clinic context is missing."
        )

    group_id = getattr(current_clinic, "group_id", None)
    if not group_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="This clinic is not linked to a clinic group yet."
        )

    target_branch = (
        db.query(models.Clinic)
        .filter(
            models.Clinic.id == branch_id,
            models.Clinic.group_id == group_id,
        )
        .first()
    )

    if not target_branch:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Branch not found."
        )

    if not target_branch.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="This branch is inactive."
        )

    membership = (
        db.query(models.ClinicMembership)
        .filter(
            models.ClinicMembership.user_id == current_user.id,
            models.ClinicMembership.clinic_id == target_branch.id,
        )
        .first()
    )

    if not membership:
        membership = models.ClinicMembership(
            clinic_id=target_branch.id,
            user_id=current_user.id,
            role=models.UserRole.clinic_manager,
            is_active=True,
        )
        db.add(membership)
        db.flush()

    if not membership.is_active:
        membership.is_active = True
        db.flush()

    if membership.role != models.UserRole.clinic_manager:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You do not have manager access to this branch."
        )

    identifier = current_user.email or current_user.phone_number
    if not identifier:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="This account is missing both email and phone identifier."
        )

    token_payload = {
        "sub": identifier,
        "role": models.UserRole.clinic_manager.value,
        "clinic_id": target_branch.clinic_id,
    }

    access_token = create_access_token(
        data=token_payload,
        expires_delta=timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES),
    )
    refresh_token = create_refresh_access_token(data=token_payload)

    return SwitchBranchContextResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        branch_id=target_branch.id,
        clinic_id=target_branch.clinic_id,
        branch_name=target_branch.branch_name,
        branch_slug=target_branch.branch_slug,
    )