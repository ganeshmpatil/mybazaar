from decimal import Decimal

from sqlalchemy import func
from sqlalchemy.orm import Session, joinedload

from ..models.product import Category, Product, ProductImage
from ..models.stock import Stock


def get_categories(db: Session, active_only: bool = True) -> list[Category]:
    query = db.query(Category)
    if active_only:
        query = query.filter(Category.is_active == True)
    return query.order_by(Category.sort_order).all()


def create_category(db: Session, name: str, parent_id: int | None = None,
                    image_url: str | None = None, sort_order: int = 0) -> Category:
    category = Category(name=name, parent_id=parent_id, image_url=image_url, sort_order=sort_order)
    db.add(category)
    db.commit()
    db.refresh(category)
    return category


def get_products(db: Session, category_id: int | None = None, search: str | None = None,
                 page: int = 1, page_size: int = 20, active_only: bool = True,
                 attribute_filters: str | None = None):
    import json as _json

    query = db.query(Product).options(joinedload(Product.images), joinedload(Product.stock))

    if active_only:
        query = query.filter(Product.is_active == True)
    if category_id:
        query = query.filter(Product.category_id == category_id)
    if search:
        query = query.filter(Product.name.ilike(f"%{search}%"))

    # Apply JSONB attribute filters
    if attribute_filters:
        try:
            attr_dict = _json.loads(attribute_filters)
            for key, value in attr_dict.items():
                query = query.filter(
                    Product.attributes[key].astext == str(value)
                )
        except (ValueError, TypeError):
            pass

    total = query.count()
    products = query.offset((page - 1) * page_size).limit(page_size).all()

    return products, total


def get_product_by_id(db: Session, product_id: int) -> Product | None:
    return (
        db.query(Product)
        .options(joinedload(Product.images), joinedload(Product.stock), joinedload(Product.category))
        .filter(Product.id == product_id)
        .first()
    )


def create_product(db: Session, data: dict) -> Product:
    initial_stock = data.pop("initial_stock", Decimal("0"))

    product = Product(**data)
    db.add(product)
    db.flush()

    stock = Stock(product_id=product.id, quantity=initial_stock)
    db.add(stock)
    db.commit()
    db.refresh(product)
    return product


def update_product(db: Session, product_id: int, data: dict) -> Product | None:
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        return None

    for key, value in data.items():
        if value is not None:
            setattr(product, key, value)

    db.commit()
    db.refresh(product)
    return product
