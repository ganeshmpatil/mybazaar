from decimal import Decimal

from sqlalchemy.orm import Session, joinedload

from ..models.product import Product
from ..models.stock import Stock, StockLedger


def get_all_stock(db: Session, low_stock_only: bool = False):
    query = db.query(Stock).options(joinedload(Stock.product))

    if low_stock_only:
        query = query.filter(Stock.quantity <= Stock.low_stock_threshold)

    return query.all()


def update_stock(db: Session, product_id: int, quantity: Decimal, reason: str) -> Stock:
    stock = db.query(Stock).filter(Stock.product_id == product_id).with_for_update().first()
    if not stock:
        raise ValueError("Stock entry not found for this product")

    stock.quantity += quantity

    db.add(StockLedger(
        product_id=product_id,
        change_qty=quantity,
        reason=reason,
        balance_after=stock.quantity,
    ))

    db.commit()
    db.refresh(stock)
    return stock
