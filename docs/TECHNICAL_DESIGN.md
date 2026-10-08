# MyBazaar - Technical Design Document

## 1. Vision

A hyperlocal e-commerce platform for small towns and rural cities — enabling local shops to accept orders online and deliver within a configurable radius (15-20 km). Think "Amazon for your town."

---

## 2. Database Recommendation

### PostgreSQL (Recommended)

| Criteria | PostgreSQL | MySQL | MongoDB |
|---|---|---|---|
| Relational data (orders, products, users) | Excellent | Good | Weak |
| ACID transactions (payments, stock) | Full | Full | Limited |
| JSON fields (flexible product attributes) | Native `jsonb` | Limited | Native |
| Full-text search (product search) | Built-in `tsvector` | Basic | Built-in |
| Geospatial (delivery radius) | PostGIS extension | Limited | Good |
| Cost | Free | Free | Free |
| Python ecosystem | Excellent (psycopg2, SQLAlchemy) | Good | Good |

**Why PostgreSQL wins for MyBazaar:**
- Orders, inventory, and payments are inherently relational — needs ACID guarantees
- `jsonb` columns handle variable product attributes (e.g., clothing has size/color, groceries have weight/expiry)
- **PostGIS** enables delivery radius checks with real geo-queries (`ST_DWithin`)
- Built-in full-text search avoids needing Elasticsearch at this scale
- Scales comfortably to 100K+ products and millions of orders

**Supplementary:**
- **Redis** — for caching, session management, OTP storage (TTL-based), rate limiting
- **S3-compatible storage** (MinIO for self-hosted or AWS S3) — for product images

---

## 3. Feature Analysis

### 3.1 Your Listed Features (Confirmed)

| # | Feature | Status |
|---|---|---|
| 1 | Stock Management | Confirmed |
| 2 | Product Registration | Confirmed |
| 3 | Mobile Number Based Auth (~500 users initially) | Confirmed |
| 4 | Android Mobile App | Confirmed |
| 5 | Delivery Tracking | Confirmed |
| 6 | Order History | Confirmed |
| 7 | Return/Refund of Orders | Confirmed |
| 8 | Cash on Delivery | Confirmed |
| 9 | Configurable Delivery Area (15-20 km) | Confirmed |
| 10 | Profit & Loss Dashboard | Confirmed |

### 3.2 Missing Features You Should Add

#### Critical (Must-Have for Launch)

| # | Feature | Why |
|---|---|---|
| 11 | **OTP-based Login** | Standard in India; no passwords to remember. Use SMS gateway (MSG91/Twilio) |
| 12 | **Product Categories & Catalog Browsing** | Users need to browse by category (Groceries, Clothing, Electronics, etc.) |
| 13 | **Product Search** | Users expect to search by name/keyword |
| 14 | **Shopping Cart** | Add multiple items before placing a single order |
| 15 | **Product Images** | No one buys without seeing the product |
| 16 | **Order Notifications** | SMS/WhatsApp alerts for order placed, shipped, delivered |
| 17 | **Pincode/Area Serviceability Check** | Before checkout, verify delivery is possible to user's location |
| 19 | **Admin Panel (Web)** | Shop owner needs a dashboard to manage products, orders, delivery boys |
| 20 | **Invoice/Bill Generation** | PDF invoice with GST details for each order |

#### Important (Add Soon After Launch)

| # | Feature | Why |
|---|---|---|
| 21 | **Delivery Boy Management** | Assign orders to delivery personnel, track their location |
| 22 | **Delivery Time Slot Selection** | Let customers pick morning/afternoon/evening delivery |
| 23 | **Ratings & Reviews** | Build trust; let buyers rate products |
| 24 | **Wishlist / Save for Later** | Common e-commerce feature |
| 25 | **Coupons & Discounts** | First-order discounts, festive offers, referral codes |
| 26 | **Low Stock Alerts** | Notify admin when inventory drops below threshold |
| 27 | **GST Handling** | Tax calculation per product category |
| 28 | **Referral System** | "Invite friends, get ₹50 off" — organic growth in small towns |

#### Nice-to-Have (Future)

