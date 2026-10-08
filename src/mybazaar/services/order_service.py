from datetime import datetime
from decimal import Decimal

from sqlalchemy.orm import Session, joinedload

from ..models.cart import CartItem
from ..models.cod_collection import CodCollection
from ..models.order import Order, OrderItem, OrderStatusHistory, Return
from ..models.product import Product
from ..models.stock import Stock, StockLedger
from ..models.user import Address


def _generate_order_number(db: Session) -> str:
    today = datetime.utcnow().strftime("%Y%m%d")
    count = db.query(Order).filter(Order.order_number.like(f"MB-{today}%")).count()
    return f"MB-{today}-{count + 1:04d}"


def check_serviceability(db: Session, address_id: int) -> dict:
    from ..utils.geo import is_within_delivery_radius

    address = db.query(Address).filter(Address.id == address_id).first()
    if not address or not address.location:
        return {
            "serviceable": False,
            "distance_km": None,
            "delivery_charge": Decimal("0"),
            "message": "Address not found or location not set",
        }

    from geoalchemy2.shape import to_shape
    point = to_shape(address.location)
    serviceable, distance_km = is_within_delivery_radius(db, point.y, point.x)

    delivery_charge = Decimal("0") if serviceable else Decimal("0")
    # TODO: calculate delivery charge based on store_config

    return {
        "serviceable": serviceable,
        "distance_km": distance_km,
        "delivery_charge": delivery_charge,
        "message": "Delivery available" if serviceable else f"Outside delivery area ({distance_km} km away)",
    }


def create_order(db: Session, user_id: int, address_id: int,
                 delivery_slot: str | None = None, coupon_code: str | None = None,
                 notes: str | None = None) -> Order:
    cart_items = (
        db.query(CartItem)
        .options(joinedload(CartItem.product))
        .filter(CartItem.user_id == user_id)
        .all()
    )

    if not cart_items:
        raise ValueError("Cart is empty")

    # Build order items and calculate totals
    order_items = []
    subtotal = Decimal("0")
    gst_amount = Decimal("0")

    for item in cart_items:
        product = item.product
        if not product.is_active:
            raise ValueError(f"Product '{product.name}' is no longer available")

        # Check stock
        stock = db.query(Stock).filter(Stock.product_id == product.id).first()
        if stock and stock.quantity < item.quantity:
            raise ValueError(f"Insufficient stock for '{product.name}' (available: {stock.quantity})")

        item_total = product.selling_price * item.quantity
        item_gst = item_total * product.gst_percent / Decimal("100")

        order_items.append(OrderItem(
            product_id=product.id,
            product_name=product.name,
            quantity=item.quantity,
            unit_price=product.selling_price,
            cost_price=product.cost_price,
            total_price=item_total,
        ))

        subtotal += item_total
        gst_amount += item_gst

    # TODO: apply coupon discount
    discount = Decimal("0")
    delivery_charge = Decimal("0")  # TODO: from store_config
    total = subtotal + gst_amount + delivery_charge - discount

    order = Order(
        order_number=_generate_order_number(db),
        user_id=user_id,
        address_id=address_id,
        subtotal=subtotal,
        delivery_charge=delivery_charge,
        discount=discount,
        gst_amount=gst_amount,
        total=total,
        payment_mode="COD",
        delivery_slot=delivery_slot,
        notes=notes,
    )
    db.add(order)
    db.flush()

    for oi in order_items:
        oi.order_id = order.id
        db.add(oi)

    # Add status history
    db.add(OrderStatusHistory(order_id=order.id, status="PLACED", created_by="SYSTEM"))

    # Create COD collection entry
    db.add(CodCollection(order_id=order.id, amount=total))

    # Deduct stock
    for item in cart_items:
        stock = db.query(Stock).filter(Stock.product_id == item.product_id).with_for_update().first()
        if stock:
            stock.quantity -= item.quantity
            db.add(StockLedger(
                product_id=item.product_id,
                change_qty=-item.quantity,
                reason="SALE",
                reference_id=order.id,
                balance_after=stock.quantity,
            ))

    # Clear cart
    db.query(CartItem).filter(CartItem.user_id == user_id).delete()

    db.commit()
    db.refresh(order)
    return order


def get_user_orders(db: Session, user_id: int, page: int = 1, page_size: int = 20):
    query = db.query(Order).filter(Order.user_id == user_id).order_by(Order.created_at.desc())
    total = query.count()
    orders = query.offset((page - 1) * page_size).limit(page_size).all()
    return orders, total


def get_order_detail(db: Session, order_id: int, user_id: int | None = None) -> Order | None:
    query = (
        db.query(Order)
        .options(joinedload(Order.items), joinedload(Order.status_history))
        .filter(Order.id == order_id)
    )
    if user_id:
        query = query.filter(Order.user_id == user_id)
    return query.first()


def cancel_order(db: Session, order_id: int, user_id: int) -> Order:
    order = db.query(Order).filter(Order.id == order_id, Order.user_id == user_id).first()
    if not order:
        raise ValueError("Order not found")
    if order.status != "PLACED":
        raise ValueError("Only orders in PLACED status can be cancelled")

    order.status = "CANCELLED"
    db.add(OrderStatusHistory(order_id=order.id, status="CANCELLED", created_by="CUSTOMER"))

    # Restore stock
    for item in db.query(OrderItem).filter(OrderItem.order_id == order.id).all():
        stock = db.query(Stock).filter(Stock.product_id == item.product_id).with_for_update().first()
        if stock:
            stock.quantity += item.quantity
            db.add(StockLedger(
                product_id=item.product_id,
                change_qty=item.quantity,
                reason="CANCELLATION",
                reference_id=order.id,
                balance_after=stock.quantity,
            ))

    # Update COD collection
    cod = db.query(CodCollection).filter(CodCollection.order_id == order.id).first()
    if cod:
        cod.status = "CANCELLED"

    db.commit()
    db.refresh(order)
    return order


def request_return(db: Session, order_id: int, user_id: int, reason: str) -> Return:
    order = db.query(Order).filter(Order.id == order_id, Order.user_id == user_id).first()
    if not order:
        raise ValueError("Order not found")
    if order.status != "DELIVERED":
        raise ValueError("Only delivered orders can be returned")

    return_req = Return(order_id=order.id, reason=reason, refund_amount=order.total)
    db.add(return_req)

    order.status = "RETURN_REQUESTED"
    db.add(OrderStatusHistory(order_id=order.id, status="RETURN_REQUESTED", created_by="CUSTOMER"))

    db.commit()
    db.refresh(return_req)
    return return_req


def update_order_status(db: Session, order_id: int, status: str,
                        delivery_boy_id: int | None = None, updated_by: str = "ADMIN") -> Order:
    order = db.query(Order).filter(Order.id == order_id).first()
    if not order:
        raise ValueError("Order not found")

    order.status = status
    db.add(OrderStatusHistory(order_id=order.id, status=status, created_by=updated_by))

    db.commit()
    db.refresh(order)
    return order
