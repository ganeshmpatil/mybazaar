from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel
from sqlalchemy.orm import Session

from ...database import get_db
from ...middleware.auth import require_admin
from ...models.order import Order
from ...models.user import User
from ...services import delivery_service, order_service

router = APIRouter()


class OrderStatusUpdate(BaseModel):
    status: str
    delivery_boy_id: int | None = None


@router.get("")
def list_orders(
    order_status: str | None = None,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    user: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    query = db.query(Order).order_by(Order.created_at.desc())
    if order_status:
        query = query.filter(Order.status == order_status)

    total = query.count()
    orders = query.offset((page - 1) * page_size).limit(page_size).all()

    return {
        "items": [
            {
                "id": o.id,
                "order_number": o.order_number,
                "status": o.status,
                "total": o.total,
                "payment_mode": o.payment_mode,
                "created_at": o.created_at,
            }
            for o in orders
        ],
        "total": total,
        "page": page,
        "page_size": page_size,
    }


@router.get("/{order_id}")
def get_order(order_id: int, user: User = Depends(require_admin), db: Session = Depends(get_db)):
    order = order_service.get_order_detail(db, order_id)
    if not order:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")
    return order


@router.put("/{order_id}/status")
def update_order_status(order_id: int, data: OrderStatusUpdate,
                        user: User = Depends(require_admin), db: Session = Depends(get_db)):
    try:
        if data.status == "OUT_FOR_DELIVERY" and data.delivery_boy_id:
            delivery_service.assign_delivery(db, order_id, data.delivery_boy_id)
        else:
            order_service.update_order_status(db, order_id, data.status)
        return {"message": f"Order status updated to {data.status}"}
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
