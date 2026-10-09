from datetime import datetime
from decimal import Decimal
from typing import Literal

from pydantic import BaseModel, Field


class AddressCreate(BaseModel):
    label: str | None = Field(None, max_length=50)
    full_address: str = Field(..., min_length=5, max_length=500)
    pincode: str | None = Field(None, max_length=10)
    city: str | None = Field(None, max_length=100)
    latitude: float | None = None
    longitude: float | None = None
    is_default: bool = False


class AddressResponse(BaseModel):
    id: int
    label: str | None
    full_address: str
    pincode: str | None
    city: str | None
    is_default: bool

    class Config:
        from_attributes = True


class CartItemAdd(BaseModel):
    product_id: int
    quantity: Decimal = Field(default=Decimal("1"), gt=0)


class CartItemUpdate(BaseModel):
    quantity: Decimal = Field(..., gt=0)


class CartItemResponse(BaseModel):
    id: int
    product_id: int
    product_name: str
    selling_price: Decimal
    quantity: Decimal
    subtotal: Decimal

    class Config:
        from_attributes = True


class CartResponse(BaseModel):
    items: list[CartItemResponse]
    total: Decimal
    item_count: int


class ServiceabilityCheck(BaseModel):
    address_id: int


class ServiceabilityResponse(BaseModel):
    serviceable: bool
    distance_km: float | None = None
    delivery_charge: Decimal = Decimal("0")
    message: str


class OrderCreate(BaseModel):
    address_id: int
    delivery_slot: Literal["MORNING", "AFTERNOON", "EVENING"] | None = None
    coupon_code: str | None = Field(None, max_length=50)
    notes: str | None = Field(None, max_length=500)


class OrderItemResponse(BaseModel):
    id: int
    product_name: str
    quantity: Decimal
    unit_price: Decimal
    total_price: Decimal

    class Config:
        from_attributes = True


class OrderStatusHistoryResponse(BaseModel):
    status: str
    notes: str | None
    created_by: str | None
    created_at: datetime

    class Config:
        from_attributes = True


class OrderResponse(BaseModel):
    id: int
    order_number: str
    status: str
    subtotal: Decimal
    delivery_charge: Decimal
    discount: Decimal
    gst_amount: Decimal
    total: Decimal
    payment_mode: str
    delivery_slot: str | None
    notes: str | None
    created_at: datetime
    items: list[OrderItemResponse] = []
    status_history: list[OrderStatusHistoryResponse] = []

    class Config:
        from_attributes = True


class OrderListResponse(BaseModel):
    id: int
    order_number: str
    status: str
    total: Decimal
    item_count: int
    created_at: datetime

    class Config:
        from_attributes = True


class ReturnRequest(BaseModel):
    reason: str = Field(..., min_length=5, max_length=500)


class StockUpdateRequest(BaseModel):
    quantity: Decimal
    reason: str = Field(..., max_length=50)  # PURCHASE, ADJUSTMENT


class StockResponse(BaseModel):
    product_id: int
    product_name: str
    quantity: Decimal
    low_stock_threshold: Decimal
    is_low_stock: bool

    class Config:
        from_attributes = True
