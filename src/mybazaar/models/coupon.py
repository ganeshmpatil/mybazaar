from datetime import datetime
from decimal import Decimal

from sqlalchemy import BigInteger, Boolean, DateTime, Integer, Numeric, String
from sqlalchemy.orm import Mapped, mapped_column

from ..database import Base


class Coupon(Base):
    __tablename__ = "coupons"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    code: Mapped[str] = mapped_column(String(30), unique=True, nullable=False)
    discount_type: Mapped[str] = mapped_column(String(10), nullable=False)  # PERCENT, FLAT
    discount_value: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    min_order_value: Mapped[Decimal] = mapped_column(Numeric(10, 2), default=0)
    max_discount: Mapped[Decimal | None] = mapped_column(Numeric(10, 2))
    usage_limit: Mapped[int | None] = mapped_column(Integer)
    used_count: Mapped[int] = mapped_column(Integer, default=0)
    valid_from: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    valid_till: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
