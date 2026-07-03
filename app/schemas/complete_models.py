from __future__ import annotations


from eralchemy import render_er

import os
os.environ["PATH"] += os.pathsep + 'D:/Program Files (x86)/Graphviz/bin/'

# models.py

from sqlalchemy import (
    Column, Integer, String, Float, Boolean, DateTime, ForeignKey,
    Text, Enum, func, UniqueConstraint, Date, Time, SmallInteger
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship, declarative_base
import uuid
import enum

Base = declarative_base()


# ─────────────────────────────────────────────
# Enums
# ─────────────────────────────────────────────
from sqlalchemy import (
    Column, Integer, String, Float, Boolean, DateTime, ForeignKey,
    Text, Enum, func, UniqueConstraint, Date, Time, SmallInteger, Numeric
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship, declarative_base
import uuid
import enum

Base = declarative_base()


# ─────────────────────────────────────────────
# Enums
# ─────────────────────────────────────────────

class UserRole(enum.Enum):
    clinic_manager = "clinic_manager"
    doctor         = "doctor"
    patient        = "patient"


class AppointmentStatus(enum.Enum):
    PENDING    = "PENDING"      # Patient booked, waiting confirmation
    CONFIRMED  = "CONFIRMED"    # Doctor/manager confirmed
    COMPLETED  = "COMPLETED"    # Visit done
    CANCELLED  = "CANCELLED"    # Cancelled by either party
    NO_SHOW    = "NO_SHOW"      # Patient didn't show up
    RESCHEDULED = "RESCHEDULED" # Moved to another slot


class DayOfWeek(enum.Enum):
    MONDAY    = "MONDAY"
    TUESDAY   = "TUESDAY"
    WEDNESDAY = "WEDNESDAY"
    THURSDAY  = "THURSDAY"
    FRIDAY    = "FRIDAY"
    SATURDAY  = "SATURDAY"
    SUNDAY    = "SUNDAY"


class NotificationType(enum.Enum):
    APPOINTMENT_BOOKED      = "APPOINTMENT_BOOKED"
    APPOINTMENT_CONFIRMED   = "APPOINTMENT_CONFIRMED"
    APPOINTMENT_CANCELLED   = "APPOINTMENT_CANCELLED"
    APPOINTMENT_REMINDER    = "APPOINTMENT_REMINDER"
    APPOINTMENT_RESCHEDULED = "APPOINTMENT_RESCHEDULED"
    PRESCRIPTION_ADDED      = "PRESCRIPTION_ADDED"
    ACCOUNT_APPROVED        = "ACCOUNT_APPROVED"
    GENERAL                 = "GENERAL"


class SubscriptionPlan(enum.Enum):
    FREE       = "FREE"
    BASIC      = "BASIC"
    PRO        = "PRO"
    ENTERPRISE = "ENTERPRISE"


class SubscriptionStatus(enum.Enum):
    ACTIVE   = "ACTIVE"
    EXPIRED  = "EXPIRED"
    TRIAL    = "TRIAL"
    CANCELLED = "CANCELLED"


class FileType(enum.Enum):
    LAB_RESULT   = "LAB_RESULT"
    PRESCRIPTION = "PRESCRIPTION"
    SCAN         = "SCAN"
    REPORT       = "REPORT"
    OTHER        = "OTHER"


class ChatMessageSender(enum.Enum):
    DOCTOR  = "DOCTOR"
    PATIENT = "PATIENT"


class Gender(enum.Enum):
    MALE   = "MALE"
    FEMALE = "FEMALE"
    OTHER  = "OTHER"

# =========================
# Financial Enums
# =========================

class PaymentStatus(enum.Enum):
    UNPAID   = "UNPAID"
    PARTIAL  = "PARTIAL"
    PAID     = "PAID"
    WAIVED   = "WAIVED"
    REFUNDED = "REFUNDED"


class MoneyFlow(enum.Enum):
    INFLOW  = "INFLOW"
    OUTFLOW = "OUTFLOW"


class LedgerEntryType(enum.Enum):
    PATIENT_PAYMENT    = "PATIENT_PAYMENT"
    PAYMENT_ADJUSTMENT = "PAYMENT_ADJUSTMENT"
    REFUND             = "REFUND"
    WAIVER             = "WAIVER"

    RENT          = "RENT"
    SALARY        = "SALARY"
    UTILITIES     = "UTILITIES"
    SUPPLIES      = "SUPPLIES"
    MAINTENANCE   = "MAINTENANCE"
    MARKETING     = "MARKETING"
    TAX           = "TAX"
    OTHER_EXPENSE = "OTHER_EXPENSE"

    OWNER_DRAW    = "OWNER_DRAW"
    OTHER_INCOME  = "OTHER_INCOME"


class PaymentMethod(enum.Enum):
    CASH          = "CASH"
    CARD          = "CARD"
    INSTAPAY      = "INSTAPAY"
    VODAFONE_CASH = "VODAFONE_CASH"
    BANK_TRANSFER = "BANK_TRANSFER"
    OTHER         = "OTHER"
# ─────────────────────────────────────────────
# Clinic
# ─────────────────────────────────────────────
class ClinicGroup(Base):
    __tablename__ = "clinic_groups"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String, nullable=False)
    slug = Column(String, unique=True, nullable=False, index=True)
    logo_url = Column(String)
    website = Column(String)
    main_phone = Column(String)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    branches = relationship("Clinic", back_populates="group")
    
class Clinic(Base):
    __tablename__ = "clinics"

    id         = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    clinic_id  = Column(String(20), unique=True, nullable=False, index=True)
    name       = Column(String, nullable=False)
    address    = Column(String)
    phone      = Column(String)
    logo_url   = Column(String)
    website    = Column(String)
    is_active  = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    
    
    group_id = Column(UUID(as_uuid=True), ForeignKey("clinic_groups.id"), nullable=True, index=True)
    branch_name = Column(String)
    branch_slug = Column(String, unique=True, index=True)
    city = Column(String)
    area = Column(String)
    search_phone = Column(String, index=True)
    join_code = Column(String(20), unique=True, index=True, nullable=True)
    is_discoverable = Column(Boolean, default=True)
    is_default_branch = Column(Boolean, default=False)

    group = relationship("ClinicGroup", back_populates="branches")
    memberships   = relationship("ClinicMembership", back_populates="clinic", cascade="all, delete-orphan")
    specialties   = relationship("Specialty", back_populates="clinic")
    appointments  = relationship("Appointment", back_populates="clinic")
    announcements = relationship("Announcement", back_populates="clinic")
    subscription  = relationship("Subscription", back_populates="clinic", uselist=False)
    audit_logs    = relationship("AuditLog", back_populates="clinic")
    
    ledger_entries = relationship(
    "ClinicLedgerEntry",
    back_populates="clinic",
    cascade="all, delete-orphan"
)


# ─────────────────────────────────────────────
# Subscription
# ─────────────────────────────────────────────

class Subscription(Base):
    __tablename__ = "subscriptions"

    id         = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    clinic_id  = Column(UUID(as_uuid=True), ForeignKey("clinics.id"), unique=True, nullable=False)
    plan       = Column(Enum(SubscriptionPlan), nullable=False, default=SubscriptionPlan.FREE)
    status     = Column(Enum(SubscriptionStatus), nullable=False, default=SubscriptionStatus.TRIAL)
    started_at = Column(DateTime(timezone=True), server_default=func.now())
    expires_at = Column(DateTime(timezone=True))
    max_doctors  = Column(Integer, default=3)    # Enforced by plan tier
    max_patients = Column(Integer, default=100)
    created_at   = Column(DateTime(timezone=True), server_default=func.now())
    updated_at   = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    # Relationships
    clinic   = relationship("Clinic",  back_populates="subscription")
    invoices = relationship("Invoice", back_populates="subscription")


# ─────────────────────────────────────────────
# Invoice
# ─────────────────────────────────────────────

class Invoice(Base):
    __tablename__ = "invoices"

    id              = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    subscription_id = Column(UUID(as_uuid=True), ForeignKey("subscriptions.id"), nullable=False)
    amount          = Column(Float, nullable=False)
    currency        = Column(String(10), default="USD")
    paid            = Column(Boolean, default=False)
    paid_at         = Column(DateTime(timezone=True))
    invoice_url     = Column(String)   # Link to PDF invoice
    created_at      = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    subscription = relationship("Subscription", back_populates="invoices")


# ─────────────────────────────────────────────
# User  (Manager / Doctor / Patient — single table, role-based)
# ─────────────────────────────────────────────
class User(Base):
    __tablename__ = "users"

    id            = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    role          = Column(Enum(UserRole), nullable=False)
    name          = Column(String, nullable=False)
    email         = Column(String, unique=True, index=True, nullable=True)
    phone_number  = Column(String, unique=True, index=True, nullable=True)
    password_hash = Column(String, nullable=False)
    gender        = Column(Enum(Gender))
    date_of_birth = Column(Date)
    avatar_url    = Column(String)
    fcm_token     = Column(String)
    is_active     = Column(Boolean, default=False)
    created_at    = Column(DateTime(timezone=True), server_default=func.now())
    updated_at    = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    memberships     = relationship("ClinicMembership", back_populates="user", cascade="all, delete-orphan")
    doctor_profile  = relationship("DoctorProfile", back_populates="user", uselist=False)
    patient_profile = relationship("PatientProfile", back_populates="user", uselist=False)
    notifications   = relationship("Notification", back_populates="user")
    audit_logs      = relationship("AuditLog", back_populates="user")
    sent_messages   = relationship("ChatMessage", back_populates="sender",
                                   foreign_keys="ChatMessage.sender_id")
    created_ledger_entries = relationship(
    "ClinicLedgerEntry",
    foreign_keys="ClinicLedgerEntry.created_by",
    back_populates="creator",
)

class ClinicMembership(Base):
    __tablename__ = "clinic_memberships"

    id         = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    clinic_id  = Column(UUID(as_uuid=True), ForeignKey("clinics.id"), nullable=False)
    user_id    = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    role       = Column(Enum(UserRole), nullable=False)
    is_active  = Column(Boolean, default=True)
    joined_at  = Column(DateTime(timezone=True), server_default=func.now())

    __table_args__ = (
        UniqueConstraint("clinic_id", "user_id", name="uq_clinic_user_membership"),
    )

    clinic = relationship("Clinic", back_populates="memberships")
    user   = relationship("User", back_populates="memberships")
# ─────────────────────────────────────────────
# Specialty
# ─────────────────────────────────────────────

class Specialty(Base):
    __tablename__ = "specialties"

    id        = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    clinic_id = Column(UUID(as_uuid=True), ForeignKey("clinics.id"), nullable=False)
    name      = Column(String, nullable=False)

    # Relationships
    clinic          = relationship("Clinic",        back_populates="specialties")
    doctor_profiles = relationship("DoctorProfile", back_populates="specialty")

    __table_args__ = (
        UniqueConstraint("clinic_id", "name", name="uq_specialty_per_clinic"),
    )


# ─────────────────────────────────────────────
# Doctor Profile
# ─────────────────────────────────────────────

class DoctorProfile(Base):
    __tablename__ = "doctor_profiles"

    id           = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id    = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    clinic_id  = Column(UUID(as_uuid=True), ForeignKey("clinics.id"), nullable=False)
    specialty_id = Column(UUID(as_uuid=True), ForeignKey("specialties.id"))
    bio          = Column(Text)
    license_number = Column(String)
    rating       = Column(Float, default=0.0)   # Avg rating from patient reviews
    total_reviews = Column(Integer, default=0)
    created_at   = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    user = relationship("User", back_populates="doctor_profile")
    specialty     = relationship("Specialty",        back_populates="doctor_profiles")
    schedules     = relationship("DoctorSchedule",   back_populates="doctor")
    blocked_slots = relationship("BlockedSlot",      back_populates="doctor")
    appointments  = relationship("Appointment",      back_populates="doctor")
    
    __table_args__ = (
        UniqueConstraint("user_id", "clinic_id", name="uq_doctor_profile_user_clinic"),
    )


# ─────────────────────────────────────────────
# Patient Profile
# ─────────────────────────────────────────────

class PatientProfile(Base):
    __tablename__ = "patient_profiles"

    id           = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id    = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    clinic_id  = Column(UUID(as_uuid=True), ForeignKey("clinics.id"), nullable=False)
    blood_type   = Column(String(5))
    allergies    = Column(Text)
    chronic_conditions = Column(Text)
    emergency_contact_name  = Column(String)
    emergency_contact_phone = Column(String)
    created_at   = Column(DateTime(timezone=True), server_default=func.now())
    updated_at   = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    
    user = relationship("User", back_populates="patient_profile")

    appointments  = relationship("Appointment",  back_populates="patient")
    reviews       = relationship("DoctorReview", back_populates="patient")
    
    __table_args__ = (
        UniqueConstraint("user_id", "clinic_id", name="uq_patient_profile_user_clinic"),
    )


# ─────────────────────────────────────────────
# Doctor Weekly Schedule
# ─────────────────────────────────────────────

class DoctorSchedule(Base):
    """
    Defines a doctor's recurring weekly availability.
    e.g. Every MONDAY from 09:00 to 13:00 with 30-minute slots.
    """
    __tablename__ = "doctor_schedules"

    id            = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    doctor_id     = Column(UUID(as_uuid=True), ForeignKey("doctor_profiles.id"), nullable=False)
    day_of_week   = Column(Enum(DayOfWeek), nullable=False)
    start_time    = Column(Time, nullable=False)
    end_time      = Column(Time, nullable=False)
    slot_duration = Column(SmallInteger, default=30)  # Minutes per appointment slot
    is_active     = Column(Boolean, default=True)
    created_at    = Column(DateTime(timezone=True), server_default=func.now())

    __table_args__ = (
        UniqueConstraint("doctor_id", "day_of_week", name="uq_doctor_day_schedule"),
    )

    # Relationships
    doctor = relationship("DoctorProfile", back_populates="schedules")


# ─────────────────────────────────────────────
# Blocked Slots  (vacation, emergency, etc.)
# ─────────────────────────────────────────────

class BlockedSlot(Base):
    """
    Specific date/time ranges where the doctor is unavailable.
    Overrides the weekly schedule.
    """
    __tablename__ = "blocked_slots"

    id         = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    doctor_id  = Column(UUID(as_uuid=True), ForeignKey("doctor_profiles.id"), nullable=False)
    date       = Column(Date, nullable=False)
    start_time = Column(Time)   # Null = entire day blocked
    end_time   = Column(Time)
    reason     = Column(String)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    doctor = relationship("DoctorProfile", back_populates="blocked_slots")


# ─────────────────────────────────────────────
# Appointment
# ─────────────────────────────────────────────

class Appointment(Base):
    __tablename__ = "appointments"

    id                = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    appointment_number = Column(String, unique=True, index=True, nullable=True)
    clinic_id         = Column(UUID(as_uuid=True), ForeignKey("clinics.id"), nullable=False)
    doctor_id         = Column(UUID(as_uuid=True), ForeignKey("doctor_profiles.id"), nullable=False)
    patient_id        = Column(UUID(as_uuid=True), ForeignKey("patient_profiles.id"), nullable=False)
    date              = Column(Date, nullable=False)
    start_time        = Column(Time, nullable=False)
    end_time          = Column(Time, nullable=False)
    status            = Column(Enum(AppointmentStatus), nullable=False, default=AppointmentStatus.PENDING)
    consultation_notes = Column(Text)         # Doctor fills after visit
    cancellation_reason = Column(String)
    created_at        = Column(DateTime(timezone=True), server_default=func.now())
    updated_at        = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    
    fee_amount        = Column(Numeric(12, 2), default=0.0)
    discount_amount   = Column(Numeric(12, 2), default=0.0)
    total_due_amount  = Column(Numeric(12, 2), default=0.0)
    total_paid_amount = Column(Numeric(12, 2), default=0.0)
    balance_amount    = Column(Numeric(12, 2), default=0.0)
    payment_status    = Column(Enum(PaymentStatus), nullable=False, default=PaymentStatus.UNPAID)
    payment_note      = Column(Text)

    financial_entries = relationship(
        "ClinicLedgerEntry",
        back_populates="appointment",
        cascade="all, delete-orphan"
    )

    # Relationships
    clinic        = relationship("Clinic",         back_populates="appointments")
    doctor        = relationship("DoctorProfile",  back_populates="appointments")
    patient       = relationship("PatientProfile", back_populates="appointments")
    prescriptions = relationship("Prescription",   back_populates="appointment")
    attachments   = relationship("MedicalFile",    back_populates="appointment")
    review        = relationship("DoctorReview",   back_populates="appointment", uselist=False)



# =========================
# New model
# =========================

class ClinicLedgerEntry(Base):
    __tablename__ = "clinic_ledger_entries"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    clinic_id = Column(UUID(as_uuid=True), ForeignKey("clinics.id"), nullable=False)
    appointment_id = Column(UUID(as_uuid=True), ForeignKey("appointments.id"), nullable=True)

    created_by = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True)

    entry_type = Column(Enum(LedgerEntryType), nullable=False)
    money_flow = Column(Enum(MoneyFlow), nullable=False)
    payment_method = Column(Enum(PaymentMethod), nullable=True)

    amount = Column(Numeric(12, 2), nullable=False)
    note = Column(Text)
    reference = Column(String)

    effective_date = Column(Date, nullable=False, server_default=func.current_date())
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    clinic = relationship("Clinic", back_populates="ledger_entries")
    appointment = relationship("Appointment", back_populates="financial_entries")
    creator = relationship("User", foreign_keys=[created_by])
    
    creator = relationship(
    "User",
    foreign_keys=[created_by],
    back_populates="created_ledger_entries",
)
# ─────────────────────────────────────────────
# Prescription
# ─────────────────────────────────────────────

