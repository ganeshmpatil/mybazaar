from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .config import settings
from .api import auth, products, cart, orders, delivery
from .api.admin import products as admin_products
from .api.admin import orders as admin_orders
from .api.admin import stock as admin_stock
from .api.admin import reports as admin_reports

app = FastAPI(
    title=settings.store_name,
    description="Hyperlocal e-commerce platform for small towns",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Customer APIs
app.include_router(auth.router, prefix="/api/v1/auth", tags=["Auth"])
app.include_router(products.router, prefix="/api/v1/products", tags=["Products"])
app.include_router(cart.router, prefix="/api/v1/cart", tags=["Cart"])
app.include_router(orders.router, prefix="/api/v1/orders", tags=["Orders"])
app.include_router(delivery.router, prefix="/api/v1/delivery", tags=["Delivery"])

# Admin APIs
app.include_router(admin_products.router, prefix="/api/v1/admin/products", tags=["Admin - Products"])
app.include_router(admin_orders.router, prefix="/api/v1/admin/orders", tags=["Admin - Orders"])
app.include_router(admin_stock.router, prefix="/api/v1/admin/stock", tags=["Admin - Stock"])
app.include_router(admin_reports.router, prefix="/api/v1/admin/reports", tags=["Admin - Reports"])


@app.get("/health")
def health_check():
    return {"status": "ok", "store": settings.store_name}
