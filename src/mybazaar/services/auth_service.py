from sqlalchemy.orm import Session

from ..config import settings
from ..models.user import User
from ..utils.security import create_access_token, generate_otp, store_otp, verify_otp


def send_otp(mobile: str):
    otp = generate_otp()
    store_otp(mobile, otp)

    if settings.app_env == "development":
        print(f"[DEV] OTP for {mobile}: {otp}")
    else:
        # TODO: integrate SMS gateway (MSG91)
        pass

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
