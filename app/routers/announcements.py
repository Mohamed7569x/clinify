"""
ANNOUNCEMENTS
Manager creates broadcast announcements for clinic users.
All authenticated clinic users can view them.
"""

from fastapi import APIRouter, Depends, HTTPException, status
from typing import Annotated
from uuid import UUID

from app.schemas import models
from app.schemas.models import UserRole
from app.dependencies import (
    db_depends, require_manager, get_current_user, verify_same_clinic,
)
from app.schemas.api_schemas import AnnouncementCreate, AnnouncementResponse

router = APIRouter(prefix="/api/v1/announcements", tags=["Announcements"])


# ─────────────────────────────────────────────
# POST — Manager creates announcement
# ─────────────────────────────────────────────

@router.post("/", response_model=AnnouncementResponse, status_code=status.HTTP_201_CREATED)
async def create_announcement(
    payload: AnnouncementCreate,
    current_user: Annotated[models.User, Depends(require_manager)],
    db: db_depends,
):
    announcement = models.Announcement(
        clinic_id=current_user.current_clinic_id,
        created_by=current_user.id,
        title=payload.title,
        body=payload.body,
        target_role=payload.target_role,
    )
    db.add(announcement)
    db.flush()
    db.refresh(announcement)
    return announcement


# ─────────────────────────────────────────────
# GET — List announcements for my clinic
# ─────────────────────────────────────────────

@router.get("/", response_model=list[AnnouncementResponse])
async def list_announcements(
    current_user: Annotated[models.User, Depends(get_current_user)],
    db: db_depends,
):
    query = db.query(models.Announcement).filter(
        models.Announcement.clinic_id == current_user.current_clinic_id
    )

    # Non-manager users only see announcements targeted to them or to all
    if current_user.current_role != UserRole.clinic_manager:
        query = query.filter(
            (models.Announcement.target_role == None) |
            (models.Announcement.target_role == current_user.current_role)
        )

    return query.order_by(models.Announcement.created_at.desc()).all()


# ─────────────────────────────────────────────
# DELETE — Manager deletes announcement
# ─────────────────────────────────────────────

@router.delete("/{announcement_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_announcement(
    announcement_id: UUID,
    current_user: Annotated[models.User, Depends(require_manager)],
    db: db_depends,
):
    announcement = db.query(models.Announcement).filter(
        models.Announcement.id == announcement_id
    ).first()

    if not announcement:
        raise HTTPException(status_code=404, detail="Announcement not found.")

    verify_same_clinic(current_user, announcement.clinic_id)
    db.delete(announcement)
    db.flush()