class Prescription(Base):
    __tablename__ = "prescriptions"

    id             = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    appointment_id = Column(UUID(as_uuid=True), ForeignKey("appointments.id"), nullable=False)
    medication     = Column(String, nullable=False)
    dosage         = Column(String)       # e.g. "500mg"
    frequency      = Column(String)       # e.g. "Twice daily"
    duration       = Column(String)       # e.g. "7 days"
    notes          = Column(Text)
    created_at     = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    appointment = relationship("Appointment", back_populates="prescriptions")


# ─────────────────────────────────────────────
# Medical File  (lab results, scans, reports)
# ─────────────────────────────────────────────

class MedicalFile(Base):
    __tablename__ = "medical_files"

    id             = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    appointment_id = Column(UUID(as_uuid=True), ForeignKey("appointments.id"), nullable=False)
    file_type      = Column(Enum(FileType), nullable=False)
    file_name      = Column(String, nullable=False)
    file_url       = Column(String, nullable=False)   # S3 / storage URL
    uploaded_by    = Column(UUID(as_uuid=True), ForeignKey("users.id"))  # Doctor or Patient
    created_at     = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    appointment = relationship("Appointment", back_populates="attachments")


# ─────────────────────────────────────────────
# Doctor Review
# ─────────────────────────────────────────────

