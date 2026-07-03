"""
BROADCAST NOTIFICATIONS
Manager can send a custom notification to all users (doctors + patients) in their clinic.

Add this router to your FastAPI app:
    from app.routers.broadcast import router as broadcast_router
    app.include_router(broadcast_router)
"""

from fastapi import APIRouter, Depends, HTTPException, status
from typing import Annotated, Optional
from pydantic import BaseModel

from app.schemas import models
from app.schemas.models import UserRole, NotificationType
from app.dependencies import db_depends, get_current_user, require_manager
from app.services.notification_service import _create

router = APIRouter(prefix="/api/v1/notifications", tags=["Notifications"])


# ─────────────────────────────────────────────
# Request Schema
# ─────────────────────────────────────────────

class BroadcastRequest(BaseModel):
    title: str
    body: str
    target: str = "all"  # "all", "doctors", "patients"


class BroadcastResponse(BaseModel):
    success: bool
    sent_count: int
    message: str


# ─────────────────────────────────────────────
# POST /notifications/broadcast — Manager sends to all
# ─────────────────────────────────────────────

@router.post("/broadcast", response_model=BroadcastResponse)
async def broadcast_notification(
    payload: BroadcastRequest,
    current_user: Annotated[models.User, Depends(require_manager)],
    db: db_depends,
):
    """
    Send a custom notification to all users in the manager's clinic.
    
    target options:
    - "all" — doctors + active patients
    - "doctors" — only doctors
    - "patients" — only active patients
    """

    query = db.query(models.User).filter(
        models.User.clinic_id == current_user.clinic_id,
        models.User.is_active == True,
        models.User.id != current_user.id,  # Don't notify yourself
    )

    if payload.target == "doctors":
        query = query.filter(models.User.role == UserRole.doctor)
    elif payload.target == "patients":
        query = query.filter(models.User.role == UserRole.patient)
    else:
        # All — doctors + patients (exclude other managers)
        query = query.filter(
            models.User.role.in_([UserRole.doctor, UserRole.patient])
        )

    users = query.all()

    if not users:
        return BroadcastResponse(
            success=True,
            sent_count=0,
            message="لا يوجد مستخدمين لإرسال الإشعار إليهم",
        )

    count = 0
    for user in users:
        try:
            _create(
                db=db,
                user_id=user.id,
                ntype=NotificationType.GENERAL,
                title=payload.title,
                body=payload.body,
            )
            count += 1
        except Exception:
            continue

    return BroadcastResponse(
        success=True,
        sent_count=count,
        message=f"تم إرسال الإشعار إلى {count} مستخدم",
    )