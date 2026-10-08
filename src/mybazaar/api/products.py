from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from ..database import get_db
from ..schemas.product import CategoryResponse, ProductListResponse, ProductResponse
from ..services import product_service

router = APIRouter()


@router.get("/categories", response_model=list[CategoryResponse])
def list_categories(db: Session = Depends(get_db)):
    categories = product_service.get_categories(db)
    return categories


@router.get("", response_model=dict)
def list_products(
    category_id: int | None = None,
    search: str | None = None,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
):
    products, total = product_service.get_products(db, category_id, search, page, page_size)

    items = []
    for p in products:
        primary_image = None
        for img in p.images:
            if img.is_primary:
                primary_image = img.image_url
                break
        if not primary_image and p.images:
            primary_image = p.images[0].image_url

        items.append({
            "id": p.id,
            "name": p.name,
            "selling_price": p.selling_price,
            "mrp": p.mrp,
            "unit": p.unit,
            "primary_image": primary_image,
            "stock_quantity": p.stock.quantity if p.stock else None,
            "is_active": p.is_active,
        })

    return {
        "items": items,
        "total": total,
        "page": page,
        "page_size": page_size,
        "total_pages": (total + page_size - 1) // page_size,
    }


@router.get("/{product_id}", response_model=ProductResponse)
def get_product(product_id: int, db: Session = Depends(get_db)):
    product = product_service.get_product_by_id(db, product_id)
    if not product:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")

    result = {
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
    return result
