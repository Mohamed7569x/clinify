from fastapi import APIRouter, Response, Cookie
from datetime import timedelta
from typing import Annotated
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from pydantic import BaseModel, EmailStr, Field, validator
from app.schemas import models
from app.dependencies import (
    db_depends, get_password_hash, create_access_token,
    authenticate_user, verify_token, create_refresh_access_token, get_current_user
)
from app.services.notification_service import notify_patient_registered
import re
import uuid

router = APIRouter(tags=['Authentication'])
ACCESS_TOKEN_EXPIRE_MINUTES = 120


# ─────────────────────────────────────────────
# Token Schemas
# ─────────────────────────────────────────────

class Token(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str


class TokenData(BaseModel):
    username: str | None = None
    role: str | None = None
    clinic_id: str | None = None


class RefreshToken(BaseModel):
    refreshToken: str


# ─────────────────────────────────────────────
# Registration Schemas
# ─────────────────────────────────────────────

class ManagerRegisterRequest(BaseModel):
    """
    Clinic manager self-registers.
    A unique Clinic ID is auto-generated on success.
    """
    name: str
    email: EmailStr
    password: str
    phone_number: str | None = None

    clinic_name: str
    branch_name: str | None = None
    clinic_address: str | None = None
    clinic_phone: str | None = None
    city: str | None = None
    area: str | None = None

    @validator('password')
    def check_complexity(cls, value):
        if not re.search(r'[A-Z]', value):
            raise ValueError('Password must contain at least one uppercase letter.')
        if not re.search(r'[a-z]', value):
            raise ValueError('Password must contain at least one lowercase letter.')
        if not re.search(r'[0-9]', value):
            raise ValueError('Password must contain at least one number.')
        if not re.search(r'[!@#$%^&*(),.?":{}|<>]', value):
            raise ValueError('Password must contain at least one special character.')
        return value


class PatientRegisterRequest(BaseModel):
    """
    Patient self-registers using the Clinic ID provided by their clinic.
    """
    clinic_id: str
    name: str
    email: EmailStr | None = None
    phone_number: str | None = None
    password: str = Field(..., min_length=8)

    @validator('password')
    def check_complexity(cls, value):
        if not re.search(r'[A-Z]', value):
            raise ValueError('Password must contain at least one uppercase letter.')
        if not re.search(r'[a-z]', value):
            raise ValueError('Password must contain at least one lowercase letter.')
        if not re.search(r'[0-9]', value):
            raise ValueError('Password must contain at least one number.')
        if not re.search(r'[!@#$%^&*(),.?":{}|<>]', value):
            raise ValueError('Password must contain at least one special character.')
        return value

    @validator('phone_number', always=True)
    def email_or_phone_required(cls, phone, values):
        if not phone and not values.get('email'):
            raise ValueError('Either email or phone number is required.')
        return phone


# ─────────────────────────────────────────────
# Login Schema (Doctor & Patient)
# ─────────────────────────────────────────────

class ClinicUserLoginRequest(BaseModel):
    """
    Doctors and Patients log in using their Clinic ID + (email or phone) + password.
    Role is detected automatically from the database.
    """
    clinic_id: str
    identifier: str      # email or phone number
    password: str


# ─────────────────────────────────────────────
# Password Reset Schemas
# ─────────────────────────────────────────────

class ForgetPasswordRequest(BaseModel):
    email: str


class ResetForgetPassword(BaseModel):
    secret_token: str
    new_password: str
    confirm_password: str

    @validator('new_password')
    def check_complexity(cls, value):
        if not re.search(r'[A-Z]', value):
            raise ValueError('Password must contain at least one uppercase letter.')
        if not re.search(r'[a-z]', value):
            raise ValueError('Password must contain at least one lowercase letter.')
        if not re.search(r'[0-9]', value):
            raise ValueError('Password must contain at least one number.')
        if not re.search(r'[!@#$%^&*(),.?":{}|<>]', value):
            raise ValueError('Password must contain at least one special character.')
        return value


# ─────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────

def generate_clinic_id() -> str:
    """Generates a unique, short, uppercase Clinic ID e.g. CLIN-A3F9B2"""
    return "CLIN-" + uuid.uuid4().hex[:6].upper()


def set_refresh_cookie(response: Response, token: str):
    response.set_cookie(
        key="refresh_token",
        value=token,
        httponly=True,
        secure=False,       # Set True in production (HTTPS)
        samesite="strict",
        max_age=7 * 24 * 60 * 60,
    )


def build_token_response(identifier: str, role: str, clinic_id: str, response: Response) -> dict:
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": identifier, "role": role, "clinic_id": clinic_id},
        expires_delta=access_token_expires
    )
    refresh_token = create_refresh_access_token(
        data={"sub": identifier, "role": role, "clinic_id": clinic_id}
    )
    set_refresh_cookie(response, refresh_token)
    return {
        "success": True,
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
        "role": role,
        "clinic_id": clinic_id,
    }

