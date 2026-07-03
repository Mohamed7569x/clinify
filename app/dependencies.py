from datetime import datetime, timedelta, timezone
from typing import Annotated
import jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jwt.exceptions import InvalidTokenError
from passlib.context import CryptContext
from pydantic import BaseModel
from app.schemas import models
from app.database.database import SessionLocal, engine
from sqlalchemy.orm import Session

SECRET_KEY = "09d25e094faa6ca2556c818166b7a9563b93f7099f6f0f4caa6cf63b88e8d3e7"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 120


pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# Two separate OAuth2 schemes — manager uses email/password form, clinic users use JSON body
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/manager/login/")


# ─────────────────────────────────────────────
# Pydantic Token Models
# ─────────────────────────────────────────────

class Token(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str


class TokenData(BaseModel):
    username: str | None = None   # email or phone
    role: str | None = None
    clinic_id: str | None = None  # Human-readable clinic code e.g. CLIN-A3F9B2


# ─────────────────────────────────────────────
# DB Dependency
# ─────────────────────────────────────────────

def get_db():
    db = SessionLocal()
    try:
        yield db
        db.commit()
    finally:
        db.close()


db_depends = Annotated[Session, Depends(get_db)]


# ─────────────────────────────────────────────
# Password Utils
# ─────────────────────────────────────────────

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)


def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)

def get_clinic_and_membership(
    db: Session,
    user_id,
    clinic_public_id: str,
) -> tuple[models.Clinic | None, models.ClinicMembership | None]:
    clinic = db.query(models.Clinic).filter(
        models.Clinic.clinic_id == clinic_public_id
    ).one_or_none()

    if not clinic:
        return None, None

    membership = db.query(models.ClinicMembership).filter(
        models.ClinicMembership.user_id == user_id,
        models.ClinicMembership.clinic_id == clinic.id,
    ).one_or_none()

    return clinic, membership

# ─────────────────────────────────────────────
# Authenticate User
# ─────────────────────────────────────────────
def authenticate_user(
    identifier: str,
    password: str,
    db: Session,
) -> models.User | None:
    """
    Finds a global user by email or phone and verifies password.
    """
    user = db.query(models.User).filter(
        (models.User.email == identifier) | (models.User.phone_number == identifier)
    ).one_or_none()

    if not user:
        return None
    if not verify_password(password, user.password_hash):
        return None

    return user


# ─────────────────────────────────────────────
# JWT — Create Tokens
# ─────────────────────────────────────────────

def create_access_token(data: dict, expires_delta: timedelta | None = None) -> str:
    """
    Creates a short-lived access token.
    Payload includes: sub (identifier), role, clinic_id, token_type=access
    """
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + (expires_delta or timedelta(minutes=15))
    to_encode.update({"exp": expire, "token_type": "access"})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


def create_refresh_access_token(data: dict) -> str:
    """
    Creates a long-lived refresh token (7 days).
    Payload includes: sub, role, clinic_id, token_type=refresh
    """
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + timedelta(days=7)
    to_encode.update({"exp": expire, "token_type": "refresh"})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


# ─────────────────────────────────────────────
# JWT — Verify Refresh Token
# ─────────────────────────────────────────────

def verify_token(token: str, credentials_exception: HTTPException) -> TokenData:
    """
    Decodes and validates a refresh token.
    Raises credentials_exception if token is invalid, expired, or wrong type.
    """
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])

        username: str = payload.get("sub")
        role: str     = payload.get("role")
        clinic_id: str = payload.get("clinic_id")
        token_type: str = payload.get("token_type")

        if token_type != "refresh":
            raise credentials_exception
        if username is None:
            raise credentials_exception

        return TokenData(username=username, role=role, clinic_id=clinic_id)

    except InvalidTokenError:
        raise credentials_exception


# ─────────────────────────────────────────────
# Get Current User (from access token)
# ─────────────────────────────────────────────
async def get_current_user(
    token: Annotated[str, Depends(oauth2_scheme)],
    db: db_depends
) -> models.User:
    """
    Decodes the access token, validates the clinic membership,
    and returns the User object enriched with current clinic context.
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials.",
        headers={"WWW-Authenticate": "Bearer"},
    )

    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])

        identifier: str = payload.get("sub")
        token_role: str = payload.get("role")
        clinic_public_id: str = payload.get("clinic_id")
        token_type: str = payload.get("token_type")

        if token_type != "access":
            raise credentials_exception
        if identifier is None or clinic_public_id is None or token_role is None:
            raise credentials_exception

    except InvalidTokenError:
        raise credentials_exception

    user = db.query(models.User).filter(
        (models.User.email == identifier) | (models.User.phone_number == identifier)
    ).one_or_none()

    if user is None:
        raise credentials_exception

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Your account is not active."
        )

    clinic, membership = get_clinic_and_membership(db, user.id, clinic_public_id)

    if clinic is None or membership is None:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This account is not linked to the selected clinic."
        )

    if not membership.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Your clinic access is not active."
        )

    if membership.role.value != token_role:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Token role does not match clinic membership."
        )

    # Attach current clinic context to the ORM user object
    setattr(user, "current_membership", membership)
    setattr(user, "current_role", membership.role)
    setattr(user, "current_clinic_id", membership.clinic_id)
    setattr(user, "current_clinic_code", clinic.clinic_id)
    setattr(user, "current_clinic", clinic)

    return user


# ─────────────────────────────────────────────
# Role-Based Guards
# ─────────────────────────────────────────────

async def require_manager(
    current_user: Annotated[models.User, Depends(get_current_user)]
) -> models.User:
    if current_user.current_role != models.UserRole.clinic_manager:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access restricted to clinic managers."
        )
    return current_user

async def require_doctor(
    current_user: Annotated[models.User, Depends(get_current_user)]
) -> models.User:
    if current_user.current_role != models.UserRole.doctor:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access restricted to doctors."
        )
    return current_user


async def require_patient(
    current_user: Annotated[models.User, Depends(get_current_user)]
) -> models.User:
    if current_user.current_role != models.UserRole.patient:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access restricted to patients."
        )
    return current_user


async def require_doctor_or_manager(
    current_user: Annotated[models.User, Depends(get_current_user)]
) -> models.User:
    if current_user.current_role not in (
        models.UserRole.doctor,
        models.UserRole.clinic_manager,
    ):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access restricted to doctors and managers."
        )
    return current_user


# ─────────────────────────────────────────────
# Clinic Isolation Guard
# ─────────────────────────────────────────────

def verify_same_clinic(current_user: models.User, target_clinic_id) -> None:
    """
    Raises 403 if the current token clinic does not match the target clinic.
    """
    if str(current_user.current_clinic_id) != str(target_clinic_id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You do not have access to this clinic's data."
        )

def get_current_patient_profile(db: Session, current_user: models.User):
    return db.query(models.PatientProfile).filter(
        models.PatientProfile.user_id == current_user.id,
        models.PatientProfile.clinic_id == current_user.current_clinic_id,
    ).first()


def get_current_doctor_profile(db: Session, current_user: models.User):
    return db.query(models.DoctorProfile).filter(
        models.DoctorProfile.user_id == current_user.id,
        models.DoctorProfile.clinic_id == current_user.current_clinic_id,
    ).first()