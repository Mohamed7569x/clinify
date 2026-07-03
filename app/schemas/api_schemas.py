from pydantic import BaseModel, EmailStr, Field
from datetime import date, time, datetime
from typing import Optional, List, Literal
from uuid import UUID
from enum import Enum
from decimal import Decimal
from app.schemas import models
# ─────────────────────────────────────────────
# Shared Enums (mirror SQLAlchemy enums for API)
# ─────────────────────────────────────────────

class GenderEnum(str, Enum):
    MALE   = "MALE"
    FEMALE = "FEMALE"
    OTHER  = "OTHER"


class AppointmentStatusEnum(str, Enum):
    PENDING     = "PENDING"
    CONFIRMED   = "CONFIRMED"
    COMPLETED   = "COMPLETED"
    CANCELLED   = "CANCELLED"
    NO_SHOW     = "NO_SHOW"
    RESCHEDULED = "RESCHEDULED"


class DayOfWeekEnum(str, Enum):
    MONDAY    = "MONDAY"
    TUESDAY   = "TUESDAY"
    WEDNESDAY = "WEDNESDAY"
    THURSDAY  = "THURSDAY"
    FRIDAY    = "FRIDAY"
    SATURDAY  = "SATURDAY"
    SUNDAY    = "SUNDAY"


class FileTypeEnum(str, Enum):
    LAB_RESULT   = "LAB_RESULT"
    PRESCRIPTION = "PRESCRIPTION"
    SCAN         = "SCAN"
    REPORT       = "REPORT"
    OTHER        = "OTHER"


class ChatSenderEnum(str, Enum):
    DOCTOR  = "DOCTOR"
    PATIENT = "PATIENT"


class UserRoleEnum(str, Enum):
    clinic_manager = "clinic_manager"
    doctor         = "doctor"
    patient        = "patient"


class SubscriptionPlanEnum(str, Enum):
    FREE       = "FREE"
    BASIC      = "BASIC"
    PRO        = "PRO"
    ENTERPRISE = "ENTERPRISE"


class SubscriptionStatusEnum(str, Enum):
    ACTIVE    = "ACTIVE"
    EXPIRED   = "EXPIRED"
    TRIAL     = "TRIAL"
    CANCELLED = "CANCELLED"


# ─────────────────────────────────────────────
# Clinic
# ─────────────────────────────────────────────

class ClinicUpdate(BaseModel):
    name:     Optional[str] = None
    address:  Optional[str] = None
    phone:    Optional[str] = None
    logo_url: Optional[str] = None
    website:  Optional[str] = None


class ClinicResponse(BaseModel):
    id:         UUID
    clinic_id:  str
    name:       str
    address:    Optional[str]
    area:    Optional[str]
    phone:      Optional[str]
    logo_url:   Optional[str]
    website:    Optional[str]
    is_active:  bool
    created_at: datetime

    class Config:
        from_attributes = True


# ─────────────────────────────────────────────
# Specialty
# ─────────────────────────────────────────────

class SpecialtyCreate(BaseModel):
    name: str


class SpecialtyResponse(BaseModel):
    id:   UUID
    name: str

    class Config:
        from_attributes = True


# ─────────────────────────────────────────────
# User (shared)
# ─────────────────────────────────────────────
class UserResponse(BaseModel):
    id: UUID
    clinic_id: UUID | None = None
    role: UserRoleEnum | None = None
    name: str
    email: Optional[str] = None
    phone_number: Optional[str] = None
    gender: Optional[GenderEnum] = None
    date_of_birth: Optional[date] = None
    avatar_url: Optional[str] = None
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True


# ─────────────────────────────────────────────
# Doctor Management (Manager creates doctors)
# ─────────────────────────────────────────────

class DoctorCreate(BaseModel):
    name:           str
    email:          Optional[EmailStr] = None
    phone_number:   Optional[str]      = None
    password:       str
    gender:         Optional[GenderEnum] = None
    date_of_birth:  Optional[date]       = None
    specialty_id:   Optional[UUID]       = None
    bio:            Optional[str]        = None
    license_number: Optional[str]        = None


class DoctorUpdate(BaseModel):
    name:           Optional[str]        = None
    email:          Optional[EmailStr]   = None
    phone_number:   Optional[str]        = None
    gender:         Optional[GenderEnum] = None
    date_of_birth:  Optional[date]       = None
    specialty_id:   Optional[UUID]       = None
    bio:            Optional[str]        = None
    license_number: Optional[str]        = None


class DoctorProfileResponse(BaseModel):
    id:             UUID
    user_id:        UUID
    specialty_id:   Optional[UUID]
    bio:            Optional[str]
    license_number: Optional[str]
    rating:         float
    total_reviews:  int
    created_at:     datetime

    class Config:
        from_attributes = True


class DoctorFullResponse(BaseModel):
    user:    UserResponse
    profile: DoctorProfileResponse
    specialty: Optional[SpecialtyResponse] = None


# ─────────────────────────────────────────────
# Patient
# ─────────────────────────────────────────────