def get_user_by_identifier(db, identifier: str):
    return db.query(models.User).filter(
        (models.User.email == identifier) | (models.User.phone_number == identifier)
    ).first()


def get_clinic_membership(db, user_id, clinic_id):
    return db.query(models.ClinicMembership).filter(
        models.ClinicMembership.user_id == user_id,
        models.ClinicMembership.clinic_id == clinic_id,
    ).first()
    


def slugify(value: str) -> str:
    value = value.strip().lower()
    value = re.sub(r"[^a-z0-9]+", "-", value)
    value = re.sub(r"-+", "-", value).strip("-")
    return value or "clinic"

def normalize_phone(phone: str | None) -> str | None:
    if not phone:
        return None
    return "".join(ch for ch in phone if ch.isdigit())
# ─────────────────────────────────────────────
# Routes
# ─────────────────────────────────────────────
@router.post("/api/v1/auth/manager/register/")
async def register_manager(
    data: ManagerRegisterRequest,
    db: db_depends,
    response: Response
):
    # Check duplicate email globally
    if db.query(models.User).filter_by(email=data.email).first():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="This email is already registered."
        )

    # Check duplicate phone globally
    if data.phone_number and db.query(models.User).filter_by(phone_number=data.phone_number).first():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="This phone number is already registered."
        )

    # Generate unique public clinic code
    clinic_id = generate_clinic_id()
    while db.query(models.Clinic).filter_by(clinic_id=clinic_id).first():
        clinic_id = generate_clinic_id()

    # Generate unique group slug
    group_slug = slugify(data.clinic_name)
    original_group_slug = group_slug
    counter = 2
    while db.query(models.ClinicGroup).filter_by(slug=group_slug).first():
        group_slug = f"{original_group_slug}-{counter}"
        counter += 1

    # Generate unique branch slug
    branch_name = (data.branch_name or "Main Branch").strip()
    branch_slug = slugify(f"{data.clinic_name}-{branch_name}")
    original_branch_slug = branch_slug
    counter = 2
    while db.query(models.Clinic).filter_by(branch_slug=branch_slug).first():
        branch_slug = f"{original_branch_slug}-{counter}"
        counter += 1

    hashed_password = get_password_hash(data.password)

    try:
        # 1) Create clinic group
        group = models.ClinicGroup(
            name=data.clinic_name.strip(),
            slug=group_slug,
            main_phone=data.clinic_phone,
            is_active=True,
        )
        db.add(group)
        db.flush()

        # 2) Create first branch
        clinic = models.Clinic(
            clinic_id=clinic_id,
            group_id=group.id,
            name=data.clinic_name.strip(),   # keep for backward compatibility
            branch_name=branch_name,
            branch_slug=branch_slug,
            address=data.clinic_address,
            phone=data.clinic_phone,
            search_phone=normalize_phone(data.clinic_phone) if data.clinic_phone else None,
            city=data.city,
            area=data.area,
            is_default_branch=True,
            is_discoverable=True,
            is_active=True,
        )
        db.add(clinic)
        db.flush()

        # 3) Create manager user
        manager = models.User(
            name=data.name,
            email=data.email,
            phone_number=data.phone_number,
            password_hash=hashed_password,
            role=models.UserRole.clinic_manager,
            is_active=True,
        )
        db.add(manager)
        db.flush()

        # 4) Create membership on the first branch
        membership = models.ClinicMembership(
            clinic_id=clinic.id,
            user_id=manager.id,
            role=models.UserRole.clinic_manager,
            is_active=True,
        )
        db.add(membership)
        db.flush()

        # 5) Keep subscription on clinic for now if you haven't migrated it yet
        subscription = models.Subscription(
            clinic_id=clinic.id,
            plan=models.SubscriptionPlan.FREE,
            status=models.SubscriptionStatus.TRIAL,
        )
        db.add(subscription)
        db.flush()

        db.commit()

    except Exception:
        db.rollback()
        raise

    return {
        "success": True,
        "message": "Clinic registered successfully.",
        "clinic_id": clinic.clinic_id,
        "group_id": str(group.id),
        "branch_id": str(clinic.id),
        "group_slug": group.slug,
        "branch_slug": clinic.branch_slug,
    }