class DoctorReview(Base):
    __tablename__ = "doctor_reviews"

    id             = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    appointment_id = Column(UUID(as_uuid=True), ForeignKey("appointments.id"), unique=True, nullable=False)
    patient_id     = Column(UUID(as_uuid=True), ForeignKey("patient_profiles.id"), nullable=False)
    doctor_id      = Column(UUID(as_uuid=True), ForeignKey("doctor_profiles.id"), nullable=False)
    rating         = Column(SmallInteger, nullable=False)   # 1–5
    comment        = Column(Text)
    created_at     = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    appointment = relationship("Appointment",   back_populates="review")
    patient     = relationship("PatientProfile",back_populates="reviews")
    doctor      = relationship("DoctorProfile")


# ─────────────────────────────────────────────
# Chat Message
# ─────────────────────────────────────────────

class ChatMessage(Base):
    """
    Simple text chat between a doctor and a patient.
    Scoped to an appointment to keep conversations organized.
    """
    __tablename__ = "chat_messages"

    id             = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    appointment_id = Column(UUID(as_uuid=True), ForeignKey("appointments.id"), nullable=False)
    sender_id      = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    sender_role    = Column(Enum(ChatMessageSender), nullable=False)
    message        = Column(Text, nullable=False)
    is_read        = Column(Boolean, default=False)
    created_at     = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    sender = relationship("User", back_populates="sent_messages", foreign_keys=[sender_id])


