from datetime import datetime
from decimal import Decimal

from sqlalchemy import BigInteger, DateTime, ForeignKey, Numeric, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..database import Base


class CartItem(Base):
    __tablename__ = "cart_items"
    __table_args__ = (UniqueConstraint("user_id", "product_id"),)

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("users.id"), nullable=False)
    product_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("products.id"), nullable=False)
    quantity: Mapped[Decimal] = mapped_column(Numeric(10, 2), default=1, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)

    user: Mapped["User"] = relationship("User", back_populates="cart_items")
    product: Mapped["Product"] = relationship("Product")


from .user import User  # noqa: E402, F811
from .product import Product  # noqa: E402, F811