| # | Feature | Why |
|---|---|---|
| 29 | **Multi-vendor Support** | Allow multiple local shops to sell on the platform |
| 30 | **Subscription Orders** | Weekly milk, daily newspaper — recurring orders |
| 31 | **Multi-language Support** | Hindi, Marathi, regional language UI |
| 32 | **WhatsApp Ordering** | Many rural users prefer WhatsApp; chatbot integration |
| 33 | **Loyalty Points** | Reward repeat customers |

---

## 4. System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      CLIENTS                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────────────┐  │
│  │  Flutter App │  │ Admin Panel  │  │ Delivery Boy App  │  │
│  │(Android+iOS) │  │ (Web - React)│  │ (Flutter)         │  │
│  └──────┬───────┘  └──────┬───────┘  └────────┬──────────┘  │
└─────────┼─────────────────┼───────────────────┼─────────────┘
          │                 │                   │
          ▼                 ▼                   ▼
┌─────────────────────────────────────────────────────────────┐
│                    API GATEWAY / NGINX                        │
│                  (Rate Limiting, SSL, CORS)                   │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                 PYTHON BACKEND (FastAPI)                      │
│                                                              │
│  ┌─────────┐ ┌─────────┐ ┌──────────┐ ┌─────────────────┐  │
│  │  Auth   │ │ Product │ │  Order   │ │    Delivery      │  │
│  │ Module  │ │ Module  │ │  Module  │ │    Module        │  │
│  └─────────┘ └─────────┘ └──────────┘ └─────────────────┘  │
│  ┌─────────┐ ┌──────────┐ ┌─────────────────┐               │
│  │  Stock  │ │ Reports  │ │  Notification    │               │
│  │ Module  │ │  Module  │ │  Module          │               │
│  └─────────┘ └──────────┘ └─────────────────┘               │
└────────┬──────────┬──────────┬──────────┬───────────────────┘
         │          │          │          │
         ▼          ▼          ▼          ▼
