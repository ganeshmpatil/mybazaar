from pydantic import BaseModel, Field


class SendOtpRequest(BaseModel):
    mobile: str = Field(..., min_length=10, max_length=15, pattern=r"^\d{10,15}$")


class VerifyOtpRequest(BaseModel):
    mobile: str = Field(..., min_length=10, max_length=15, pattern=r"^\d{10,15}$")
    otp: str = Field(..., min_length=4, max_length=6)


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user_id: int
    name: str | None
    is_new_user: bool


class ProfileUpdate(BaseModel):
    name: str | None = Field(None, max_length=100)
    email: str | None = Field(None, max_length=255)


class ProfileResponse(BaseModel):
    id: int
    mobile: str
    name: str | None
    email: str | None
    role: str

    class Config:
        from_attributes = True
