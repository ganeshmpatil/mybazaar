from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from ...database import get_db
from ...middleware.auth import require_admin
from ...models.user import User
from ...schemas.order import StockResponse, StockUpdateRequest
from ...services import stock_service

router = APIRouter()


@router.get("", response_model=list[StockResponse])
def list_stock(
    low_stock_only: bool = Query(False),
    user: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    stocks = stock_service.get_all_stock(db, low_stock_only)
    return [
        {
            "product_id": s.product_id,
            "product_name": s.product.name,
            "quantity": s.quantity,
            "low_stock_threshold": s.low_stock_threshold,
            "is_low_stock": s.quantity <= s.low_stock_threshold,
        }
        for s in stocks
    ]


@router.put("/{product_id}", response_model=StockResponse)
def update_stock(product_id: int, data: StockUpdateRequest,
                 user: User = Depends(require_admin), db: Session = Depends(get_db)):
    try:
        stock = stock_service.update_stock(db, product_id, data.quantity, data.reason)
        return {
            "product_id": stock.product_id,
            "product_name": stock.product.name,
            "quantity": stock.quantity,
            "low_stock_threshold": stock.low_stock_threshold,
            "is_low_stock": stock.quantity <= stock.low_stock_threshold,
        }
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
