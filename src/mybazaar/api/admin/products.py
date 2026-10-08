from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from ...database import get_db
from ...middleware.auth import require_admin
from ...models.user import User
from ...schemas.product import CategoryCreate, CategoryResponse, ProductCreate, ProductResponse, ProductUpdate
from ...services import product_service

router = APIRouter()


@router.post("/categories", response_model=CategoryResponse, status_code=status.HTTP_201_CREATED)
def create_category(data: CategoryCreate, user: User = Depends(require_admin), db: Session = Depends(get_db)):
    category = product_service.create_category(db, data.name, data.parent_id, data.image_url, data.sort_order)
    return category


@router.post("", response_model=ProductResponse, status_code=status.HTTP_201_CREATED)
def create_product(data: ProductCreate, user: User = Depends(require_admin), db: Session = Depends(get_db)):
    product = product_service.create_product(db, data.model_dump())
    return {
        "id": product.id,
        "name": product.name,
        "description": product.description,
        "category_id": product.category_id,
        "mrp": product.mrp,
        "selling_price": product.selling_price,
        "unit": product.unit,
        "attributes": product.attributes,
        "gst_percent": product.gst_percent,
        "is_active": product.is_active,
        "images": [],
        "stock_quantity": product.stock.quantity if product.stock else None,
    }


@router.put("/{product_id}", response_model=ProductResponse)
def update_product(product_id: int, data: ProductUpdate,
                   user: User = Depends(require_admin), db: Session = Depends(get_db)):
    product = product_service.update_product(db, product_id, data.model_dump(exclude_unset=True))
    if not product:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")
    return {
        "id": product.id,
        "name": product.name,
        "description": product.description,
        "category_id": product.category_id,
        "mrp": product.mrp,
        "selling_price": product.selling_price,
        "unit": product.unit,
        "attributes": product.attributes,
        "gst_percent": product.gst_percent,
        "is_active": product.is_active,
        "images": product.images,
        "stock_quantity": product.stock.quantity if product.stock else None,
    }


@router.delete("/{product_id}")
def delete_product(product_id: int, user: User = Depends(require_admin), db: Session = Depends(get_db)):
    product = product_service.update_product(db, product_id, {"is_active": False})
    if not product:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")
    return {"message": "Product deactivated"}
