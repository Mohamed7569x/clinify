from __future__ import annotations

from datetime import date
from decimal import Decimal
from typing import Annotated, Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel, Field

from app.schemas import models
from app.dependencies import db_depends, require_manager


router = APIRouter(
    prefix="/api/v1/finance",
    tags=["Finance"],
)


# =========================================================
# Schemas
# =========================================================

class AppointmentFinanceSummaryResponse(BaseModel):
    appointment_id: UUID
    fee_amount: Decimal
    discount_amount: Decimal
    total_due_amount: Decimal
    total_paid_amount: Decimal
    balance_amount: Decimal
    payment_status: models.PaymentStatus
    payment_note: Optional[str] = None

    class Config:
        from_attributes = True


class LedgerEntryResponse(BaseModel):
    id: UUID
    clinic_id: UUID
    appointment_id: Optional[UUID] = None
    created_by: Optional[UUID] = None
    entry_type: models.LedgerEntryType
    money_flow: models.MoneyFlow
    payment_method: Optional[models.PaymentMethod] = None
    amount: Decimal
    note: Optional[str] = None
    reference: Optional[str] = None
    effective_date: date

    class Config:
        from_attributes = True


class AppointmentPaymentEntryCreate(BaseModel):
    entry_type: models.LedgerEntryType = Field(
        ...,
        description="PATIENT_PAYMENT / PAYMENT_ADJUSTMENT / REFUND / WAIVER"
    )
    money_flow: models.MoneyFlow
    amount: Decimal = Field(..., gt=0)
    payment_method: Optional[models.PaymentMethod] = None
    note: Optional[str] = None
    reference: Optional[str] = None
    effective_date: Optional[date] = None


class GeneralLedgerEntryCreate(BaseModel):
    entry_type: models.LedgerEntryType
    money_flow: models.MoneyFlow
    amount: Decimal = Field(..., gt=0)
    payment_method: Optional[models.PaymentMethod] = None
    note: Optional[str] = None
    reference: Optional[str] = None
    effective_date: Optional[date] = None


class AppointmentFinanceUpdate(BaseModel):
    fee_amount: Optional[Decimal] = Field(default=None, ge=0)
    discount_amount: Optional[Decimal] = Field(default=None, ge=0)
    payment_note: Optional[str] = None


class FinanceTotalsResponse(BaseModel):
    inflow_total: Decimal
    outflow_total: Decimal
    net_total: Decimal


# =========================================================
# Helpers
# =========================================================

APPOINTMENT_ALLOWED_ENTRY_TYPES = {
    models.LedgerEntryType.PATIENT_PAYMENT,
    models.LedgerEntryType.PAYMENT_ADJUSTMENT,
    models.LedgerEntryType.REFUND,
    models.LedgerEntryType.WAIVER,
}


def _to_decimal(value) -> Decimal:
    if value is None:
        return Decimal("0.00")
    if isinstance(value, Decimal):
        return value
    return Decimal(str(value))


def _get_appointment_or_404(
    appointment_id: UUID,
    clinic_id: UUID,
    db,
) -> models.Appointment:
    appointment = (
        db.query(models.Appointment)
        .filter(
            models.Appointment.id == appointment_id,
            models.Appointment.clinic_id == clinic_id,
        )
        .first()
    )
    if not appointment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Appointment not found.",
        )
    return appointment


def _recalculate_appointment_finance(
    appointment: models.Appointment,
    db,
) -> None:
    entries = (
        db.query(models.ClinicLedgerEntry)
        .filter(models.ClinicLedgerEntry.appointment_id == appointment.id)
        .all()
    )

    inflow_total = Decimal("0.00")
    outflow_total = Decimal("0.00")

    for entry in entries:
        amount = _to_decimal(entry.amount)
        if entry.money_flow == models.MoneyFlow.INFLOW:
            inflow_total += amount
        else:
            outflow_total += amount

    fee_amount = _to_decimal(appointment.fee_amount)
    discount_amount = _to_decimal(appointment.discount_amount)

    total_due = fee_amount - discount_amount
    if total_due < Decimal("0.00"):
        total_due = Decimal("0.00")

    total_paid = inflow_total - outflow_total
    balance = total_due - total_paid

    appointment.total_due_amount = total_due
    appointment.total_paid_amount = total_paid
    appointment.balance_amount = balance

    if total_due == Decimal("0.00"):
        appointment.payment_status = models.PaymentStatus.WAIVED
    elif total_paid <= Decimal("0.00"):
        appointment.payment_status = models.PaymentStatus.UNPAID
    elif total_paid < total_due:
        appointment.payment_status = models.PaymentStatus.PARTIAL
    else:
        appointment.payment_status = models.PaymentStatus.PAID

    db.flush()


