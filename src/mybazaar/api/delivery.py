from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.orm import Session

from ..database import get_db
from ..middleware.auth import get_current_user, require_delivery_boy
from ..models.delivery import DeliveryBoy
from ..models.user import User
from ..services import delivery_service

router = APIRouter()


class DeliveryStatusUpdate(BaseModel):
    status: str  # PICKED_UP, IN_TRANSIT, DELIVERED, FAILED


@router.get("/my-orders")
def get_my_deliveries(user: User = Depends(require_delivery_boy), db: Session = Depends(get_db)):
    delivery_boy = db.query(DeliveryBoy).filter(DeliveryBoy.mobile == user.mobile).first()
    if not delivery_boy:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Delivery boy profile not found")

    deliveries = delivery_service.get_delivery_boy_orders(db, delivery_boy.id)
    return [
        {
            "delivery_id": d.id,
            "order_id": d.order_id,
            "order_number": d.order.order_number,
            "status": d.status,
            "total": d.order.total,
            "assigned_at": d.assigned_at,
        }
        for d in deliveries
    ]


@router.put("/orders/{order_id}/status")
def update_status(order_id: int, data: DeliveryStatusUpdate,
                  user: User = Depends(require_delivery_boy), db: Session = Depends(get_db)):
    delivery_boy = db.query(DeliveryBoy).filter(DeliveryBoy.mobile == user.mobile).first()
    if not delivery_boy:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Delivery boy profile not found")

    try:
        delivery_service.update_delivery_status(db, order_id, data.status, delivery_boy.id)
        return {"message": f"Delivery status updated to {data.status}"}
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