class PatientRegister(BaseModel):
    clinic_code:    str                    # e.g. CLIN-A3F9B2
    name:           str
    email:          Optional[EmailStr] = None
    phone_number:   Optional[str]      = None
    password:       str
    gender:         Optional[GenderEnum] = None
    date_of_birth:  Optional[date]       = None
    blood_type:     Optional[str]        = None
    allergies:      Optional[str]        = None
    chronic_conditions:      Optional[str] = None
    emergency_contact_name:  Optional[str] = None
    emergency_contact_phone: Optional[str] = None


class PatientProfileUpdate(BaseModel):
    name:           Optional[str]        = None
    email:          Optional[EmailStr]   = None
    phone_number:   Optional[str]        = None
    gender:         Optional[GenderEnum] = None
    date_of_birth:  Optional[date]       = None
    blood_type:     Optional[str]        = None
    allergies:      Optional[str]        = None
    chronic_conditions:      Optional[str] = None
    emergency_contact_name:  Optional[str] = None
    emergency_contact_phone: Optional[str] = None


class PatientProfileResponse(BaseModel):
    id:           UUID
    user_id:      UUID
    blood_type:   Optional[str]
    allergies:    Optional[str]
    chronic_conditions:      Optional[str]
    emergency_contact_name:  Optional[str]
    emergency_contact_phone: Optional[str]
    created_at:   datetime

    class Config:
        from_attributes = True


class PatientFullResponse(BaseModel):
    user:    UserResponse
    profile: PatientProfileResponse


# ─────────────────────────────────────────────
# Doctor Schedule
# ─────────────────────────────────────────────

class ScheduleCreate(BaseModel):
    day_of_week:   DayOfWeekEnum
    start_time:    time
    end_time:      time
    slot_duration: int = 30


class ScheduleUpdate(BaseModel):
    start_time:    Optional[time] = None
    end_time:      Optional[time] = None
    slot_duration: Optional[int]  = None
    is_active:     Optional[bool] = None


class ScheduleResponse(BaseModel):
    id:            UUID
    doctor_id:     UUID
    day_of_week:   DayOfWeekEnum
    start_time:    time
    end_time:      time
    slot_duration: int
    is_active:     bool
    created_at:    datetime

    class Config:
        from_attributes = True


# ─────────────────────────────────────────────
# Blocked Slots
# ─────────────────────────────────────────────

class BlockedSlotCreate(BaseModel):
    date:       date
    start_time: Optional[time] = None
    end_time:   Optional[time] = None
    reason:     Optional[str]  = None


class BlockedSlotResponse(BaseModel):
    id:         UUID
    doctor_id:  UUID
    date:       date
    start_time: Optional[time]
    end_time:   Optional[time]
    reason:     Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True


# ─────────────────────────────────────────────
# Appointment
# ─────────────────────────────────────────────

class AppointmentBook(BaseModel):
    doctor_id:  UUID       # doctor_profile ID
    date:       date
    start_time: time


class AppointmentUpdateStatus(BaseModel):
    status:              AppointmentStatusEnum
    cancellation_reason: Optional[str] = None
    consultation_notes:  Optional[str] = None


class AppointmentResponse(BaseModel):
    id:                  UUID
    clinic_id:           UUID
    doctor_id:           UUID
    doctor_name: str
    appointment_number: str
    patient_id:          UUID
    patient_name:str
    specialty_name: str
    date:                date
    start_time:          time
    end_time:            time
    status:              AppointmentStatusEnum
    consultation_notes:  Optional[str]
    cancellation_reason: Optional[str]
    created_at:          datetime
    fee_amount: Decimal | None = None
    discount_amount: Decimal | None = None
    total_due_amount: Decimal | None = None
    total_paid_amount: Decimal | None = None
    balance_amount: Decimal | None = None
    payment_status: models.PaymentStatus | None = None
    payment_note: str | None = None

    class Config:
        from_attributes = True


# ─────────────────────────────────────────────
# Prescription
# ─────────────────────────────────────────────

class PrescriptionCreate(BaseModel):
    medication: str
    dosage:     Optional[str] = None
    frequency:  Optional[str] = None
    duration:   Optional[str] = None
    notes:      Optional[str] = None


class PrescriptionResponse(BaseModel):
    id:             UUID
    appointment_id: UUID
    medication:     str
    dosage:         Optional[str]
    frequency:      Optional[str]
    duration:       Optional[str]
    notes:          Optional[str]
    created_at:     datetime

    class Config:
        from_attributes = True

class BulkPrescriptionCreate(BaseModel):
    items: List[PrescriptionCreate] = Field(min_length=1)


class BulkPrescriptionResponse(BaseModel):
    items: List[PrescriptionResponse]
    count: int
# ─────────────────────────────────────────────
# Medical File
# ─────────────────────────────────────────────

class MedicalFileResponse(BaseModel):
    id:             UUID
    appointment_id: UUID
    file_type:      FileTypeEnum
    file_name:      str
    file_url:       str
    uploaded_by:    Optional[UUID]
    created_at:     datetime

    class Config:
        from_attributes = True


