import shutil
from pathlib import Path

import cloudinary
import cloudinary.uploader
from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status
from sqlalchemy.orm import Session

from ...config import settings
from ...database import get_db
from ...middleware.auth import require_admin
from ...models.product import Product, ProductImage
from ...models.user import User

router = APIRouter()

STATIC_DIR = Path(__file__).resolve().parent.parent.parent.parent.parent / "static" / "products"
ALLOWED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp"}
MAX_FILE_SIZE = 5 * 1024 * 1024  # 5 MB


def _cloudinary_configured() -> bool:
    return bool(settings.cloudinary_cloud_name and settings.cloudinary_api_key)


def _init_cloudinary():
    cloudinary.config(
        cloud_name=settings.cloudinary_cloud_name,
        api_key=settings.cloudinary_api_key,
        api_secret=settings.cloudinary_api_secret,
        secure=True,
    )


def _upload_to_cloudinary(file: UploadFile, product_name: str) -> str:
    _init_cloudinary()
    safe_name = product_name.lower().split("(")[0].strip().replace(" ", "_")
    result = cloudinary.uploader.upload(
        file.file,
        folder="mybazaar/products",
        public_id=safe_name,
        overwrite=True,
        resource_type="image",
        transformation=[{"width": 800, "height": 800, "crop": "limit", "quality": "auto"}],
    )
    return result["secure_url"]


def _upload_to_local(file: UploadFile, product_name: str) -> str:
    ext = Path(file.filename).suffix.lower() or ".jpg"
    safe_name = product_name.lower().split("(")[0].strip().replace(" ", "_")
    filename = f"{safe_name}{ext}"

    STATIC_DIR.mkdir(parents=True, exist_ok=True)
    file_path = STATIC_DIR / filename
    with open(file_path, "wb") as f:
        shutil.copyfileobj(file.file, f)

    return f"/static/products/{filename}"


@router.post("/{product_id}/image")
def upload_product_image(
    product_id: int,
    file: UploadFile = File(...),
    user: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    # Validate file type
    ext = Path(file.filename).suffix.lower() if file.filename else ""
    if ext not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid file type '{ext}'. Allowed: {', '.join(ALLOWED_EXTENSIONS)}",
        )

    # Validate file size
    file.file.seek(0, 2)
    size = file.file.tell()
    file.file.seek(0)
    if size > MAX_FILE_SIZE:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"File too large. Max size: {MAX_FILE_SIZE // (1024*1024)} MB",
        )

    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")

    if _cloudinary_configured():
        image_url = _upload_to_cloudinary(file, product.name)
    else:
        image_url = _upload_to_local(file, product.name)

    existing = db.query(ProductImage).filter(
        ProductImage.product_id == product_id, ProductImage.is_primary == True
    ).first()

    if existing:
        existing.image_url = image_url
    else:
        db.add(ProductImage(product_id=product_id, image_url=image_url, is_primary=True))

    db.commit()
    return {"message": "Image uploaded", "image_url": image_url}
