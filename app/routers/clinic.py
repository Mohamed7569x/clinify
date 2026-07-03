"""
WEB DASHBOARD — Clinic Profile & Dashboard
Manager-only endpoints for clinic settings and overview stats.
"""

from fastapi import APIRouter, Depends, HTTPException, status
from typing import Annotated
from sqlalchemy.orm import Session
from uuid import UUID

from app.schemas import models
from app.schemas.models import UserRole, AppointmentStatus
from app.dependencies import (
    db_depends, require_manager, get_current_user,
)
from app.schemas.api_schemas import (
    ClinicUpdate, ClinicResponse, DashboardStats,
)

router = APIRouter(prefix="/api/v1/clinic", tags=["Clinic"])


# ─────────────────────────────────────────────
# GET  /clinic/profile — View own clinic details
# ─────────────────────────────────────────────

@router.get("/profile", response_model=ClinicResponse)
async def get_clinic_profile(
    current_user: Annotated[models.User, Depends(require_manager)],
    db: db_depends,
):
    clinic = db.query(models.Clinic).filter(
        models.Clinic.id == current_user.current_clinic_id
    ).first()

    if not clinic:
        raise HTTPException(status_code=404, detail="Clinic not found.")

    return clinic


# ─────────────────────────────────────────────
# PUT  /clinic/profile — Update clinic info
# ─────────────────────────────────────────────

@router.put("/profile", response_model=ClinicResponse)
async def update_clinic_profile(
    payload: ClinicUpdate,
    current_user: Annotated[models.User, Depends(require_manager)],
    db: db_depends,
):
    clinic = db.query(models.Clinic).filter(
        models.Clinic.id == current_user.clinic_id
    ).first()

    if not clinic:
        raise HTTPException(status_code=404, detail="Clinic not found.")

    update_data = payload.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(clinic, field, value)

    db.flush()
    db.refresh(clinic)
    return clinic


# ─────────────────────────────────────────────
# GET  /clinic/dashboard — Quick stats overview
# ─────────────────────────────────────────────

@router.get("/dashboard", response_model=DashboardStats)
async def get_dashboard_stats(
    current_user: Annotated[models.User, Depends(require_manager)],
    db: db_depends,
):
    clinic_id = current_user.current_clinic_id

    total_doctors = db.query(models.ClinicMembership).filter(
    models.ClinicMembership.clinic_id == clinic_id,
    models.ClinicMembership.role == UserRole.doctor,
    models.ClinicMembership.is_active == True,
).count()

    total_patients = db.query(models.ClinicMembership).filter(
        models.ClinicMembership.clinic_id == clinic_id,
        models.ClinicMembership.role == UserRole.patient,
        models.ClinicMembership.is_active == True,
    ).count()

    appointments_q = db.query(models.Appointment).filter(
        models.Appointment.clinic_id == clinic_id
    )

    total_appointments     = appointments_q.count()
    pending_appointments   = appointments_q.filter(
        models.Appointment.status == AppointmentStatus.PENDING
    ).count()
    completed_appointments = appointments_q.filter(
        models.Appointment.status == AppointmentStatus.COMPLETED
    ).count()
    cancelled_appointments = appointments_q.filter(
        models.Appointment.status == AppointmentStatus.CANCELLED
    ).count()

    return DashboardStats(
        total_doctors=total_doctors,
        total_patients=total_patients,
        total_appointments=total_appointments,
        pending_appointments=pending_appointments,
        completed_appointments=completed_appointments,
        cancelled_appointments=cancelled_appointments,
    )
