from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from ..database import get_db
from ..middleware.auth import get_current_user
from ..models.user import Address, User
from ..schemas.auth import (
    ProfileResponse,
    ProfileUpdate,
    SendOtpRequest,
    TokenResponse,
    VerifyOtpRequest,
)
from ..schemas.order import AddressCreate, AddressResponse
from ..services import auth_service

router = APIRouter()


@router.post("/send-otp")
def send_otp(request: SendOtpRequest):
    try:
        auth_service.send_otp(request.mobile)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_429_TOO_MANY_REQUESTS, detail=str(e))
    return {"message": "OTP sent successfully"}


@router.post("/verify-otp", response_model=TokenResponse)
def verify_otp(request: VerifyOtpRequest, db: Session = Depends(get_db)):
    result = auth_service.verify_and_login(db, request.mobile, request.otp)
    if result is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid or expired OTP")
    return result


@router.get("/profile", response_model=ProfileResponse)
def get_profile(user: User = Depends(get_current_user)):
    return user


@router.put("/profile", response_model=ProfileResponse)
def update_profile(data: ProfileUpdate, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    if data.name is not None:
        user.name = data.name
    if data.email is not None:
        user.email = data.email
    db.commit()
    db.refresh(user)
    return user


@router.get("/addresses", response_model=list[AddressResponse])
def get_addresses(user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    return db.query(Address).filter(Address.user_id == user.id).all()


@router.delete("/addresses/{address_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_address(address_id: int, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    address = db.query(Address).filter(Address.id == address_id, Address.user_id == user.id).first()
    if not address:
        raise HTTPException(status_code=404, detail="Address not found")
    db.delete(address)
    db.commit()


@router.put("/addresses/{address_id}", response_model=AddressResponse)
def update_address(address_id: int, data: AddressCreate, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    address = db.query(Address).filter(Address.id == address_id, Address.user_id == user.id).first()
    if not address:
        raise HTTPException(status_code=404, detail="Address not found")
    address.label = data.label
    address.full_address = data.full_address
    address.pincode = data.pincode
    address.city = data.city
    address.is_default = data.is_default
    if data.is_default:
        db.query(Address).filter(Address.user_id == user.id, Address.id != address_id).update({"is_default": False})
    db.commit()
    db.refresh(address)
    return address


@router.post("/addresses", response_model=AddressResponse, status_code=status.HTTP_201_CREATED)
def add_address(data: AddressCreate, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    address = Address(
        user_id=user.id,
        label=data.label,
        full_address=data.full_address,
        pincode=data.pincode,
        city=data.city,
        is_default=data.is_default,
    )

    if data.latitude and data.longitude:
        from geoalchemy2.elements import WKTElement
        address.location = WKTElement(f"POINT({data.longitude} {data.latitude})", srid=4326)

    if data.is_default:
        db.query(Address).filter(Address.user_id == user.id).update({"is_default": False})

    db.add(address)
    db.commit()
    db.refresh(address)
    return address
