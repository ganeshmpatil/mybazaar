import random
from datetime import datetime, timedelta

import jwt
import redis

from ..config import settings

redis_client = redis.from_url(settings.redis_url, decode_responses=True)


def generate_otp() -> str:
    return "".join([str(random.randint(0, 9)) for _ in range(settings.otp_length)])


def store_otp(mobile: str, otp: str):
    key = f"otp:{mobile}"
    redis_client.setex(key, settings.otp_expire_seconds, otp)


def verify_otp(mobile: str, otp: str) -> bool:
    key = f"otp:{mobile}"
    stored_otp = redis_client.get(key)
    if stored_otp and stored_otp == otp:
        redis_client.delete(key)
        return True
    return False


def create_access_token(user_id: int, role: str) -> str:
    expire = datetime.utcnow() + timedelta(minutes=settings.jwt_access_token_expire_minutes)
    payload = {
        "sub": str(user_id),
        "role": role,
        "exp": expire,
    }
    return jwt.encode(payload, settings.jwt_secret_key, algorithm=settings.jwt_algorithm)


def decode_access_token(token: str) -> dict | None:
    try:
        payload = jwt.decode(token, settings.jwt_secret_key, algorithms=[settings.jwt_algorithm])
        return payload
    except jwt.PyJWTError:
        return None
