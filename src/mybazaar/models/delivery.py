from datetime import datetime

from geoalchemy2 import Geography
from sqlalchemy import BigInteger, Boolean, DateTime, ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..database import Base


class DeliveryBoy(Base):
    __tablename__ = "delivery_boys"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    mobile: Mapped[str] = mapped_column(String(15), unique=True, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    current_location = mapped_column(Geography(geometry_type="POINT", srid=4326), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)

    deliveries: Mapped[list["Delivery"]] = relationship(back_populates="delivery_boy")


class Delivery(Base):
    __tablename__ = "deliveries"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    order_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("orders.id"), unique=True, nullable=False)
    delivery_boy_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("delivery_boys.id"), nullable=False)
    status: Mapped[str] = mapped_column(String(20), default="ASSIGNED")
    assigned_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)
    picked_up_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    delivered_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    order: Mapped["Order"] = relationship("Order", back_populates="delivery")
    delivery_boy: Mapped["DeliveryBoy"] = relationship(back_populates="deliveries")


from .order import Order  # noqa: E402, F811
