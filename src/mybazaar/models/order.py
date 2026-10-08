from datetime import datetime
from decimal import Decimal

from sqlalchemy import BigInteger, DateTime, ForeignKey, Numeric, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..database import Base


class Order(Base):
    __tablename__ = "orders"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    order_number: Mapped[str] = mapped_column(String(20), unique=True, nullable=False)
    user_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("users.id"), nullable=False)
    address_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("addresses.id"), nullable=False)
    status: Mapped[str] = mapped_column(String(30), default="PLACED", nullable=False)
    subtotal: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    delivery_charge: Mapped[Decimal] = mapped_column(Numeric(10, 2), default=0)
    discount: Mapped[Decimal] = mapped_column(Numeric(10, 2), default=0)
    gst_amount: Mapped[Decimal] = mapped_column(Numeric(10, 2), default=0)
    total: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    payment_mode: Mapped[str] = mapped_column(String(20), default="COD", nullable=False)
    delivery_slot: Mapped[str | None] = mapped_column(String(30))
    notes: Mapped[str | None] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow, onupdate=datetime.utcnow)

    user: Mapped["User"] = relationship("User", back_populates="orders")
    items: Mapped[list["OrderItem"]] = relationship(back_populates="order", cascade="all, delete-orphan")
    status_history: Mapped[list["OrderStatusHistory"]] = relationship(back_populates="order", cascade="all, delete-orphan")
    delivery: Mapped["Delivery | None"] = relationship("Delivery", back_populates="order", uselist=False)
    cod_collection: Mapped["CodCollection | None"] = relationship("CodCollection", back_populates="order", uselist=False)


class OrderItem(Base):
    __tablename__ = "order_items"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    order_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("orders.id"), nullable=False)
    product_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("products.id"), nullable=False)
    product_name: Mapped[str] = mapped_column(String(255), nullable=False)
    quantity: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    unit_price: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    cost_price: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    total_price: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)

    order: Mapped["Order"] = relationship(back_populates="items")


class OrderStatusHistory(Base):
    __tablename__ = "order_status_history"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    order_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("orders.id"), nullable=False)
    status: Mapped[str] = mapped_column(String(30), nullable=False)
    notes: Mapped[str | None] = mapped_column(Text)
    created_by: Mapped[str | None] = mapped_column(String(50))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)

    order: Mapped["Order"] = relationship(back_populates="status_history")


class Return(Base):
    __tablename__ = "returns"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    order_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("orders.id"), nullable=False)
    reason: Mapped[str] = mapped_column(Text, nullable=False)
    status: Mapped[str] = mapped_column(String(20), default="REQUESTED")
    refund_amount: Mapped[Decimal | None] = mapped_column(Numeric(10, 2))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow, onupdate=datetime.utcnow)

    order: Mapped["Order"] = relationship("Order")


from .user import User  # noqa: E402, F811
from .delivery import Delivery  # noqa: E402, F811
from .cod_collection import CodCollection  # noqa: E402, F811
