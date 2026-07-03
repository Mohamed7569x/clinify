"""
NOTIFICATION SERVICE — DB + FCM Push

Setup checklist:
  1. pip install firebase-admin --break-system-packages
  2. Download service account JSON from Firebase Console:
     → Project Settings → Service Accounts → Generate New Private Key
  3. Set env: FIREBASE_CREDENTIALS_PATH=/path/to/serviceAccountKey.json
  4. Add fcm_token column to User model:
     fcm_token = Column(String, nullable=True)
  5. Run migration: alembic revision --autogenerate -m "add fcm_token"
                    alembic upgrade head
  6. Register the users.py router (PUT /api/v1/users/fcm-token)
"""
from dotenv import load_dotenv

import os
import logging
from sqlalchemy.orm import Session
from app.schemas import models
from app.schemas.models import NotificationType

logger = logging.getLogger("clinify.notifications")

# ─────────────────────────────────────────────
# Firebase Admin SDK Init
# ─────────────────────────────────────────────

_firebase_ok = False

try:
    import firebase_admin
    from firebase_admin import credentials, messaging
    load_dotenv()

    cred_path = 'D:/Night Hunter/Clinify API/app/clinify-c1bc8-firebase-adminsdk-fbsvc-6629e09b1f.json'
    print(cred_path)

    if not cred_path:
        logger.warning("⚠️  FIREBASE_CREDENTIALS_PATH env var not set — push disabled")
    elif not os.path.exists(cred_path):
        logger.warning(f"⚠️  Firebase credentials file not found: {cred_path}")
    else:
        # Only initialize if not already done
        if not firebase_admin._apps:
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
        _firebase_ok = True
        logger.info("✅ Firebase Admin SDK initialized — push enabled")

except ImportError:
    logger.warning("⚠️  firebase-admin package not installed — run: pip install firebase-admin --break-system-packages")


# ─────────────────────────────────────────────
# FCM Push
# ─────────────────────────────────────────────

def _send_fcm(user: models.User, title: str, body: str, data: dict = None):
    """Send push notification to user's device via FCM."""
    if not _firebase_ok:
        logger.debug("FCM skipped — firebase not initialized")
        return False

    token = getattr(user, 'fcm_token', None)
    if not token:
        logger.debug(f"FCM skipped — user {user.id} has no fcm_token")
        return False

    try:
        msg = messaging.Message(
            notification=messaging.Notification(title=title, body=body),
            data={k: str(v) for k, v in (data or {}).items()},  # FCM data must be string values
            token=token,
        )
        response = messaging.send(msg)
        logger.info(f"✅ FCM sent to user {user.id}: {response}")
        return True
    except messaging.UnregisteredError:
        # Token expired — clear it
        logger.warning(f"FCM token expired for user {user.id} — clearing")
        user.fcm_token = None
        return False
    except Exception as e:
        logger.error(f"❌ FCM send failed for user {user.id}: {e}")
        return False


# ─────────────────────────────────────────────
# Core: Create DB notification + send push
# ─────────────────────────────────────────────

def _create(db: Session, user_id, ntype: NotificationType, title: str, body: str, related_id=None):
    n = models.Notification(
        user_id=user_id,
        type=ntype,
        title=title,
        body=body,
        related_id=related_id,
    )
    db.add(n)
    db.flush()

    # Send FCM push
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if user:
        data = {
            "type": ntype.value if hasattr(ntype, 'value') else str(ntype),
            "related_id": str(related_id) if related_id else "",
        }
        _send_fcm(user, title, body, data)

    return n


# ─────────────────────────────────────────────
# Appointment Notifications
# ─────────────────────────────────────────────

def notify_appointment_booked(db: Session, appt: models.Appointment):
    dp = db.query(models.DoctorProfile).filter(models.DoctorProfile.id == appt.doctor_id).first()
    if not dp:
        return
    pp = db.query(models.PatientProfile).filter(models.PatientProfile.id == appt.patient_id).first()
    pname = "مريض"
    if pp:
        pu = db.query(models.User).filter(models.User.id == pp.user_id).first()
        if pu:
            pname = pu.name
    _create(db, dp.user_id, NotificationType.APPOINTMENT_BOOKED, "موعد جديد",
            f"قام {pname} بحجز موعد بتاريخ {appt.date} الساعة {appt.start_time}", appt.id)


def notify_appointment_confirmed(db: Session, appt: models.Appointment):
    pp = db.query(models.PatientProfile).filter(models.PatientProfile.id == appt.patient_id).first()
    if not pp:
        return
    _create(db, pp.user_id, NotificationType.APPOINTMENT_CONFIRMED, "تم تأكيد موعدك",
            f"تم تأكيد موعدك بتاريخ {appt.date} الساعة {appt.start_time}", appt.id)


def notify_appointment_cancelled(db: Session, appt: models.Appointment, by: str):
    pp = db.query(models.PatientProfile).filter(models.PatientProfile.id == appt.patient_id).first()
    dp = db.query(models.DoctorProfile).filter(models.DoctorProfile.id == appt.doctor_id).first()
    if by == "patient" and dp:
        _create(db, dp.user_id, NotificationType.APPOINTMENT_CANCELLED, "تم إلغاء موعد",
                f"تم إلغاء الموعد بتاريخ {appt.date} من قبل المريض", appt.id)
    elif pp:
        _create(db, pp.user_id, NotificationType.APPOINTMENT_CANCELLED, "تم إلغاء موعدك",
                f"تم إلغاء موعدك بتاريخ {appt.date} الساعة {appt.start_time}", appt.id)


def notify_appointment_completed(db: Session, appt: models.Appointment):
    pp = db.query(models.PatientProfile).filter(models.PatientProfile.id == appt.patient_id).first()
    if not pp:
        return
    _create(db, pp.user_id, NotificationType.APPOINTMENT_CONFIRMED, "تمت الزيارة",
            f"تمت زيارتك بتاريخ {appt.date} بنجاح. يمكنك تقييم الطبيب.", appt.id)


def notify_prescription_added(db: Session, appt: models.Appointment):
    pp = db.query(models.PatientProfile).filter(models.PatientProfile.id == appt.patient_id).first()
    if not pp:
        return
    _create(db, pp.user_id, NotificationType.PRESCRIPTION_ADDED, "وصفة طبية جديدة",
            f"أضاف الطبيب وصفة طبية لموعدك بتاريخ {appt.date}", appt.id)


# ─────────────────────────────────────────────
# Registration
# ─────────────────────────────────────────────

def notify_patient_registered(db: Session, clinic_id, patient_name: str):
    docs = (
        db.query(models.User)
        .join(models.ClinicMembership, models.ClinicMembership.user_id == models.User.id)
        .filter(
            models.ClinicMembership.clinic_id == clinic_id,
            models.ClinicMembership.role == models.UserRole.doctor,
            models.ClinicMembership.is_active == True,
            models.User.is_active == True,
        )
        .all()
    )

    for d in docs:
        _create(
            db,
            d.id,
            NotificationType.GENERAL,
            "مريض جديد",
            f"سجّل مريض جديد باسم {patient_name} في العيادة",
        )


def notify_account_approved(db: Session, user_id):
    _create(db, user_id, NotificationType.ACCOUNT_APPROVED, "تم تفعيل حسابك",
            "تمت الموافقة على حسابك. يمكنك الآن تسجيل الدخول وحجز المواعيد.")