# ─────────────────────────────────────────────
# Notification
# ─────────────────────────────────────────────

class Notification(Base):
    __tablename__ = "notifications"

    id               = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id          = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    type             = Column(Enum(NotificationType), nullable=False)
    title            = Column(String, nullable=False)
    body             = Column(Text, nullable=False)
    is_read          = Column(Boolean, default=False)
    related_id       = Column(UUID(as_uuid=True))   # ID of the related appointment, etc.
    created_at       = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    user = relationship("User", back_populates="notifications")


# ─────────────────────────────────────────────
# Announcement  (broadcast from manager to clinic users)
# ─────────────────────────────────────────────

class Announcement(Base):
    __tablename__ = "announcements"

    id         = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    clinic_id  = Column(UUID(as_uuid=True), ForeignKey("clinics.id"), nullable=False)
    created_by = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    title      = Column(String, nullable=False)
    body       = Column(Text, nullable=False)
    target_role = Column(Enum(UserRole))   # Null = all users, or specific role
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    clinic = relationship("Clinic", back_populates="announcements")


# ─────────────────────────────────────────────
# Audit Log
# ─────────────────────────────────────────────

class AuditLog(Base):
    """
    Tracks critical actions per clinic for compliance and debugging.
    e.g. doctor deactivated, appointment cancelled, plan upgraded.
    """
    __tablename__ = "audit_logs"

    id         = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    clinic_id  = Column(UUID(as_uuid=True), ForeignKey("clinics.id"), nullable=False)
    user_id    = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    action     = Column(String, nullable=False)    # e.g. "DOCTOR_DEACTIVATED"
    target_id  = Column(UUID(as_uuid=True))        # ID of the affected entity
    target_type = Column(String)                   # e.g. "User", "Appointment"
    detail     = Column(Text)                      # JSON or free-text extra info
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    clinic = relationship("Clinic", back_populates="audit_logs")
    user   = relationship("User",   back_populates="audit_logs")



from graphviz import Source

render_er(Base, "mymodel.dot")

graph_attr = {
    "rankdir": "LR",    # left-to-right instead of top-to-bottom
    "ranksep": "2.0",   # vertical spacing
    "nodesep": "3.0",   # horizontal spacing
    "dpi": "300"
}

src = Source.from_file("mymodel.dot")

# try 'dot', 'neato', 'fdp', 'sfdp', 'circo', 'twopi'
src.engine = "dot"  # good for very large graphs
src.graph_attr = graph_attr
pdf_path = src.render("mymodel", format="pdf", cleanup=True)
print("Wrote:", pdf_path)



