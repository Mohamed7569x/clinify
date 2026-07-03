"""
AUDIT LOGS
Manager views audit trail for their clinic.
Read-only — logs are created by other endpoints via a helper.
"""

from fastapi import APIRouter, Depends, Query
from typing import Annotated
from uuid import UUID

from app.schemas import models
from app.dependencies import db_depends, require_manager
from app.schemas.api_schemas import AuditLogResponse

router = APIRouter(prefix="/api/v1/audit-logs", tags=["Audit Logs"])


# ─────────────────────────────────────────────
# Helper — other routers call this to write audit entries
# ─────────────────────────────────────────────

def create_audit_log(
    db,
    clinic_id: UUID,
    action: str,
    user_id: UUID | None = None,
    target_id: UUID | None = None,
    target_type: str | None = None,
    detail: str | None = None,
):
    log = models.AuditLog(
        clinic_id=clinic_id,
        user_id=user_id,
        action=action,
        target_id=target_id,
        target_type=target_type,
        detail=detail,
    )
    db.add(log)
    db.flush()
    return log


# ─────────────────────────────────────────────
# GET /audit-logs — List audit logs
# ─────────────────────────────────────────────

@router.get("/", response_model=list[AuditLogResponse])
async def list_audit_logs(
    current_user: Annotated[models.User, Depends(require_manager)],
    db: db_depends,
    action: str | None = Query(None),
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
):
    query = db.query(models.AuditLog).filter(
        models.AuditLog.clinic_id == current_user.current_clinic_id
    )

    if action:
        query = query.filter(models.AuditLog.action == action)

    return (
        query
        .order_by(models.AuditLog.created_at.desc())
        .offset(offset)
        .limit(limit)
        .all()
    )
