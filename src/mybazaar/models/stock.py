from datetime import datetime
from decimal import Decimal

from sqlalchemy import BigInteger, DateTime, ForeignKey, Numeric, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..database import Base


class Stock(Base):
    __tablename__ = "stock"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    product_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("products.id"), unique=True, nullable=False)
    quantity: Mapped[Decimal] = mapped_column(Numeric(10, 2), default=0, nullable=False)
    low_stock_threshold: Mapped[Decimal] = mapped_column(Numeric(10, 2), default=5)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow, onupdate=datetime.utcnow)

    product: Mapped["Product"] = relationship("Product", back_populates="stock")


class StockLedger(Base):
    __tablename__ = "stock_ledger"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    product_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("products.id"), nullable=False)
    change_qty: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    reason: Mapped[str] = mapped_column(String(50), nullable=False)  # PURCHASE, SALE, RETURN, ADJUSTMENT
    reference_id: Mapped[int | None] = mapped_column(BigInteger)
    balance_after: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)


from .product import Product  # noqa: E402, F811
