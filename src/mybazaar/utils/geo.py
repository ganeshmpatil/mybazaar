from sqlalchemy import text
from sqlalchemy.orm import Session

from ..config import settings


def is_within_delivery_radius(db: Session, customer_lat: float, customer_lng: float) -> tuple[bool, float]:
    result = db.execute(text("""
        SELECT ST_Distance(
            ST_MakePoint(:store_lng, :store_lat)::geography,
            ST_MakePoint(:cust_lng, :cust_lat)::geography
        ) AS distance_meters
    """), {
        "store_lat": settings.store_lat,
        "store_lng": settings.store_lng,
        "cust_lat": customer_lat,
        "cust_lng": customer_lng,
    })
    distance_meters = result.scalar()
    distance_km = round(distance_meters / 1000, 2)
    is_serviceable = distance_km <= settings.delivery_radius_km
    return is_serviceable, distance_km