@router.post("/api/v1/auth/patient/register/")
async def register_patient(data: PatientRegisterRequest, db: db_depends):
    """
    Patient self-registers using the Clinic ID provided by their clinic manager.
    If the patient already has a global account, link it to the clinic instead of creating a new account.
    """
    clinic = db.query(models.Clinic).filter_by(clinic_id=data.clinic_id).first()
    if not clinic:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Invalid Clinic ID. Please check with your clinic."
        )

    subscription = db.query(models.Subscription).filter_by(clinic_id=clinic.id).first()
    if subscription:
        current_count = db.query(models.ClinicMembership).filter(
            models.ClinicMembership.clinic_id == clinic.id,
            models.ClinicMembership.role == models.UserRole.patient,
        ).count()
        if current_count >= subscription.max_patients:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="This clinic has reached its patient limit. Please contact the clinic administration.",
            )

    # Find existing global user by email or phone
    existing_user = None
    if data.email:
        existing_user = db.query(models.User).filter_by(email=data.email).first()

    if not existing_user and data.phone_number:
        existing_user = db.query(models.User).filter_by(phone_number=data.phone_number).first()

    if existing_user:
        # Prevent conflicting identity data
        if data.email and existing_user.email and existing_user.email != data.email:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="This email belongs to another account."
            )

        if data.phone_number and existing_user.phone_number and existing_user.phone_number != data.phone_number:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="This phone number belongs to another account."
            )

        # Optional password check:
        # If you want to prevent someone from attaching another person's account,
        # verify credentials here using your password verification helper.
        # If your authenticate_user only accepts identifier, use email first then phone.
        verified_user = None
        if existing_user.email:
            verified_user = authenticate_user(existing_user.email, data.password, db)
        if not verified_user and existing_user.phone_number:
            verified_user = authenticate_user(existing_user.phone_number, data.password, db)

        if not verified_user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="An account with this email or phone already exists. Please use the same password for that account."
            )

        patient = existing_user

        # Update missing info only
        if not patient.name and data.name:
            patient.name = data.name
        if not patient.email and data.email:
            patient.email = data.email
        if not patient.phone_number and data.phone_number:
            patient.phone_number = data.phone_number

    else:
        hashed_password = get_password_hash(data.password)
        patient = models.User(
            name=data.name,
            email=data.email,
            phone_number=data.phone_number,
            password_hash=hashed_password,
            role=models.UserRole.patient,   # keep for compatibility if still present
            is_active=True,
        )
        db.add(patient)
        db.flush()

    # Check if already linked to this clinic
    existing_membership = db.query(models.ClinicMembership).filter(
        models.ClinicMembership.user_id == patient.id,
        models.ClinicMembership.clinic_id == clinic.id,
    ).first()

    if existing_membership:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="This account is already registered in this clinic."
        )

    membership = models.ClinicMembership(
        clinic_id=clinic.id,
        user_id=patient.id,
        role=models.UserRole.patient,
        is_active=True,   # manager approval per clinic
    )
    db.add(membership)
    db.flush()

    patient_profile = db.query(models.PatientProfile).filter(
        models.PatientProfile.user_id == patient.id,
        models.PatientProfile.clinic_id == clinic.id,
    ).first()

    if not patient_profile:
        patient_profile = models.PatientProfile(
            user_id=patient.id,
            clinic_id=clinic.id,
        )
        db.add(patient_profile)
        db.flush()

    notify_patient_registered(db, clinic.id, data.name)

    return {
        "success": True,
        "message": "Registration successful.",
    }

