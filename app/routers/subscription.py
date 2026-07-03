"""
SUBSCRIPTION & INVOICES
Manager views their clinic's subscription info and invoice history.
Plan upgrade logic would hook into a payment gateway — placeholder here.
"""

from fastapi import APIRouter, Depends, HTTPException, status
from typing import Annotated
from uuid import UUID

from app.schemas import models
from app.dependencies import db_depends, require_manager
from app.schemas.api_schemas import SubscriptionResponse, InvoiceResponse

router = APIRouter(prefix="/api/v1/subscription", tags=["Subscription"])


# ─────────────────────────────────────────────
# GET /subscription — View my clinic's subscription
# ─────────────────────────────────────────────

@router.get("/", response_model=SubscriptionResponse)
async def get_subscription(
    current_user: Annotated[models.User, Depends(require_manager)],
    db: db_depends,
):
    subscription = db.query(models.Subscription).filter(
        models.Subscription.clinic_id == current_user.current_clinic_id
    ).first()

    if not subscription:
        raise HTTPException(status_code=404, detail="No subscription found for this clinic.")

    return subscription


# ─────────────────────────────────────────────
# GET /subscription/invoices — Invoice history
# ─────────────────────────────────────────────

@router.get("/invoices", response_model=list[InvoiceResponse])
async def list_invoices(
    current_user: Annotated[models.User, Depends(require_manager)],
    db: db_depends,
):
    subscription = db.query(models.Subscription).filter(
        models.Subscription.clinic_id == current_user.current_clinic_id
    ).first()

    if not subscription:
        raise HTTPException(status_code=404, detail="No subscription found.")

    return (
        db.query(models.Invoice)
        .filter(models.Invoice.subscription_id == subscription.id)
        .order_by(models.Invoice.created_at.desc())
        .all()
    )
