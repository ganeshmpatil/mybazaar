import logging
import random
from datetime import datetime, timedelta

import jwt
import redis

from ..config import settings

logger = logging.getLogger(__name__)

redis_client = redis.from_url(settings.redis_url, decode_responses=True)

_jwt_secret = settings.get_jwt_secret()


def generate_otp() -> str:
    return "".join([str(random.randint(0, 9)) for _ in range(settings.otp_length)])


def check_otp_rate_limit(mobile: str) -> bool:
    """Returns True if OTP can be sent, False if rate limited."""
    key = f"otp_cooldown:{mobile}"
    if redis_client.exists(key):
        return False
    redis_client.setex(key, settings.otp_rate_limit_seconds, "1")
    return True


def store_otp(mobile: str, otp: str):
    key = f"otp:{mobile}"
    redis_client.setex(key, settings.otp_expire_seconds, otp)
    # Reset attempt counter
    redis_client.delete(f"otp_attempts:{mobile}")


def verify_otp(mobile: str, otp: str) -> bool:
    attempts_key = f"otp_attempts:{mobile}"
    attempts = int(redis_client.get(attempts_key) or 0)

    if attempts >= settings.otp_max_attempts:
        logger.warning("OTP max attempts exceeded for %s", mobile)
        return False

    key = f"otp:{mobile}"
    stored_otp = redis_client.get(key)
    if stored_otp and stored_otp == otp:
        redis_client.delete(key)
        redis_client.delete(attempts_key)
        return True

    # Increment failed attempt counter
    redis_client.incr(attempts_key)
    redis_client.expire(attempts_key, settings.otp_expire_seconds)
    return False


def create_access_token(user_id: int, role: str) -> str:
    expire = datetime.utcnow() + timedelta(minutes=settings.jwt_access_token_expire_minutes)
    payload = {
        "sub": str(user_id),
        "role": role,
        "exp": expire,
    }
    return jwt.encode(payload, _jwt_secret, algorithm=settings.jwt_algorithm)


def decode_access_token(token: str) -> dict | None:
    try:
        payload = jwt.decode(token, _jwt_secret, algorithms=[settings.jwt_algorithm])
        return payload
    except jwt.PyJWTError:
        return None
