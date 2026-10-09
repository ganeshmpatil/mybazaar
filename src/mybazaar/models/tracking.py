from datetime import datetime
from decimal import Decimal

from sqlalchemy import BigInteger, DateTime, ForeignKey, Numeric, String
from sqlalchemy.orm import Mapped, mapped_column

from ..database import Base


class DeliveryTracking(Base):
    __tablename__ = "delivery_tracking"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    delivery_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("deliveries.id"), nullable=False)
    order_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("orders.id"), nullable=False)
    delivery_boy_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("delivery_boys.id"), nullable=False)
    latitude: Mapped[Decimal] = mapped_column(Numeric(10, 7), nullable=False)
    longitude: Mapped[Decimal] = mapped_column(Numeric(10, 7), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)
