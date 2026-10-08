from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, joinedload

from ..database import get_db
from ..middleware.auth import get_current_user
from ..models.cart import CartItem
from ..models.product import Product
from ..models.user import User
from ..schemas.order import CartItemAdd, CartItemUpdate, CartResponse

router = APIRouter()


@router.get("", response_model=CartResponse)
def get_cart(user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    items = (
        db.query(CartItem)
        .options(joinedload(CartItem.product))
        .filter(CartItem.user_id == user.id)
        .all()
    )

    cart_items = []
    total = 0
    for item in items:
        subtotal = item.product.selling_price * item.quantity
        cart_items.append({
            "id": item.id,
            "product_id": item.product_id,
            "product_name": item.product.name,
            "selling_price": item.product.selling_price,
            "quantity": item.quantity,
            "subtotal": subtotal,
        })
        total += subtotal

    return {"items": cart_items, "total": total, "item_count": len(cart_items)}


@router.post("", status_code=status.HTTP_201_CREATED)
def add_to_cart(data: CartItemAdd, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    product = db.query(Product).filter(Product.id == data.product_id, Product.is_active == True).first()
    if not product:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")

    existing = db.query(CartItem).filter(
        CartItem.user_id == user.id, CartItem.product_id == data.product_id
    ).first()

    if existing:
        existing.quantity += data.quantity
    else:
        db.add(CartItem(user_id=user.id, product_id=data.product_id, quantity=data.quantity))

    db.commit()
    return {"message": "Added to cart"}


@router.put("/{item_id}")
def update_cart_item(item_id: int, data: CartItemUpdate,
                     user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    item = db.query(CartItem).filter(CartItem.id == item_id, CartItem.user_id == user.id).first()
    if not item:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Cart item not found")

    item.quantity = data.quantity
    db.commit()
    return {"message": "Cart updated"}


@router.delete("/{item_id}")
def remove_from_cart(item_id: int, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    item = db.query(CartItem).filter(CartItem.id == item_id, CartItem.user_id == user.id).first()
    if not item:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Cart item not found")

    db.delete(item)
    db.commit()
    return {"message": "Item removed from cart"}
