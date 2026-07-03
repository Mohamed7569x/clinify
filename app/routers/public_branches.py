from __future__ import annotations

from typing import Optional
from uuid import UUID

from fastapi import APIRouter, HTTPException, status, Request
from pydantic import BaseModel

from app.dependencies import db_depends
from app.schemas import models


router = APIRouter(
    prefix="/public/branches",
    tags=["Public Branches"],
)


class PublicBranchPreview(BaseModel):
    id: UUID
    group_name: str
    branch_name: Optional[str] = None
    branch_slug: Optional[str] = None
    join_code: Optional[str] = None
    city: Optional[str] = None
    area: Optional[str] = None
    phone: Optional[str] = None
    address: Optional[str] = None
    is_active: bool

class JoinAssetsResponse(BaseModel):
    branch_id: UUID
    branch_name: Optional[str] = None
    branch_slug: Optional[str] = None
    join_code: Optional[str] = None
    join_url: str


def build_public_branch_preview(branch: models.Clinic) -> PublicBranchPreview:
    return PublicBranchPreview(
        id=branch.id,
        group_name=branch.name,
        branch_name=branch.branch_name,
        branch_slug=branch.branch_slug,
        join_code=branch.join_code,
        city=getattr(branch, "city", None),
        area=getattr(branch, "area", None),
        phone=branch.phone,
        address=branch.address,
        is_active=branch.is_active,
    )


@router.get("/resolve/slug/{branch_slug}", response_model=PublicBranchPreview)
def resolve_branch_by_slug(
    branch_slug: str,
    db: db_depends,
):
    branch = (
        db.query(models.Clinic)
        .filter(
            models.Clinic.branch_slug == branch_slug,
            models.Clinic.is_discoverable == True,
        )
        .first()
    )

    if not branch:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Branch not found."
        )

    if not branch.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="This branch is currently inactive."
        )

    return build_public_branch_preview(branch)


@router.get("/resolve/code/{join_code}", response_model=PublicBranchPreview)
def resolve_branch_by_code(
    join_code: str,
    db: db_depends,
):
    branch = (
        db.query(models.Clinic)
        .filter(
            models.Clinic.join_code == join_code.upper(),
            models.Clinic.is_discoverable == True,
        )
        .first()
    )

    if not branch:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Branch not found."
        )

    if not branch.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="This branch is currently inactive."
        )

    return build_public_branch_preview(branch)