@router.post("/api/v1/auth/manager/login/")
async def login_manager(
    form_data: Annotated[OAuth2PasswordRequestForm, Depends()],
    db: db_depends,
    response: Response
):
    """
    Manager logs in with email + password only.
    """
    user = authenticate_user(form_data.username, form_data.password, db)

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid credentials."
        )

    membership = db.query(models.ClinicMembership).filter(
        models.ClinicMembership.user_id == user.id,
        models.ClinicMembership.role == models.UserRole.clinic_manager,
        models.ClinicMembership.is_active == True,
    ).first()

    if not membership:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Manager account not found."
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Your account is not active."
        )

    clinic = db.query(models.Clinic).filter_by(id=membership.clinic_id).first()
    if not clinic:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Clinic not found."
        )

    return build_token_response(
        identifier=user.email or user.phone_number,
        role=membership.role.value,
        clinic_id=clinic.clinic_id,
        response=response
    )
@router.post("/api/v1/auth/clinic/login/")
async def login_clinic_user(data: ClinicUserLoginRequest, db: db_depends, response: Response):
    print(data)
    clinic = db.query(models.Clinic).filter_by(clinic_id=data.clinic_id).first()
    if not clinic:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Invalid Clinic ID."
        )

    user = authenticate_user(data.identifier, data.password, db)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid credentials."
        )

    membership = db.query(models.ClinicMembership).filter(
        models.ClinicMembership.user_id == user.id,
        models.ClinicMembership.clinic_id == clinic.id,
    ).first()

    if not membership:
        if user.role != models.UserRole.patient:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="This account is not assigned to this clinic."
            )

        membership = models.ClinicMembership(
            clinic_id=clinic.id,
            user_id=user.id,
            role=models.UserRole.patient,
            is_active=True,
        )
        db.add(membership)
        db.flush()

        patient_profile = db.query(models.PatientProfile).filter(
            models.PatientProfile.user_id == user.id,
            models.PatientProfile.clinic_id == clinic.id,
        ).first()

        if not patient_profile:
            db.add(models.PatientProfile(
                user_id=user.id,
                clinic_id=clinic.id,
            ))
            db.flush()

    if membership.role == models.UserRole.clinic_manager:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Managers must use the manager login endpoint."
        )

    if not membership.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Your account is not approved in this clinic yet."
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="الحساب الخاص بك غير نشط"
        )

    return build_token_response(
        identifier=user.email or user.phone_number or data.identifier,
        role=membership.role.value,
        clinic_id=data.clinic_id,
        response=response
    )


