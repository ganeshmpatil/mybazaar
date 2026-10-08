from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # Database
    database_url: str = "postgresql://mybazaar:mybazaar_dev@localhost:5432/mybazaar"

    # Redis
    redis_url: str = "redis://localhost:6379/0"

    # JWT
    jwt_secret_key: str = "change-this-to-a-random-secret-key"
    jwt_algorithm: str = "HS256"
    jwt_access_token_expire_minutes: int = 1440  # 24 hours

    # OTP
    otp_expire_seconds: int = 300  # 5 minutes
    otp_length: int = 4

    # SMS Gateway
    sms_api_key: str = ""
    sms_sender_id: str = "MYBZAR"
    sms_template_id: str = ""

    # Store
    store_name: str = "MyBazaar"
    store_lat: float = 19.876
    store_lng: float = 75.343
    delivery_radius_km: int = 20

    # MinIO / S3
    s3_endpoint: str = "http://localhost:9000"
    s3_access_key: str = "minioadmin"
    s3_secret_key: str = "minioadmin"
    s3_bucket: str = "mybazaar-images"

    # App
    app_env: str = "development"
    app_debug: bool = True

    class Config:
        env_file = ".env"


settings = Settings()
