from datetime import datetime
from decimal import Decimal

from sqlalchemy import BigInteger, Boolean, DateTime, ForeignKey, Integer, Numeric, String, Text
from sqlalchemy.dialects.postgresql import JSONB, TSVECTOR
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..database import Base


class Category(Base):
    __tablename__ = "categories"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    parent_id: Mapped[int | None] = mapped_column(BigInteger, ForeignKey("categories.id"))
    image_url: Mapped[str | None] = mapped_column(String(500))
    sort_order: Mapped[int] = mapped_column(Integer, default=0)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    parent: Mapped["Category | None"] = relationship(remote_side="Category.id")
    products: Mapped[list["Product"]] = relationship(back_populates="category")


class Product(Base):
    __tablename__ = "products"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[str | None] = mapped_column(Text)
    category_id: Mapped[int | None] = mapped_column(BigInteger, ForeignKey("categories.id"))
    mrp: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    selling_price: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    cost_price: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    unit: Mapped[str | None] = mapped_column(String(20))
    attributes = mapped_column(JSONB, nullable=True)
    hsn_code: Mapped[str | None] = mapped_column(String(20))
    gst_percent: Mapped[Decimal] = mapped_column(Numeric(4, 2), default=0)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    search_vector = mapped_column(TSVECTOR, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow, onupdate=datetime.utcnow)

    category: Mapped["Category | None"] = relationship(back_populates="products")
    images: Mapped[list["ProductImage"]] = relationship(back_populates="product", cascade="all, delete-orphan")
    stock: Mapped["Stock | None"] = relationship("Stock", back_populates="product", uselist=False)


class ProductImage(Base):
    __tablename__ = "product_images"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    product_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("products.id", ondelete="CASCADE"), nullable=False)
    image_url: Mapped[str] = mapped_column(String(500), nullable=False)
    sort_order: Mapped[int] = mapped_column(Integer, default=0)
    is_primary: Mapped[bool] = mapped_column(Boolean, default=False)

    product: Mapped["Product"] = relationship(back_populates="images")


# Forward reference for Stock
from .stock import Stock  # noqa: E402, F811