@router.post("/api/v1/auth/refresh/", response_model=Token)
def refresh_token(refresh_token: str = Cookie(None)):
    """
    Issues a new access token and refresh token using the refresh token cookie.
    clinic_id and role are preserved from the original token.
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials.",
        headers={"WWW-Authenticate": "Bearer"},
    )

    if not refresh_token:
        raise credentials_exception

    token_data = verify_token(refresh_token, credentials_exception)

    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    new_access_token = create_access_token(
        data={"sub": token_data.username, "role": token_data.role, "clinic_id": token_data.clinic_id},
        expires_delta=access_token_expires
    )
    new_refresh_token = create_refresh_access_token(
        data={"sub": token_data.username, "role": token_data.role, "clinic_id": token_data.clinic_id}
    )

    return {
        "access_token": new_access_token,
        "refresh_token": new_refresh_token,
        "token_type": "bearer"
    }


@router.post("/api/v1/auth/logout/", status_code=200)
async def logout_user(response: Response):
    """
    Logs out by clearing the refresh token cookie.
    The access token is stored in frontend memory — no server action needed for it.
    """
    response.set_cookie(
        key="refresh_token",
        value="",
        httponly=True,
        secure=False,   # Set True in production
        samesite="strict",
        max_age=0,
        expires=0,
        path="/"
    )
    return {
        "success": True,
        "message": "Logout successful. Session cleared."
    }
    
fcmrouter = APIRouter(prefix="/api/v1/users", tags=["Users"])
    
class FcmTokenUpdate(BaseModel):
    fcm_token: str
 
 
@fcmrouter.put("/fcm-token")
async def update_fcm_token(
    payload: FcmTokenUpdate,
    current_user: Annotated[models.User, Depends(get_current_user)],
    db: db_depends,
):
    """Save the user's FCM token for push notifications."""
    current_user.fcm_token = payload.fcm_token
    db.flush()
    return {"success": True}


class SwitchClinicRequest(BaseModel):
    clinic_id: str
    
class MyClinicItem(BaseModel):
    clinic_uuid: str
    clinic_id: str
    clinic_name: str
    area: str
    branch_name: str | None = None
    branch_slug: str | None = None
    group_id: str | None = None
    group_name: str | None = None
    group_slug: str | None = None
    role: str
    is_active: bool
    
@router.get("/api/v1/auth/my-clinics/")
async def list_my_clinics(
    current_user: Annotated[models.User, Depends(get_current_user)],
    db: db_depends,
):
    memberships = (
        db.query(models.ClinicMembership)
        .join(models.Clinic, models.Clinic.id == models.ClinicMembership.clinic_id)
        .filter(models.ClinicMembership.user_id == current_user.id)
        .all()
    )

    current_clinic_id = getattr(current_user, "current_clinic_id", None)

    items = []

    for membership in memberships:
        clinic = membership.clinic

        if not clinic:
            continue

        group = clinic.group if hasattr(clinic, "group") else None

        items.append({
            "clinic_uuid": str(clinic.id),
            "clinic_id": clinic.clinic_id,
            "clinic_name": clinic.name,
            "area": clinic.area,
            "branch_name": getattr(clinic, "branch_name", None),
            "branch_slug": getattr(clinic, "branch_slug", None),

            "group_id": str(group.id) if group else None,
            "group_name": group.name if group else None,
            "group_slug": group.slug if group else None,

            "role": membership.role.value,
            "is_active": membership.is_active,

            "is_current": clinic.id == current_clinic_id
        })

    return {
        "success": True,
        "items": items,
    }
    
@router.post("/api/v1/auth/switch-clinic/")
async def switch_clinic(
    payload: SwitchClinicRequest,
    current_user: Annotated[models.User, Depends(get_current_user)],
    db: db_depends,
    response: Response,
):
    clinic = db.query(models.Clinic).filter_by(clinic_id=payload.clinic_id).first()
    if not clinic:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Clinic not found."
        )

    membership = db.query(models.ClinicMembership).filter(
        models.ClinicMembership.user_id == current_user.id,
        models.ClinicMembership.clinic_id == clinic.id,
    ).first()

    if not membership:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This account is not linked to this clinic."
        )

    if not membership.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Your access to this clinic is not active."
        )

    return build_token_response(
        identifier=current_user.email or current_user.phone_number,
        role=membership.role.value,
        clinic_id=clinic.clinic_id,
        response=response,
    )