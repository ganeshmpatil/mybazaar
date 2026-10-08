from datetime import datetime
from decimal import Decimal

from sqlalchemy import BigInteger, DateTime, ForeignKey, Numeric, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..database import Base


class CodCollection(Base):
    __tablename__ = "cod_collections"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    order_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("orders.id"), nullable=False)
    amount: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    status: Mapped[str] = mapped_column(String(20), default="PENDING", nullable=False)
    collected_by: Mapped[int | None] = mapped_column(BigInteger)
    collected_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    settled_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)

    order: Mapped["Order"] = relationship("Order", back_populates="cod_collection")


from .order import Order  # noqa: E402, F811