# =========================================================
# Appointment finance endpoints
# =========================================================

@router.get(
    "/appointments/{appointment_id}",
    response_model=AppointmentFinanceSummaryResponse,
)
def get_appointment_finance(
    appointment_id: UUID,
    current_user: Annotated[models.User, Depends(require_manager)],
    db: db_depends,
):
    clinic_id = current_user.current_clinic_id
    appointment = _get_appointment_or_404(appointment_id, clinic_id, db)
    return AppointmentFinanceSummaryResponse(
        appointment_id=appointment.id,
        fee_amount=_to_decimal(appointment.fee_amount),
        discount_amount=_to_decimal(appointment.discount_amount),
        total_due_amount=_to_decimal(appointment.total_due_amount),
        total_paid_amount=_to_decimal(appointment.total_paid_amount),
        balance_amount=_to_decimal(appointment.balance_amount),
        payment_status=appointment.payment_status,
        payment_note=appointment.payment_note,
    )


@router.patch(
    "/appointments/{appointment_id}",
    response_model=AppointmentFinanceSummaryResponse,
)
def update_appointment_finance(
    appointment_id: UUID,
    payload: AppointmentFinanceUpdate,
    current_user: Annotated[models.User, Depends(require_manager)],
    db: db_depends,
):
    clinic_id = current_user.current_clinic_id
    appointment = _get_appointment_or_404(appointment_id, clinic_id, db)

    if payload.fee_amount is not None:
        appointment.fee_amount = payload.fee_amount

    if payload.discount_amount is not None:
        appointment.discount_amount = payload.discount_amount

    if payload.payment_note is not None:
        appointment.payment_note = payload.payment_note

    _recalculate_appointment_finance(appointment, db)

    return AppointmentFinanceSummaryResponse(
        appointment_id=appointment.id,
        fee_amount=_to_decimal(appointment.fee_amount),
        discount_amount=_to_decimal(appointment.discount_amount),
        total_due_amount=_to_decimal(appointment.total_due_amount),
        total_paid_amount=_to_decimal(appointment.total_paid_amount),
        balance_amount=_to_decimal(appointment.balance_amount),
        payment_status=appointment.payment_status,
        payment_note=appointment.payment_note,
    )


@router.get(
    "/appointments/{appointment_id}/entries",
    response_model=list[LedgerEntryResponse],
)
def list_appointment_finance_entries(
    appointment_id: UUID,
    current_user: Annotated[models.User, Depends(require_manager)],
    db: db_depends,
):
    clinic_id = current_user.current_clinic_id
    _get_appointment_or_404(appointment_id, clinic_id, db)

    entries = (
        db.query(models.ClinicLedgerEntry)
        .filter(
            models.ClinicLedgerEntry.clinic_id == clinic_id,
            models.ClinicLedgerEntry.appointment_id == appointment_id,
        )
        .order_by(
            models.ClinicLedgerEntry.effective_date.desc(),
            models.ClinicLedgerEntry.created_at.desc(),
        )
        .all()
    )
    return entries