# ─────────────────────────────────────────────
# Doctor Review
# ─────────────────────────────────────────────

class ReviewCreate(BaseModel):
    rating:  int = Field(ge=1, le=5)
    comment: Optional[str] = None


class ReviewResponse(BaseModel):
    id:             UUID
    appointment_id: UUID
    patient_id:     UUID
    doctor_id:      UUID
    rating:         int
    comment:        Optional[str]
    created_at:     datetime

    class Config:
        from_attributes = True


# ─────────────────────────────────────────────
# Chat
# ─────────────────────────────────────────────

class ChatMessageCreate(BaseModel):
    message: str


class ChatMessageResponse(BaseModel):
    id:             UUID
    appointment_id: UUID
    sender_id:      UUID
    sender_role:    ChatSenderEnum
    message:        str
    is_read:        bool
    created_at:     datetime

    class Config:
        from_attributes = True


# ─────────────────────────────────────────────
# Notification
# ─────────────────────────────────────────────

class NotificationResponse(BaseModel):
    id:         UUID
    user_id:    UUID
    type:       str
    title:      str
    body:       str
    is_read:    bool
    related_id: Optional[UUID]
    created_at: datetime

    class Config:
        from_attributes = True


# ─────────────────────────────────────────────
# Announcement
# ─────────────────────────────────────────────

class AnnouncementCreate(BaseModel):
    title:       str
    body:        str
    target_role: Optional[UserRoleEnum] = None


class AnnouncementResponse(BaseModel):
    id:          UUID
    clinic_id:   UUID
    created_by:  UUID
    title:       str
    body:        str
    target_role: Optional[UserRoleEnum]
    created_at:  datetime

    class Config:
        from_attributes = True


# ─────────────────────────────────────────────
# Subscription
# ─────────────────────────────────────────────

class SubscriptionResponse(BaseModel):
    id:           UUID
    clinic_id:    UUID
    plan:         SubscriptionPlanEnum
    status:       SubscriptionStatusEnum
    started_at:   datetime
    expires_at:   Optional[datetime]
    max_doctors:  int
    max_patients: int
    created_at:   datetime

    class Config:
        from_attributes = True


class InvoiceResponse(BaseModel):
    id:              UUID
    subscription_id: UUID
    amount:          float
    currency:        str
    paid:            bool
    paid_at:         Optional[datetime]
    invoice_url:     Optional[str]
    created_at:      datetime

    class Config:
        from_attributes = True


# ─────────────────────────────────────────────
# Audit Log
# ─────────────────────────────────────────────

class AuditLogResponse(BaseModel):
    id:          UUID
    clinic_id:   UUID
    user_id:     Optional[UUID]
    action:      str
    target_id:   Optional[UUID]
    target_type: Optional[str]
    detail:      Optional[str]
    created_at:  datetime

    class Config:
        from_attributes = True


# ─────────────────────────────────────────────
# Dashboard Stats
# ─────────────────────────────────────────────

class DashboardStats(BaseModel):
    total_doctors:          int
    total_patients:         int
    total_appointments:     int
    pending_appointments:   int
    completed_appointments: int
    cancelled_appointments: int


# ─────────────────────────────────────────────
# Available Slot (computed, not a DB model)
# ─────────────────────────────────────────────

class AvailableSlot(BaseModel):
    start_time: time
    end_time:   time
    
# ─────────────────────────────────────────────
# Join
# ─────────────────────────────────────────────

class JoinBranchItem(BaseModel):
    clinic_uuid: UUID
    clinic_id: str
    clinic_name: str
    clinic_slug: str | None = None
    address: str | None = None
    area: str | None = None
    phone: str | None = None
    logo_url: str | None = None
    group_id: UUID | None = None
    group_name: str | None = None
    group_slug: str | None = None


class JoinResolveBranchResponse(BaseModel):
    type: Literal["branch"]
    clinic: JoinBranchItem


class JoinResolveGroupResponse(BaseModel):
    type: Literal["group"]
    group_id: UUID
    group_name: str
    group_slug: str
    logo_url: str | None = None
    branches: list[JoinBranchItem]


class JoinSearchGroupItem(BaseModel):
    type: Literal["group"]
    group_id: UUID
    group_name: str
    group_slug: str
    logo_url: str | None = None
    branches_count: int


class JoinSearchBranchItem(BaseModel):
    type: Literal["branch"]
    clinic_uuid: UUID
    clinic_id: str
    clinic_name: str
    clinic_slug: str | None = None
    address: str | None = None
    area: str | None = None
    phone: str | None = None
    logo_url: str | None = None
    group_id: UUID | None = None
    group_name: str | None = None
    group_slug: str | None = None


class JoinSearchResponse(BaseModel):
    groups: list[JoinSearchGroupItem]
    branches: list[JoinSearchBranchItem]


class JoinResolveCodeResponse(BaseModel):
    type: Literal["branch"]
    clinic: JoinBranchItem