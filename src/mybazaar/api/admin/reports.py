from datetime import date, datetime, timedelta
from decimal import Decimal

from fastapi import APIRouter, Depends, Query
from sqlalchemy import func
from sqlalchemy.orm import Session

from ...database import get_db
from ...middleware.auth import require_admin
from ...models.cod_collection import CodCollection
from ...models.order import Order, OrderItem
from ...models.stock import Stock
from ...models.user import User

router = APIRouter()


@router.get("/dashboard")
def dashboard(user: User = Depends(require_admin), db: Session = Depends(get_db)):
    today = date.today()
    today_start = datetime.combine(today, datetime.min.time())

    # Today's stats
    today_orders = db.query(func.count(Order.id)).filter(Order.created_at >= today_start).scalar()
    today_revenue = (
        db.query(func.sum(Order.total))
        .filter(Order.created_at >= today_start, Order.status != "CANCELLED")
        .scalar() or Decimal("0")
    )

    # Pending orders
    pending_orders = db.query(func.count(Order.id)).filter(Order.status == "PLACED").scalar()

    # Out for delivery
    out_for_delivery = db.query(func.count(Order.id)).filter(Order.status == "OUT_FOR_DELIVERY").scalar()

    # Low stock count
    low_stock = db.query(func.count(Stock.id)).filter(Stock.quantity <= Stock.low_stock_threshold).scalar()

    # COD pending collection
    cod_pending = (
        db.query(func.sum(CodCollection.amount))
        .filter(CodCollection.status == "PENDING")
        .scalar() or Decimal("0")
    )

    return {
        "today": {
            "orders": today_orders,
            "revenue": today_revenue,
        },
        "pending_orders": pending_orders,
        "out_for_delivery": out_for_delivery,
        "low_stock_items": low_stock,
        "cod_pending_collection": cod_pending,
    }


@router.get("/pnl")
def profit_and_loss(
    from_date: date = Query(...),
    to_date: date = Query(...),
    user: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    from_dt = datetime.combine(from_date, datetime.min.time())
    to_dt = datetime.combine(to_date, datetime.max.time())

    # Revenue: total of delivered orders
    revenue = (
        db.query(func.sum(Order.total))
        .filter(Order.status == "DELIVERED", Order.created_at.between(from_dt, to_dt))
        .scalar() or Decimal("0")
    )

    delivery_charges = (
        db.query(func.sum(Order.delivery_charge))
        .filter(Order.status == "DELIVERED", Order.created_at.between(from_dt, to_dt))
        .scalar() or Decimal("0")
    )

    # Cost of goods sold
    cogs = (
        db.query(func.sum(OrderItem.cost_price * OrderItem.quantity))
        .join(Order, Order.id == OrderItem.order_id)
        .filter(Order.status == "DELIVERED", Order.created_at.between(from_dt, to_dt))
        .scalar() or Decimal("0")
    )

    # Refunds
    refunds = (
        db.query(func.sum(Order.total))
        .filter(Order.status == "RETURNED", Order.created_at.between(from_dt, to_dt))
        .scalar() or Decimal("0")
    )

    gross_profit = revenue - cogs - refunds

    # Order counts by status
    status_counts = (
        db.query(Order.status, func.count(Order.id))
        .filter(Order.created_at.between(from_dt, to_dt))
        .group_by(Order.status)
        .all()
    )

    return {
        "period": {"from": from_date.isoformat(), "to": to_date.isoformat()},
        "revenue": {
            "total_sales": revenue,
            "delivery_charges": delivery_charges,
            "refunds": refunds,
            "net_revenue": revenue - refunds,
        },
        "costs": {
            "cost_of_goods_sold": cogs,
        },
        "gross_profit": gross_profit,
        "order_summary": {s: c for s, c in status_counts},
    }


@router.get("/sales")
def sales_summary(
    from_date: date = Query(...),
    to_date: date = Query(...),
    user: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    from_dt = datetime.combine(from_date, datetime.min.time())
    to_dt = datetime.combine(to_date, datetime.max.time())

    # Top selling products
    top_products = (
        db.query(
            OrderItem.product_name,
            func.sum(OrderItem.quantity).label("total_qty"),
            func.sum(OrderItem.total_price).label("total_revenue"),
        )
        .join(Order, Order.id == OrderItem.order_id)
        .filter(Order.status == "DELIVERED", Order.created_at.between(from_dt, to_dt))
        .group_by(OrderItem.product_name)
        .order_by(func.sum(OrderItem.total_price).desc())
        .limit(10)
        .all()
    )

    return {
        "period": {"from": from_date.isoformat(), "to": to_date.isoformat()},
        "top_products": [
            {"product_name": p, "quantity_sold": q, "revenue": r}
            for p, q, r in top_products
        ],
    }
