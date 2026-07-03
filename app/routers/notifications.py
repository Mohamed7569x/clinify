"""
NOTIFICATIONS
List user's notifications, mark as read.
"""

from fastapi import APIRouter, Depends, HTTPException, status
from typing import Annotated
from uuid import UUID

from app.schemas import models
from app.dependencies import db_depends, get_current_user
from app.schemas.api_schemas import NotificationResponse

router = APIRouter(prefix="/api/v1/notifications", tags=["Notifications"])


# ─────────────────────────────────────────────
# GET — List my notifications
# ─────────────────────────────────────────────

@router.get("/", response_model=list[NotificationResponse])
async def list_notifications(
    current_user: Annotated[models.User, Depends(get_current_user)],
    db: db_depends,
    unread_only: bool = False,
):
    query = db.query(models.Notification).filter(
        models.Notification.user_id == current_user.id
    )
    if unread_only:
        query = query.filter(models.Notification.is_read == False)

    return query.order_by(models.Notification.created_at.desc()).all()


# ─────────────────────────────────────────────
# GET — Unread count
# ─────────────────────────────────────────────

@router.get("/unread-count")
async def unread_count(
    current_user: Annotated[models.User, Depends(get_current_user)],
    db: db_depends,
):
    count = db.query(models.Notification).filter(
        models.Notification.user_id == current_user.id,
        models.Notification.is_read == False,
    ).count()
    return {"unread_count": count}


# ─────────────────────────────────────────────
# PATCH — Mark single notification as read
# ─────────────────────────────────────────────

@router.patch("/{notification_id}/read", status_code=status.HTTP_204_NO_CONTENT)
async def mark_notification_read(
    notification_id: UUID,
    current_user: Annotated[models.User, Depends(get_current_user)],
    db: db_depends,
):
    notification = db.query(models.Notification).filter(
        models.Notification.id == notification_id,
        models.Notification.user_id == current_user.id,
    ).first()

    if not notification:
        raise HTTPException(status_code=404, detail="Notification not found.")

    notification.is_read = True
    db.flush()


# ─────────────────────────────────────────────
# PATCH — Mark all as read
# ─────────────────────────────────────────────

@router.patch("/read-all", status_code=status.HTTP_204_NO_CONTENT)
async def mark_all_read(
    current_user: Annotated[models.User, Depends(get_current_user)],
    db: db_depends,
):
    db.query(models.Notification).filter(
        models.Notification.user_id == current_user.id,
        models.Notification.is_read == False,
    ).update({"is_read": True})
    db.flush()
