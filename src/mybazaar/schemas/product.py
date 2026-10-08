from decimal import Decimal

from pydantic import BaseModel, Field


class CategoryCreate(BaseModel):
    name: str = Field(..., max_length=100)
    parent_id: int | None = None
    image_url: str | None = None
    sort_order: int = 0


class CategoryResponse(BaseModel):
    id: int
    name: str
    parent_id: int | None
    image_url: str | None
    sort_order: int
    is_active: bool
    subcategories: list["CategoryResponse"] = []

    class Config:
        from_attributes = True


class ProductCreate(BaseModel):
    name: str = Field(..., max_length=255)
    description: str | None = None
    category_id: int | None = None
    mrp: Decimal = Field(..., gt=0)
    selling_price: Decimal = Field(..., gt=0)
    cost_price: Decimal = Field(..., gt=0)
    unit: str | None = None
    attributes: dict | None = None
    hsn_code: str | None = None
    gst_percent: Decimal = Decimal("0")
    initial_stock: Decimal = Decimal("0")


class ProductUpdate(BaseModel):
    name: str | None = Field(None, max_length=255)
    description: str | None = None
    category_id: int | None = None
    mrp: Decimal | None = Field(None, gt=0)
    selling_price: Decimal | None = Field(None, gt=0)
    cost_price: Decimal | None = Field(None, gt=0)
    unit: str | None = None
    attributes: dict | None = None
    hsn_code: str | None = None
    gst_percent: Decimal | None = None
    is_active: bool | None = None


class ProductImageResponse(BaseModel):
    id: int
    image_url: str
    sort_order: int
    is_primary: bool

    class Config:
        from_attributes = True


class ProductResponse(BaseModel):
    id: int
    name: str
    description: str | None
    category_id: int | None
    mrp: Decimal
    selling_price: Decimal
    unit: str | None
    attributes: dict | None
    gst_percent: Decimal
    is_active: bool
    images: list[ProductImageResponse] = []
    stock_quantity: Decimal | None = None

    class Config:
        from_attributes = True


class ProductListResponse(BaseModel):
    id: int
    name: str
    selling_price: Decimal
    mrp: Decimal
    unit: str | None
    primary_image: str | None = None
    stock_quantity: Decimal | None = None
    is_active: bool

    class Config:
        from_attributes = True