@router.post(
    "/appointments/{appointment_id}/entries",
    response_model=LedgerEntryResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_appointment_finance_entry(
    appointment_id: UUID,
    payload: AppointmentPaymentEntryCreate,
    current_user: Annotated[models.User, Depends(require_manager)],
    db: db_depends,
):
    clinic_id = current_user.current_clinic_id
    appointment = _get_appointment_or_404(appointment_id, clinic_id, db)

    if payload.entry_type not in APPOINTMENT_ALLOWED_ENTRY_TYPES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="This entry type is not allowed for appointment finance.",
        )

    entry = models.ClinicLedgerEntry(
        clinic_id=clinic_id,
        appointment_id=appointment.id,
        created_by=current_user.id,
        entry_type=payload.entry_type,
        money_flow=payload.money_flow,
        payment_method=payload.payment_method,
        amount=payload.amount,
        note=payload.note,
        reference=payload.reference,
        effective_date=payload.effective_date or date.today(),
    )
    db.add(entry)
    db.flush()

    _recalculate_appointment_finance(appointment, db)
    db.refresh(entry)

    return entry


# =========================================================
# General clinic ledger endpoints
# =========================================================

@router.get(
    "/entries",
    response_model=list[LedgerEntryResponse],
)
def list_clinic_ledger_entries(
    current_user: Annotated[models.User, Depends(require_manager)],
    db: db_depends,
    date_from: Optional[date] = Query(default=None),
    date_to: Optional[date] = Query(default=None),
    money_flow: Optional[models.MoneyFlow] = Query(default=None),
    entry_type: Optional[models.LedgerEntryType] = Query(default=None),
    appointment_only: bool = Query(default=False),
):
    clinic_id = current_user.current_clinic_id

    q = db.query(models.ClinicLedgerEntry).filter(
        models.ClinicLedgerEntry.clinic_id == clinic_id
    )

    if date_from:
        q = q.filter(models.ClinicLedgerEntry.effective_date >= date_from)
    if date_to:
        q = q.filter(models.ClinicLedgerEntry.effective_date <= date_to)
    if money_flow:
        q = q.filter(models.ClinicLedgerEntry.money_flow == money_flow)
    if entry_type:
        q = q.filter(models.ClinicLedgerEntry.entry_type == entry_type)
    if appointment_only:
        q = q.filter(models.ClinicLedgerEntry.appointment_id.isnot(None))

    entries = q.order_by(
        models.ClinicLedgerEntry.effective_date.desc(),
        models.ClinicLedgerEntry.created_at.desc(),
    ).all()

    return entries


@router.post(
    "/entries",
    response_model=LedgerEntryResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_general_ledger_entry(
    payload: GeneralLedgerEntryCreate,
    current_user: Annotated[models.User, Depends(require_manager)],
    db: db_depends,
):
    clinic_id = current_user.current_clinic_id

    entry = models.ClinicLedgerEntry(
        clinic_id=clinic_id,
        appointment_id=None,
        created_by=current_user.id,
        entry_type=payload.entry_type,
        money_flow=payload.money_flow,
        payment_method=payload.payment_method,
        amount=payload.amount,
        note=payload.note,
        reference=payload.reference,
        effective_date=payload.effective_date or date.today(),
    )
    db.add(entry)
    db.flush()
    db.refresh(entry)

    return entry


# =========================================================
# Reports / totals
# =========================================================

@router.get(
    "/totals",
    response_model=FinanceTotalsResponse,
)
def get_finance_totals(
    current_user: Annotated[models.User, Depends(require_manager)],
    db: db_depends,
    date_from: Optional[date] = Query(default=None),
    date_to: Optional[date] = Query(default=None),
):
    clinic_id = current_user.current_clinic_id

    q = db.query(models.ClinicLedgerEntry).filter(
        models.ClinicLedgerEntry.clinic_id == clinic_id
    )

    if date_from:
        q = q.filter(models.ClinicLedgerEntry.effective_date >= date_from)
    if date_to:
        q = q.filter(models.ClinicLedgerEntry.effective_date <= date_to)

    entries = q.all()

    inflow_total = Decimal("0.00")
    outflow_total = Decimal("0.00")

    for entry in entries:
        amount = _to_decimal(entry.amount)
        if entry.money_flow == models.MoneyFlow.INFLOW:
            inflow_total += amount
        else:
            outflow_total += amount

    return FinanceTotalsResponse(
        inflow_total=inflow_total,
        outflow_total=outflow_total,
        net_total=inflow_total - outflow_total,
    )