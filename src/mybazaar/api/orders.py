from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from ..database import get_db
from ..middleware.auth import get_current_user
from ..models.user import User
from ..schemas.order import (
    OrderCreate,
    OrderResponse,
    ReturnRequest,
    ServiceabilityCheck,
    ServiceabilityResponse,
)
from ..services import order_service

router = APIRouter()


@router.post("/check-serviceability", response_model=ServiceabilityResponse)
def check_serviceability(data: ServiceabilityCheck,
                         user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    return order_service.check_serviceability(db, data.address_id)


@router.post("", response_model=OrderResponse, status_code=status.HTTP_201_CREATED)
def create_order(data: OrderCreate, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    try:
        order = order_service.create_order(
            db, user.id, data.address_id, data.delivery_slot, data.coupon_code, data.notes
        )
        return order_service.get_order_detail(db, order.id)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


@router.get("", response_model=dict)
def list_orders(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    orders, total = order_service.get_user_orders(db, user.id, page, page_size)
    items = []
    for o in orders:
        items.append({
            "id": o.id,
            "order_number": o.order_number,
            "status": o.status,
            "total": o.total,
            "item_count": len(o.items) if o.items else 0,
            "created_at": o.created_at,
        })
    return {
        "items": items,
        "total": total,
        "page": page,
        "page_size": page_size,
    }


@router.get("/{order_id}", response_model=OrderResponse)
def get_order(order_id: int, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    order = order_service.get_order_detail(db, order_id, user.id)
    if not order:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")
    return order


@router.post("/{order_id}/cancel")
def cancel_order(order_id: int, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    try:
        order_service.cancel_order(db, order_id, user.id)
        return {"message": "Order cancelled"}
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


@router.post("/{order_id}/return")
def return_order(order_id: int, data: ReturnRequest,
                 user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    try:
        order_service.request_return(db, order_id, user.id, data.reason)
        return {"message": "Return request submitted"}
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
