import shutil
from pathlib import Path

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status
from sqlalchemy.orm import Session

from ...database import get_db
from ...middleware.auth import require_admin
from ...models.product import Product, ProductImage
from ...models.user import User

router = APIRouter()

STATIC_DIR = Path(__file__).resolve().parent.parent.parent.parent.parent / "static" / "products"


@router.post("/{product_id}/image")
def upload_product_image(
    product_id: int,
    file: UploadFile = File(...),
    user: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")

    ext = Path(file.filename).suffix.lower() or ".jpg"
    safe_name = product.name.lower().split("(")[0].strip().replace(" ", "_")
    filename = f"{safe_name}{ext}"

    STATIC_DIR.mkdir(parents=True, exist_ok=True)
    file_path = STATIC_DIR / filename
    with open(file_path, "wb") as f:
        shutil.copyfileobj(file.file, f)

    image_url = f"http://localhost:8000/static/products/{filename}"

    existing = db.query(ProductImage).filter(
        ProductImage.product_id == product_id, ProductImage.is_primary == True
    ).first()

    if existing:
        existing.image_url = image_url
    else:
        db.add(ProductImage(product_id=product_id, image_url=image_url, is_primary=True))

    db.commit()
    return {"message": "Image uploaded", "image_url": image_url}
