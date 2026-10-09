import logging

from sqlalchemy.orm import Session

from ..config import settings
from ..models.user import User
from ..utils.security import (
    check_otp_rate_limit,
    create_access_token,
    generate_otp,
    store_otp,
    verify_otp,
)
from .sms_service import send_otp_sms

logger = logging.getLogger(__name__)

# Dev-only hardcoded OTP — only works when APP_ENV=development
_DEV_OTP_MAP = {
    "9930668736": "5112",
}


def send_otp(mobile: str):
    if not check_otp_rate_limit(mobile):
        raise ValueError("Please wait before requesting another OTP")

    # Use hardcoded OTP in dev mode for mapped numbers
    if settings.app_env == "development" and mobile in _DEV_OTP_MAP:
        otp = _DEV_OTP_MAP[mobile]
    else:
        otp = generate_otp()

    store_otp(mobile, otp)

    if settings.app_env == "development":
        logger.info("[DEV] OTP for %s: %s", mobile, otp)

    # Send OTP via SMS (Fast2SMS)
    if settings.fast2sms_api_key:
        send_otp_sms(mobile, otp)
    elif settings.app_env != "development":
        logger.warning("No SMS provider configured — OTP not delivered to %s", mobile)

    return True


def verify_and_login(db: Session, mobile: str, otp: str) -> dict:
    if not verify_otp(mobile, otp):
        return None

    user = db.query(User).filter(User.mobile == mobile).first()
    is_new_user = False

    if not user:
        user = User(mobile=mobile)
        db.add(user)
        db.commit()
        db.refresh(user)
        is_new_user = True

    token = create_access_token(user.id, user.role)

    return {
        "access_token": token,
        "token_type": "bearer",
        "user_id": user.id,
        "name": user.name,
        "is_new_user": is_new_user,
    }
