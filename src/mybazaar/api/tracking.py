import json

from fastapi import APIRouter, Depends, HTTPException, WebSocket, WebSocketDisconnect, status
from pydantic import BaseModel
from sqlalchemy.orm import Session

from ..database import get_db
from ..middleware.auth import get_current_user, require_delivery_boy
from ..models.delivery import Delivery, DeliveryBoy
from ..models.tracking import DeliveryTracking
from ..models.user import User
from ..utils.security import decode_access_token, redis_client

router = APIRouter()


class LocationUpdate(BaseModel):
    order_id: int
    latitude: float
    longitude: float


@router.post("/update-location")
def update_location(
    data: LocationUpdate,
    user: User = Depends(require_delivery_boy),
    db: Session = Depends(get_db),
):
    delivery_boy = db.query(DeliveryBoy).filter(DeliveryBoy.mobile == user.mobile).first()
    if not delivery_boy:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Delivery boy not found")

    delivery = db.query(Delivery).filter(
        Delivery.order_id == data.order_id,
        Delivery.delivery_boy_id == delivery_boy.id,
        Delivery.status.in_(["ASSIGNED", "PICKED_UP", "IN_TRANSIT"]),
    ).first()
    if not delivery:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Active delivery not found")

    # Save to DB (route history)
    track = DeliveryTracking(
        delivery_id=delivery.id,
        order_id=data.order_id,
        delivery_boy_id=delivery_boy.id,
        latitude=data.latitude,
        longitude=data.longitude,
    )
    db.add(track)
    db.commit()

    # Save latest location to Redis (for real-time)
    location_data = json.dumps({
        "order_id": data.order_id,
        "delivery_boy_id": delivery_boy.id,
        "delivery_boy_name": delivery_boy.name,
        "latitude": data.latitude,
        "longitude": data.longitude,
    })
    redis_client.setex(f"tracking:{data.order_id}", 300, location_data)
    redis_client.setex(f"tracking:boy:{delivery_boy.id}", 300, location_data)

    return {"message": "Location updated"}


@router.get("/location/{order_id}")
def get_location(order_id: int, user: User = Depends(get_current_user)):
    cached = redis_client.get(f"tracking:{order_id}")
    if cached:
        return json.loads(cached)
    return {"message": "No live location available"}


@router.get("/route/{order_id}")
def get_route(order_id: int, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    points = (
        db.query(DeliveryTracking)
        .filter(DeliveryTracking.order_id == order_id)
        .order_by(DeliveryTracking.created_at.asc())
        .all()
    )
    return [
        {"lat": float(p.latitude), "lng": float(p.longitude), "time": p.created_at.isoformat()}
        for p in points
    ]


@router.get("/active-deliveries")
def get_active_deliveries(user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Get all active deliveries with latest locations (for admin map)."""
    if user.role != "admin":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Admin only")

    active = (
        db.query(Delivery)
        .filter(Delivery.status.in_(["ASSIGNED", "PICKED_UP", "IN_TRANSIT"]))
        .all()
    )

    results = []
    for d in active:
        location = redis_client.get(f"tracking:{d.order_id}")
        loc_data = json.loads(location) if location else None
        results.append({
            "delivery_id": d.id,
            "order_id": d.order_id,
            "order_number": d.order.order_number if d.order else None,
            "delivery_boy_name": d.delivery_boy.name if d.delivery_boy else None,
            "status": d.status,
            "location": loc_data,
        })
    return results


# WebSocket for real-time tracking
class TrackingConnectionManager:
    def __init__(self):
        self.connections: dict[int, list[WebSocket]] = {}

    async def connect(self, order_id: int, websocket: WebSocket):
        await websocket.accept()
        if order_id not in self.connections:
            self.connections[order_id] = []
        self.connections[order_id].append(websocket)

    def disconnect(self, order_id: int, websocket: WebSocket):
        if order_id in self.connections:
            self.connections[order_id].remove(websocket)
            if not self.connections[order_id]:
                del self.connections[order_id]

    async def broadcast_location(self, order_id: int, data: dict):
        if order_id in self.connections:
            for ws in self.connections[order_id]:
                try:
                    await ws.send_json(data)
                except Exception:
                    pass


manager = TrackingConnectionManager()


@router.websocket("/ws/{order_id}")
async def tracking_websocket(websocket: WebSocket, order_id: int):
    # Authenticate via query param
    token = websocket.query_params.get("token")
    if not token or not decode_access_token(token):
        await websocket.close(code=4001)
        return

    await manager.connect(order_id, websocket)
    try:
        while True:
            data = await websocket.receive_text()
            # Delivery boy can send location via WebSocket too
            try:
                loc = json.loads(data)
                if "latitude" in loc and "longitude" in loc:
                    location_data = {
                        "order_id": order_id,
                        "latitude": loc["latitude"],
                        "longitude": loc["longitude"],
                    }
                    redis_client.setex(f"tracking:{order_id}", 300, json.dumps(location_data))
                    await manager.broadcast_location(order_id, location_data)
            except json.JSONDecodeError:
                pass
    except WebSocketDisconnect:
        manager.disconnect(order_id, websocket)
