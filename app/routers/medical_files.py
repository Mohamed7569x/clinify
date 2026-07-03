"""
MEDICAL FILES
Upload and list medical files (lab results, scans, etc.) per appointment.
Doctor or patient can upload; doctor/manager/patient (own) can view.
"""

from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form
from typing import Annotated
from uuid import UUID

from app.schemas import models
from app.schemas.models import UserRole, FileType
from app.dependencies import (
    db_depends, get_current_user, verify_same_clinic,
)
from app.schemas.api_schemas import MedicalFileResponse, FileTypeEnum

router = APIRouter(prefix="/api/v1/appointments/{appointment_id}/files", tags=["Medical Files"])


def _get_appointment_or_404(appointment_id: UUID, current_user: models.User, db):
    appointment = db.query(models.Appointment).filter(
        models.Appointment.id == appointment_id
    ).first()
    if not appointment:
        raise HTTPException(status_code=404, detail="Appointment not found.")
    verify_same_clinic(current_user, appointment.clinic_id)
    return appointment


# ─────────────────────────────────────────────
# POST — Upload file metadata (actual file upload to S3/storage is separate)
# ─────────────────────────────────────────────

@router.post("/", response_model=MedicalFileResponse, status_code=status.HTTP_201_CREATED)
async def add_medical_file(
    appointment_id: UUID,
    file_type: FileTypeEnum = Form(...),
    file_name: str = Form(...),
    file_url: str = Form(...),      # Pre-signed URL or storage path from frontend
    current_user: Annotated[models.User, Depends(get_current_user)] = None,
    db: db_depends = None,
):
    """
    Records a medical file attachment for the appointment.
    The actual binary upload happens client-side to your object storage;
    this endpoint saves the metadata.
    """
    if current_user.current_role not in (UserRole.doctor, UserRole.patient):
        raise HTTPException(status_code=403, detail="Only doctors and patients can upload files.")

    appointment = _get_appointment_or_404(appointment_id, current_user, db)

    medical_file = models.MedicalFile(
        appointment_id=appointment.id,
        file_type=file_type,
        file_name=file_name,
        file_url=file_url,
        uploaded_by=current_user.id,
    )
    db.add(medical_file)
    db.flush()
    db.refresh(medical_file)
    return medical_file


# ─────────────────────────────────────────────
# GET — List files for an appointment
# ─────────────────────────────────────────────

@router.get("/", response_model=list[MedicalFileResponse])
async def list_medical_files(
    appointment_id: UUID,
    current_user: Annotated[models.User, Depends(get_current_user)],
    db: db_depends,
):
    appointment = _get_appointment_or_404(appointment_id, current_user, db)

    return (
        db.query(models.MedicalFile)
        .filter(models.MedicalFile.appointment_id == appointment.id)
        .all()
    )
