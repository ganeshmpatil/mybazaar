import logging
import secrets

from pydantic_settings import BaseSettings

logger = logging.getLogger(__name__)


def _generate_secret() -> str:
    """Generate a random secret key. In production, always set JWT_SECRET_KEY env var."""
    secret = secrets.token_urlsafe(32)
    logger.warning("JWT_SECRET_KEY not set — using auto-generated key. Tokens will invalidate on restart.")
    return secret


class Settings(BaseSettings):
    # Database
    database_url: str = "postgresql://mybazaar:mybazaar_dev@localhost:5432/mybazaar"

    # Redis
    redis_url: str = "redis://localhost:6379/0"

    # JWT
    jwt_secret_key: str = ""
    jwt_algorithm: str = "HS256"
    jwt_access_token_expire_minutes: int = 1440  # 24 hours

    # OTP
    otp_expire_seconds: int = 300  # 5 minutes
    otp_length: int = 4
    otp_max_attempts: int = 5  # Max wrong OTP attempts before lockout
    otp_rate_limit_seconds: int = 60  # Min seconds between OTP requests

    # SMS Gateway (Fast2SMS — https://www.fast2sms.com)
    # Sign up free → Dashboard → API Keys → copy key
    sms_provider: str = "fast2sms"  # fast2sms | disabled
    fast2sms_api_key: str = ""

    # Store
    store_name: str = "MyBazaar"
    store_lat: float = 21.0191
    store_lng: float = 75.3575
    delivery_radius_km: int = 20

    # MinIO / S3 (local dev)
    s3_endpoint: str = "http://localhost:9000"
    s3_access_key: str = ""
    s3_secret_key: str = ""
    s3_bucket: str = "mybazaar-images"

    # Cloudinary (production)
    cloudinary_cloud_name: str = ""
    cloudinary_api_key: str = ""
    cloudinary_api_secret: str = ""

    # CORS
    allowed_origins: str = ""  # Comma-separated origins, e.g. "https://mybazaar.com,http://localhost:3000"

    # App
    app_env: str = "development"
    app_debug: bool = False

    # Render port
    port: int = 8000

    class Config:
        env_file = ".env"
        env_prefix = ""

    def get_jwt_secret(self) -> str:
        if self.jwt_secret_key:
            return self.jwt_secret_key
        return _generate_secret()

    def get_cors_origins(self) -> list[str]:
        if self.allowed_origins:
            return [o.strip() for o in self.allowed_origins.split(",") if o.strip()]
        if self.app_env == "development":
            return ["*"]
        return []


settings = Settings()