┌──────────────┐ ┌───────┐ ┌──────┐ ┌──────────┐
│ PostgreSQL   │ │ Redis │ │ S3/  │ │ SMS/WA   │
│ + PostGIS    │ │       │ │ MinIO│ │ Gateway  │
└──────────────┘ └───────┘ └──────┘ └──────────┘
```

---

## 5. Tech Stack

| Layer | Technology | Justification |
|---|---|---|
| **Backend** | Python 3.11+ / FastAPI | Async, fast, auto-generated OpenAPI docs, great for mobile APIs |
| **ORM** | SQLAlchemy 2.0 + Alembic | Industry standard; Alembic for DB migrations |
| **Database** | PostgreSQL 16 + PostGIS | See Section 2 |
| **Cache** | Redis | OTP storage, sessions, frequently accessed data |
| **Image Storage** | MinIO (self-hosted S3) | Product images, invoices |
| **Auth** | JWT + OTP (SMS) | Stateless auth; OTP via MSG91 or similar |
| **Payment** | Cash on Delivery only | No payment gateway needed; delivery boy collects cash |
| **Notifications** | MSG91 (SMS) + WhatsApp Business API | Order updates |
| **Mobile Apps** | Flutter (Dart) | Single codebase for Android + iOS; fast development |
| **Admin Panel** | React (or served via FastAPI templates) | Product/order management |
| **Deployment** | Docker + Docker Compose | Simple single-server deployment |
| **Web Server** | Nginx | Reverse proxy, SSL termination |

---

## 6. Data Model (Core Entities)

### 6.1 Entity Relationship Overview

```
User ──1:N──> Address
User ──1:N──> Order
User ──1:N──> Cart
Order ──1:N──> OrderItem ──N:1──> Product
Product ──N:1──> Category
Product ──1:N──> ProductImage
Order ──1:1──> Delivery
Order ──1:N──> OrderStatusHistory
DeliveryBoy ──1:N──> Delivery
Product ──1:1──> StockEntry
```

### 6.2 Key Tables

```sql
-- Users (customers)
CREATE TABLE users (
    id              BIGSERIAL PRIMARY KEY,
    mobile          VARCHAR(15) UNIQUE NOT NULL,
    name            VARCHAR(100),
    email           VARCHAR(255),
    is_active       BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Addresses with geolocation for delivery radius check
CREATE TABLE addresses (
    id              BIGSERIAL PRIMARY KEY,
    user_id         BIGINT REFERENCES users(id),
    label           VARCHAR(50),  -- 'Home', 'Work'
    full_address    TEXT NOT NULL,
    pincode         VARCHAR(10),
    city            VARCHAR(100),
    location        GEOGRAPHY(POINT, 4326),  -- PostGIS lat/lng
    is_default      BOOLEAN DEFAULT FALSE,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Product categories (hierarchical)
CREATE TABLE categories (
    id              BIGSERIAL PRIMARY KEY,
    name            VARCHAR(100) NOT NULL,
    parent_id       BIGINT REFERENCES categories(id),
    image_url       VARCHAR(500),
    sort_order      INT DEFAULT 0,
    is_active       BOOLEAN DEFAULT TRUE
);

-- Products
CREATE TABLE products (
    id              BIGSERIAL PRIMARY KEY,
    name            VARCHAR(255) NOT NULL,
    description     TEXT,
    category_id     BIGINT REFERENCES categories(id),
    mrp             DECIMAL(10,2) NOT NULL,
    selling_price   DECIMAL(10,2) NOT NULL,
    cost_price      DECIMAL(10,2) NOT NULL,  -- for P&L calculation
    unit            VARCHAR(20),  -- 'kg', 'piece', 'litre', 'pack'
    attributes      JSONB,  -- flexible: {"color": "red", "size": "L", "weight": "500g"}
    hsn_code        VARCHAR(20),  -- GST HSN code
    gst_percent     DECIMAL(4,2) DEFAULT 0,
    is_active       BOOLEAN DEFAULT TRUE,
    search_vector   TSVECTOR,  -- full-text search
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Product images
CREATE TABLE product_images (
    id              BIGSERIAL PRIMARY KEY,
    product_id      BIGINT REFERENCES products(id) ON DELETE CASCADE,
    image_url       VARCHAR(500) NOT NULL,
    sort_order      INT DEFAULT 0,
    is_primary      BOOLEAN DEFAULT FALSE
);

-- Stock management
CREATE TABLE stock (
    id              BIGSERIAL PRIMARY KEY,
    product_id      BIGINT UNIQUE REFERENCES products(id),
    quantity         DECIMAL(10,2) NOT NULL DEFAULT 0,
    low_stock_threshold DECIMAL(10,2) DEFAULT 5,
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Stock movement log (audit trail)
CREATE TABLE stock_ledger (
    id              BIGSERIAL PRIMARY KEY,
    product_id      BIGINT REFERENCES products(id),
    change_qty      DECIMAL(10,2) NOT NULL,  -- +ve for inward, -ve for outward
    reason          VARCHAR(50) NOT NULL,  -- 'PURCHASE', 'SALE', 'RETURN', 'ADJUSTMENT'
    reference_id    BIGINT,  -- order_id or adjustment_id
    balance_after   DECIMAL(10,2) NOT NULL,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Shopping cart
CREATE TABLE cart_items (
    id              BIGSERIAL PRIMARY KEY,
    user_id         BIGINT REFERENCES users(id),
    product_id      BIGINT REFERENCES products(id),
    quantity        DECIMAL(10,2) NOT NULL DEFAULT 1,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, product_id)
);

-- Orders
CREATE TABLE orders (
    id              BIGSERIAL PRIMARY KEY,
    order_number    VARCHAR(20) UNIQUE NOT NULL,  -- e.g., 'MB-20261008-0001'
    user_id         BIGINT REFERENCES users(id),
    address_id      BIGINT REFERENCES addresses(id),
    status          VARCHAR(30) NOT NULL DEFAULT 'PLACED',
        -- PLACED -> CONFIRMED -> PACKED -> OUT_FOR_DELIVERY -> DELIVERED
        -- PLACED -> CANCELLED
        -- DELIVERED -> RETURN_REQUESTED -> RETURNED
    subtotal        DECIMAL(10,2) NOT NULL,
    delivery_charge DECIMAL(10,2) DEFAULT 0,
    discount        DECIMAL(10,2) DEFAULT 0,
    gst_amount      DECIMAL(10,2) DEFAULT 0,
    total           DECIMAL(10,2) NOT NULL,
    payment_mode    VARCHAR(20) NOT NULL DEFAULT 'COD',  -- Cash on Delivery only
    delivery_slot   VARCHAR(30),  -- 'MORNING', 'AFTERNOON', 'EVENING'
    notes           TEXT,  -- customer instructions
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Order items
CREATE TABLE order_items (
    id              BIGSERIAL PRIMARY KEY,
    order_id        BIGINT REFERENCES orders(id),
    product_id      BIGINT REFERENCES products(id),
    product_name    VARCHAR(255) NOT NULL,  -- snapshot at time of order
    quantity        DECIMAL(10,2) NOT NULL,
    unit_price      DECIMAL(10,2) NOT NULL,  -- snapshot at time of order
    cost_price      DECIMAL(10,2) NOT NULL,  -- snapshot for P&L
    total_price     DECIMAL(10,2) NOT NULL
);

-- Order status history (tracking)
CREATE TABLE order_status_history (
    id              BIGSERIAL PRIMARY KEY,
    order_id        BIGINT REFERENCES orders(id),
    status          VARCHAR(30) NOT NULL,
    notes           TEXT,
    created_by      VARCHAR(50),  -- 'SYSTEM', 'ADMIN', 'DELIVERY_BOY'
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- COD payment collection tracking
CREATE TABLE cod_collections (
    id              BIGSERIAL PRIMARY KEY,
    order_id        BIGINT REFERENCES orders(id),
    amount          DECIMAL(10,2) NOT NULL,
    status          VARCHAR(20) NOT NULL DEFAULT 'PENDING',
        -- PENDING -> COLLECTED -> SETTLED (handed to admin)
    collected_by    BIGINT,  -- delivery_boy_id
    collected_at    TIMESTAMPTZ,
    settled_at      TIMESTAMPTZ,  -- when delivery boy hands cash to admin
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Delivery boys
CREATE TABLE delivery_boys (
    id              BIGSERIAL PRIMARY KEY,
    name            VARCHAR(100) NOT NULL,
    mobile          VARCHAR(15) UNIQUE NOT NULL,
    is_active       BOOLEAN DEFAULT TRUE,
    current_location GEOGRAPHY(POINT, 4326),
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Delivery assignment
CREATE TABLE deliveries (
    id              BIGSERIAL PRIMARY KEY,
    order_id        BIGINT UNIQUE REFERENCES orders(id),
    delivery_boy_id BIGINT REFERENCES delivery_boys(id),
    status          VARCHAR(20) DEFAULT 'ASSIGNED',
        -- ASSIGNED -> PICKED_UP -> IN_TRANSIT -> DELIVERED / FAILED
    assigned_at     TIMESTAMPTZ DEFAULT NOW(),
    picked_up_at    TIMESTAMPTZ,
    delivered_at    TIMESTAMPTZ
);

-- Returns
CREATE TABLE returns (
    id              BIGSERIAL PRIMARY KEY,
    order_id        BIGINT REFERENCES orders(id),
    reason          TEXT NOT NULL,
    status          VARCHAR(20) DEFAULT 'REQUESTED',
        -- REQUESTED -> APPROVED -> PICKED_UP -> REFUNDED / REJECTED
    refund_amount   DECIMAL(10,2),
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Store configuration (delivery radius, charges, etc.)
CREATE TABLE store_config (
    key             VARCHAR(100) PRIMARY KEY,
    value           JSONB NOT NULL,
    description     TEXT
);
-- Example rows:
-- ('delivery_radius_km', '20', 'Max delivery distance in KM')
-- ('delivery_charge', '{"free_above": 500, "default": 30}', 'Delivery fee rules')
-- ('store_location', '{"lat": 19.876, "lng": 75.343}', 'Store coordinates')
-- ('operating_hours', '{"start": "08:00", "end": "21:00"}', 'Order acceptance window')

-- Coupons
CREATE TABLE coupons (
    id              BIGSERIAL PRIMARY KEY,
    code            VARCHAR(30) UNIQUE NOT NULL,
    discount_type   VARCHAR(10) NOT NULL,  -- 'PERCENT', 'FLAT'
    discount_value  DECIMAL(10,2) NOT NULL,
    min_order_value DECIMAL(10,2) DEFAULT 0,
    max_discount    DECIMAL(10,2),
    usage_limit     INT,
    used_count      INT DEFAULT 0,
    valid_from      TIMESTAMPTZ,
    valid_till      TIMESTAMPTZ,
    is_active       BOOLEAN DEFAULT TRUE
);
```

---

## 7. API Design (Key Endpoints)

### 7.1 Auth
```
POST   /api/v1/auth/send-otp          { mobile }
POST   /api/v1/auth/verify-otp        { mobile, otp } → { token }
GET    /api/v1/auth/profile
PUT    /api/v1/auth/profile            { name, email }
```

### 7.2 Products & Categories
```
GET    /api/v1/categories                          → category tree
GET    /api/v1/products?category=X&search=Y&page=1 → paginated list
GET    /api/v1/products/{id}                       → product detail
POST   /api/v1/admin/products                      → create product (admin)
PUT    /api/v1/admin/products/{id}                 → update product (admin)
DELETE /api/v1/admin/products/{id}                 → soft delete (admin)
```

### 7.3 Cart
```
GET    /api/v1/cart
POST   /api/v1/cart                    { product_id, quantity }
PUT    /api/v1/cart/{item_id}          { quantity }
DELETE /api/v1/cart/{item_id}
```

### 7.4 Orders
```
POST   /api/v1/orders/check-serviceability   { address_id } → deliverable?
POST   /api/v1/orders                        { address_id, slot, coupon }
GET    /api/v1/orders                        → order history
GET    /api/v1/orders/{id}                   → order detail + tracking
POST   /api/v1/orders/{id}/cancel
POST   /api/v1/orders/{id}/return            { reason }
```

### 7.5 Admin
```
GET    /api/v1/admin/orders?status=X         → filtered orders
PUT    /api/v1/admin/orders/{id}/status       { status, delivery_boy_id }
GET    /api/v1/admin/stock                    → stock levels
PUT    /api/v1/admin/stock/{product_id}       { quantity, reason }
GET    /api/v1/admin/reports/pnl?from=&to=   → profit & loss
GET    /api/v1/admin/reports/sales?from=&to=  → sales summary
GET    /api/v1/admin/dashboard                → today's stats
```

### 7.6 Delivery Boy
```
GET    /api/v1/delivery/my-orders             → assigned orders
PUT    /api/v1/delivery/orders/{id}/status     { status }
PUT    /api/v1/delivery/location               { lat, lng }
```

---

## 8. Delivery Radius — How It Works

```python
# Using PostGIS — check if customer is within delivery range
from sqlalchemy import text

def is_serviceable(session, customer_lat, customer_lng):
    store_location = get_config("store_location")  # {"lat": ..., "lng": ...}
    radius_km = get_config("delivery_radius_km")    # e.g., 20

    result = session.execute(text("""
        SELECT ST_DWithin(
            ST_MakePoint(:store_lng, :store_lat)::geography,
            ST_MakePoint(:cust_lng, :cust_lat)::geography,
            :radius_meters
        ) AS within_range
    """), {
        "store_lat": store_location["lat"],
        "store_lng": store_location["lng"],
        "cust_lat": customer_lat,
        "cust_lng": customer_lng,
        "radius_meters": radius_km * 1000
    })
    return result.scalar()
```

---

## 9. Profit & Loss Dashboard — Data Points

```
Revenue
├── Total Sales (sum of order_items.total_price for DELIVERED orders)
├── Delivery Charges Collected
└── Minus: Refunds (returned orders)

Costs
├── Cost of Goods Sold (sum of order_items.cost_price * quantity)
├── Delivery Expenses
Profit = Revenue - Costs

Dashboard Cards:
├── Today's Orders / Revenue / Profit
├── This Week / Month trends
├── Top Selling Products
├── Low Stock Alerts
├── Order Status Distribution (pie chart)
└── Delivery Performance (avg time, success rate)
```

---

## 10. Project Structure

```
mybazaar/
├── docs/
│   └── TECHNICAL_DESIGN.md
├── src/
│   └── mybazaar/
│       ├── __init__.py
│       ├── main.py                  # FastAPI app entry point
│       ├── config.py                # Settings (env-based)
│       ├── database.py              # DB engine, session
│       ├── models/                  # SQLAlchemy models
│       │   ├── __init__.py
│       │   ├── user.py
│       │   ├── product.py
│       │   ├── order.py
│       │   ├── stock.py
│       │   ├── delivery.py
│       │   └── cod_collection.py
│       ├── schemas/                 # Pydantic request/response schemas
│       │   ├── __init__.py
│       │   ├── auth.py
│       │   ├── product.py
│       │   ├── order.py
│       │   └── common.py
│       ├── api/                     # Route handlers
│       │   ├── __init__.py
│       │   ├── auth.py
│       │   ├── products.py
│       │   ├── cart.py
│       │   ├── orders.py
│       │   ├── delivery.py
│       │   └── admin/
│       │       ├── __init__.py
│       │       ├── products.py
│       │       ├── orders.py
│       │       ├── stock.py
│       │       └── reports.py
│       ├── services/                # Business logic
│       │   ├── __init__.py
│       │   ├── auth_service.py
│       │   ├── product_service.py
│       │   ├── order_service.py
│       │   ├── stock_service.py
│       │   ├── delivery_service.py
│       │   ├── cod_service.py
│       │   └── notification_service.py
│       ├── utils/
│       │   ├── __init__.py
│       │   ├── security.py          # JWT, OTP
│       │   ├── geo.py               # PostGIS helpers
│       │   └── invoice.py           # PDF generation
│       └── middleware/
│           ├── __init__.py
│           └── auth.py              # JWT middleware
├── migrations/                      # Alembic migrations
│   ├── alembic.ini
│   └── versions/
├── tests/
│   ├── __init__.py
│   ├── test_auth.py
│   ├── test_products.py
│   └── test_orders.py
├── docker-compose.yml               # PostgreSQL + Redis + MinIO + App
├── Dockerfile
├── requirements.txt
├── .env.example
├── .gitignore
└── README.md
```

---

## 11. Docker Compose (Development)

```yaml
version: '3.8'
services:
  db:
    image: postgis/postgis:16-3.4
    environment:
      POSTGRES_DB: mybazaar
      POSTGRES_USER: mybazaar
      POSTGRES_PASSWORD: mybazaar_dev
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  minio:
    image: minio/minio
    command: server /data --console-address ":9001"
    environment:
      MINIO_ROOT_USER: minioadmin
      MINIO_ROOT_PASSWORD: minioadmin
    ports:
      - "9000:9000"
      - "9001:9001"
    volumes:
      - minio_data:/data

volumes:
  pgdata:
  minio_data:
```

---

## 12. Order Flow (State Machine)

```
                  PLACED
                    │
            ┌───────┴───────┐
            ▼               ▼
        CONFIRMED       CANCELLED
            │
            ▼
          PACKED
            │
            ▼
    OUT_FOR_DELIVERY
            │
      ┌─────┴─────┐
      ▼            ▼
  DELIVERED    DELIVERY_FAILED
      │
      ▼
RETURN_REQUESTED (within 24h)
      │
  ┌───┴───┐
  ▼       ▼
RETURNED  RETURN_REJECTED
  │
  ▼
REFUNDED
```

---

## 13. Non-Functional Requirements

| Aspect | Target |
|---|---|
| **Users** | 500 initially, scalable to 5,000 |
| **Concurrent API requests** | ~50-100 (FastAPI handles this easily) |
| **API response time** | < 200ms (p95) |
| **Image size** | Compress to < 500KB on upload |
| **Uptime** | 99.5% (single server is fine at this scale) |
| **Deployment** | Single VPS (4GB RAM, 2 vCPU) via Docker Compose |
| **Backup** | Daily PostgreSQL pg_dump to S3 |
| **Security** | HTTPS, JWT with refresh tokens, rate limiting on OTP |

---

## 14. Phase-wise Rollout

### Phase 1 — MVP (4-6 weeks)
- OTP auth, product catalog, cart, order placement
- COD payment only
- Basic admin panel (add products, manage orders, update stock)
- SMS notifications
- Delivery radius check

### Phase 2 — Growth (3-4 weeks)
- Delivery boy app + assignment
- COD collection tracking & settlement
- Live delivery tracking
- P&L dashboard
- Invoice generation

### Phase 3 — Engagement (3-4 weeks)
- Ratings & reviews
- Coupons & discounts
- Wishlist
- Referral system
- Delivery slot selection

### Phase 4 — Scale (Future)
- Multi-vendor support
- WhatsApp ordering bot
- Multi-language UI
- Subscription/recurring orders
- Loyalty points program
