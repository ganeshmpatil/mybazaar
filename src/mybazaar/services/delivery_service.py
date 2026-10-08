from datetime import datetime

from sqlalchemy.orm import Session, joinedload

from ..models.delivery import Delivery, DeliveryBoy
from ..models.cod_collection import CodCollection
from ..models.order import Order, OrderStatusHistory


def assign_delivery(db: Session, order_id: int, delivery_boy_id: int) -> Delivery:
    delivery = Delivery(order_id=order_id, delivery_boy_id=delivery_boy_id)
    db.add(delivery)

    order = db.query(Order).filter(Order.id == order_id).first()
    if order:
        order.status = "OUT_FOR_DELIVERY"
        db.add(OrderStatusHistory(order_id=order_id, status="OUT_FOR_DELIVERY", created_by="ADMIN"))

    db.commit()
    db.refresh(delivery)
    return delivery


def update_delivery_status(db: Session, order_id: int, status: str, delivery_boy_id: int) -> Delivery:
    delivery = db.query(Delivery).filter(
        Delivery.order_id == order_id,
        Delivery.delivery_boy_id == delivery_boy_id,
    ).first()

    if not delivery:
        raise ValueError("Delivery assignment not found")

    delivery.status = status

    if status == "PICKED_UP":
        delivery.picked_up_at = datetime.utcnow()
    elif status == "DELIVERED":
        delivery.delivered_at = datetime.utcnow()
        # Update order status
        order = db.query(Order).filter(Order.id == order_id).first()
        if order:
            order.status = "DELIVERED"
            db.add(OrderStatusHistory(order_id=order_id, status="DELIVERED", created_by="DELIVERY_BOY"))
        # Update COD collection
        cod = db.query(CodCollection).filter(CodCollection.order_id == order_id).first()
        if cod:
            cod.status = "COLLECTED"
            cod.collected_by = delivery_boy_id
            cod.collected_at = datetime.utcnow()

    db.commit()
    db.refresh(delivery)
    return delivery


def get_delivery_boy_orders(db: Session, delivery_boy_id: int):
    return (
        db.query(Delivery)
        .options(joinedload(Delivery.order))
        .filter(Delivery.delivery_boy_id == delivery_boy_id)
        .filter(Delivery.status.in_(["ASSIGNED", "PICKED_UP", "IN_TRANSIT"]))
        .all()
    )
