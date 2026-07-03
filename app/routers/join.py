from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, or_
from sqlalchemy.orm import joinedload

from app.dependencies import db_depends
from app.schemas import models
from app.schemas.api_schemas import (
    JoinBranchItem,
    JoinResolveBranchResponse,
    JoinResolveGroupResponse,
    JoinSearchBranchItem,
    JoinSearchGroupItem,
    JoinSearchResponse,
    JoinResolveCodeResponse,
)

router = APIRouter(prefix="/api/v1/join", tags=["Join"])


def _branch_item(clinic: models.Clinic) -> JoinBranchItem:
    group = getattr(clinic, "group", None)
    return JoinBranchItem(
        clinic_uuid=clinic.id,
        clinic_id=clinic.clinic_id,
        clinic_name=clinic.name,
        clinic_slug=clinic.branch_slug,
        address=clinic.address,
        area=clinic.area,
        phone=clinic.phone,
        logo_url=clinic.logo_url,
        group_id=group.id if group else None,
        group_name=group.name if group else None,
        group_slug=group.slug if group else None,
    )


@router.get("/resolve/branch/{slug}", response_model=JoinResolveBranchResponse)
async def resolve_branch_by_slug(
    slug: str,
    db: db_depends,
):
    clinic = (
        db.query(models.Clinic)
        .options(joinedload(models.Clinic.group))
        .filter(
            models.Clinic.branch_slug == slug,
            models.Clinic.is_active == True,
        )
        .first()
    )

    if not clinic:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Clinic branch not found.",
        )

    return JoinResolveBranchResponse(
        type="branch",
        clinic=_branch_item(clinic),
    )


@router.get("/resolve/group/{slug}", response_model=JoinResolveGroupResponse)
async def resolve_group_by_slug(
    slug: str,
    db: db_depends,
):
    group = (
        db.query(models.ClinicGroup)
        .options(joinedload(models.ClinicGroup.clinics))
        .filter(
            models.ClinicGroup.slug == slug,
            models.ClinicGroup.is_active == True,
        )
        .first()
    )

    if not group:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Clinic group not found.",
        )

    active_branches = [
        clinic for clinic in group.clinics
        if clinic.is_active
    ]

    active_branches.sort(key=lambda c: (c.name or "").lower())

    return JoinResolveGroupResponse(
        type="group",
        group_id=group.id,
        group_name=group.name,
        group_slug=group.slug,
        logo_url=group.logo_url,
        branches=[_branch_item(clinic) for clinic in active_branches],
    )


@router.get("/resolve/code/{clinic_code}", response_model=JoinResolveCodeResponse)
async def resolve_clinic_by_code(
    clinic_code: str,
    db: db_depends,
):
    clinic = (
        db.query(models.Clinic)
        .options(joinedload(models.Clinic.group))
        .filter(
            func.upper(models.Clinic.clinic_id) == clinic_code.upper(),
            models.Clinic.is_active == True,
        )
        .first()
    )

    if not clinic:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Invalid clinic code.",
        )

    return JoinResolveCodeResponse(
        type="branch",
        clinic=_branch_item(clinic),
    )


@router.get("/search", response_model=JoinSearchResponse)
async def search_join_targets(
    q: str = Query(..., min_length=1),
    limit: int = Query(10, ge=1, le=50),
    db: db_depends = None,
):
    q = q.strip()
    like = f"%{q}%"

    groups_raw = (
        db.query(
            models.ClinicGroup.id,
            models.ClinicGroup.name,
            models.ClinicGroup.slug,
            models.ClinicGroup.logo_url,
            func.count(models.Clinic.id).label("branches_count"),
        )
        .outerjoin(
            models.Clinic,
            (models.Clinic.group_id == models.ClinicGroup.id) & (models.Clinic.is_active == True),
        )
        .filter(
            models.ClinicGroup.is_active == True,
            or_(
                models.ClinicGroup.name.ilike(like),
                models.ClinicGroup.slug.ilike(like),
            ),
        )
        .group_by(
            models.ClinicGroup.id,
            models.ClinicGroup.name,
            models.ClinicGroup.slug,
            models.ClinicGroup.logo_url,
        )
        .order_by(models.ClinicGroup.name.asc())
        .limit(limit)
        .all()
    )

    branches_raw = (
        db.query(models.Clinic)
        .options(joinedload(models.Clinic.group))
        .filter(
            models.Clinic.is_active == True,
            or_(
                models.Clinic.name.ilike(like),
                models.Clinic.branch_slug.ilike(like),
                models.Clinic.clinic_id.ilike(like),
                models.Clinic.address.ilike(like),
            ),
        )
        .order_by(models.Clinic.name.asc())
        .limit(limit)
        .all()
    )

    groups = [
        JoinSearchGroupItem(
            type="group",
            group_id=row.id,
            group_name=row.name,
            group_slug=row.slug,
            logo_url=row.logo_url,
            branches_count=int(row.branches_count or 0),
        )
        for row in groups_raw
    ]

    branches = [
        JoinSearchBranchItem(
            type="branch",
            display_name= f"{clinic.name} - {clinic.branch_name}",
            clinic_uuid=clinic.id,
            clinic_id=clinic.clinic_id,
            clinic_name=clinic.name,
            clinic_slug=clinic.branch_slug,
            address=clinic.address,
            area=clinic.area,
            phone=clinic.phone,
            logo_url=clinic.logo_url,
            group_id=clinic.group.id if clinic.group else None,
            group_name=clinic.group.name if clinic.group else None,
            group_slug=clinic.group.slug if clinic.group else None,
        )
        for clinic in branches_raw
    ]

    return JoinSearchResponse(
        groups=groups,
        branches=branches,
    )