from datetime import datetime

from geoalchemy2 import Geography
from sqlalchemy import BigInteger, Boolean, DateTime, ForeignKey, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..database import Base


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    mobile: Mapped[str] = mapped_column(String(15), unique=True, nullable=False)
    name: Mapped[str | None] = mapped_column(String(100))
    email: Mapped[str | None] = mapped_column(String(255))
    role: Mapped[str] = mapped_column(String(20), default="customer")  # customer, admin, delivery_boy
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow, onupdate=datetime.utcnow)

    addresses: Mapped[list["Address"]] = relationship(back_populates="user")
    orders: Mapped[list] = relationship("Order", back_populates="user")
    cart_items: Mapped[list] = relationship("CartItem", back_populates="user")


class Address(Base):
    __tablename__ = "addresses"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("users.id"), nullable=False)
    label: Mapped[str | None] = mapped_column(String(50))
    full_address: Mapped[str] = mapped_column(Text, nullable=False)
    pincode: Mapped[str | None] = mapped_column(String(10))
    city: Mapped[str | None] = mapped_column(String(100))
    location = mapped_column(Geography(geometry_type="POINT", srid=4326), nullable=True)
    is_default: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)

    user: Mapped["User"] = relationship(back_populates="addresses")
