#!/usr/bin/env bash
#
# MyBazaar Deployment Script — Neon (DB) + Render (App + Redis)
#
# Prerequisites:
#   1. Install Neon CLI:  npm i -g neonctl
#   2. Install Render CLI: https://render.com/docs/cli (or use dashboard)
#   3. Authenticate:
#      - neonctl auth
#      - render login (or use dashboard)
#
# Usage:
#   chmod +x deploy.sh
#   ./deploy.sh setup     # First-time setup (create Neon DB + Render services)
#   ./deploy.sh deploy    # Deploy latest code to Render
#   ./deploy.sh migrate   # Run DB migrations against Neon
#   ./deploy.sh seed      # Seed products and admin user
#   ./deploy.sh status    # Check service status
#   ./deploy.sh logs      # View Render logs
#   ./deploy.sh destroy   # Tear down everything
#
set -euo pipefail

# ─── Config ───────────────────────────────────────────────────
PROJECT_NAME="mybazaar"
NEON_PROJECT="${PROJECT_NAME}"
NEON_DB="mybazaar"
NEON_ROLE="mybazaar"
RENDER_SERVICE="mybazaar-api"
GITHUB_REPO="ganeshmpatil/mybazaar"
ENV_FILE=".env.production"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()   { echo -e "${GREEN}[✓]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; exit 1; }
info()  { echo -e "${BLUE}[i]${NC} $1"; }

# ─── Check prerequisites ─────────────────────────────────────
check_tools() {
    local missing=()
    command -v neonctl  >/dev/null 2>&1 || missing+=("neonctl (npm i -g neonctl)")
    command -v git      >/dev/null 2>&1 || missing+=("git")
    command -v curl     >/dev/null 2>&1 || missing+=("curl")
    command -v python3  >/dev/null 2>&1 || missing+=("python3")

    if [ ${#missing[@]} -gt 0 ]; then
        error "Missing tools: ${missing[*]}"
    fi
    log "All prerequisites met"
}

# ─── 1. Setup Neon Database ──────────────────────────────────
setup_neon() {
    info "Setting up Neon PostgreSQL..."

    # Check if project already exists
    if neonctl projects list 2>/dev/null | grep -q "$NEON_PROJECT"; then
        warn "Neon project '$NEON_PROJECT' already exists"
    else
        neonctl projects create --name "$NEON_PROJECT"
        log "Created Neon project: $NEON_PROJECT"
    fi

    # Get connection string
    local conn_str
    conn_str=$(neonctl connection-string --project-id "$(get_neon_project_id)" --database-name "$NEON_DB" 2>/dev/null || true)

    if [ -z "$conn_str" ]; then
        # Create database and role if needed
        local project_id
        project_id=$(get_neon_project_id)

        # Get the connection string (Neon creates a default DB)
        conn_str=$(neonctl connection-string --project-id "$project_id")
        log "Got connection string from Neon"
    fi

    # Save to env file
    echo "DATABASE_URL=${conn_str}" > "$ENV_FILE"
    echo "# Neon Project: $NEON_PROJECT" >> "$ENV_FILE"
    log "Saved DATABASE_URL to $ENV_FILE"

    echo ""
    info "Neon Database URL (keep this safe):"
    echo "  $conn_str"
    echo ""
}

get_neon_project_id() {
    neonctl projects list --output json 2>/dev/null \
        | python3 -c "
import sys, json
projects = json.load(sys.stdin)
for p in projects:
    if p.get('name') == '$NEON_PROJECT':
        print(p['id'])
        break
"
}

# ─── 2. Run Migrations ───────────────────────────────────────
run_migrations() {
    info "Running Alembic migrations against Neon..."

    if [ ! -f "$ENV_FILE" ]; then
        error "No $ENV_FILE found. Run './deploy.sh setup' first."
    fi

    source <(grep DATABASE_URL "$ENV_FILE")
    export DATABASE_URL

    # Activate venv if exists
    if [ -f "venv/bin/activate" ]; then
        source venv/bin/activate
    fi

    PYTHONPATH="$(pwd)" python -m alembic upgrade head
    log "Migrations complete"
}

# ─── 3. Seed Data ────────────────────────────────────────────
seed_data() {
    info "Seeding products and admin user..."

    if [ ! -f "$ENV_FILE" ]; then
        error "No $ENV_FILE found. Run './deploy.sh setup' first."
    fi

    source <(grep DATABASE_URL "$ENV_FILE")

    # Extract parts from connection string for psql
    # Neon URLs: postgresql://user:pass@host/dbname?sslmode=require
    local db_url="$DATABASE_URL"

    python3 << 'SEED_SCRIPT'
import os
from sqlalchemy import create_engine, text

db_url = os.environ["DATABASE_URL"]
engine = create_engine(db_url)

with engine.connect() as conn:
    # Create admin user
    conn.execute(text("""
        INSERT INTO users (mobile, role, created_at, updated_at)
        VALUES ('9930668736', 'admin', now(), now())
        ON CONFLICT (mobile) DO UPDATE SET role = 'admin'
    """))

    # Create category
    result = conn.execute(text("""
        INSERT INTO categories (name, is_active, created_at, updated_at)
        VALUES ('Groceries & Staples', true, now(), now())
        ON CONFLICT DO NOTHING
        RETURNING id
    """))
    row = result.fetchone()
    cat_id = row[0] if row else conn.execute(text("SELECT id FROM categories LIMIT 1")).fetchone()[0]

    # Seed products
    products = [
        ("Rice (Basmati)", "Premium Basmati Rice", 110, 110, 80, "1 kg", 5),
        ("Sunflower Oil", "Refined Sunflower Oil", 140, 135, 100, "1 L", 5),
        ("Pohe (Flattened Rice)", "Thin Pohe", 45, 42, 30, "500 g", 5),
        ("Rawa (Semolina)", "Fine Rawa", 50, 48, 35, "500 g", 5),
        ("Gehu (Wheat)", "Premium Wheat Grain", 40, 38, 28, "1 kg", 5),
        ("Besan (Gram Flour)", "Fine Besan", 75, 72, 50, "500 g", 5),
        ("Ghee (Desi)", "Pure Desi Ghee", 550, 530, 400, "500 ml", 5),
        ("Sugar", "Refined Sugar", 45, 42, 32, "1 kg", 5),
        ("Salt (Iodized)", "Iodized Table Salt", 22, 20, 14, "1 kg", 5),
        ("Maida (All Purpose)", "Fine Maida Flour", 40, 38, 28, "500 g", 5),
    ]

    for name, desc, mrp, sp, cp, unit, gst in products:
        result = conn.execute(text("""
            INSERT INTO products (name, description, mrp, selling_price, cost_price, unit,
                                  gst_percent, category_id, is_active, created_at, updated_at)
            VALUES (:name, :desc, :mrp, :sp, :cp, :unit, :gst, :cat_id, true, now(), now())
            ON CONFLICT DO NOTHING
            RETURNING id
        """), {"name": name, "desc": desc, "mrp": mrp, "sp": sp, "cp": cp,
               "unit": unit, "gst": gst, "cat_id": cat_id})

        row = result.fetchone()
        if row:
            pid = row[0]
            conn.execute(text("""
                INSERT INTO stock (product_id, quantity, low_stock_threshold, updated_at)
                VALUES (:pid, 100, 10, now())
                ON CONFLICT DO NOTHING
            """), {"pid": pid})

    conn.commit()

print("Seeded successfully!")
SEED_SCRIPT

    log "Data seeded (admin: 9930668736, 10 products with stock)"
}

# ─── 4. Deploy to Render ─────────────────────────────────────
deploy_render() {
    info "Deploying to Render..."

    # Check if render.yaml exists
    if [ ! -f "render.yaml" ]; then
        error "render.yaml not found"
    fi

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Render Deployment Options"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  Option A: Deploy via Render Dashboard (Recommended)"
    echo ""
    echo "  1. Go to https://dashboard.render.com"
    echo "  2. Click 'New' → 'Blueprint'"
    echo "  3. Connect your GitHub repo: $GITHUB_REPO"
    echo "  4. Render will detect render.yaml and create services"
    echo "  5. Set the DATABASE_URL env var to your Neon connection string"
    echo ""

    if [ -f "$ENV_FILE" ]; then
        source <(grep DATABASE_URL "$ENV_FILE")
        echo "  Your Neon DATABASE_URL:"
        echo "  $DATABASE_URL"
        echo ""
    fi

    echo "  Option B: Deploy via Render CLI"
    echo ""
    echo "  render blueprint launch"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # If render CLI is available, offer to deploy
    if command -v render >/dev/null 2>&1; then
        read -rp "Deploy using Render CLI now? (y/N): " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            render blueprint launch
            log "Render deployment initiated"
        fi
    else
        warn "Render CLI not installed. Use the dashboard at https://dashboard.render.com"
        info "Install Render CLI: https://render.com/docs/cli"
    fi
}

# ─── 5. Push code to GitHub ───────────────────────────────────
push_code() {
    info "Pushing latest code to GitHub..."

    git add -A
    git status

    read -rp "Commit message (or Enter for default): " msg
    msg="${msg:-Deploy: update Dockerfile and add render.yaml}"

    git commit -m "$msg" || warn "Nothing to commit"
    git push origin main
    log "Code pushed to GitHub"
}

# ─── 6. Status Check ─────────────────────────────────────────
check_status() {
    info "Checking service status..."

    echo ""
    echo "── Neon Database ──"
    if command -v neonctl >/dev/null 2>&1; then
        neonctl projects list 2>/dev/null | head -10 || warn "Cannot reach Neon"
    else
        warn "neonctl not installed"
    fi

    echo ""
    echo "── Render Service ──"
    if command -v render >/dev/null 2>&1; then
        render services list 2>/dev/null | grep -i mybazaar || warn "Service not found"
    else
        warn "Render CLI not installed"
        info "Check at: https://dashboard.render.com"
    fi

    echo ""
    echo "── Health Check ──"
    if [ -f "$ENV_FILE" ]; then
        # Try to find the Render URL
        info "Check your Render dashboard for the live URL"
    fi
}

# ─── 7. View Logs ────────────────────────────────────────────
view_logs() {
    if command -v render >/dev/null 2>&1; then
        render logs --service "$RENDER_SERVICE" --tail
    else
        warn "Render CLI not installed"
        info "View logs at: https://dashboard.render.com → mybazaar-api → Logs"
    fi
}

# ─── 8. Destroy Everything ───────────────────────────────────
destroy() {
    echo ""
    warn "This will DELETE all deployed resources!"
    read -rp "Type 'yes-delete-everything' to confirm: " confirm

    if [ "$confirm" != "yes-delete-everything" ]; then
        info "Aborted"
        exit 0
    fi

    info "Destroying Neon project..."
    if command -v neonctl >/dev/null 2>&1; then
        local project_id
        project_id=$(get_neon_project_id)
        if [ -n "$project_id" ]; then
            neonctl projects delete "$project_id"
            log "Neon project deleted"
        fi
    fi

    info "Destroying Render services..."
    if command -v render >/dev/null 2>&1; then
        render services delete --name "$RENDER_SERVICE" --yes 2>/dev/null || true
        render services delete --name "mybazaar-redis" --yes 2>/dev/null || true
        log "Render services deleted"
    else
        warn "Delete services manually at https://dashboard.render.com"
    fi

    rm -f "$ENV_FILE"
    log "Cleanup complete"
}

# ─── Full Setup Flow ─────────────────────────────────────────
full_setup() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  MyBazaar — Full Deployment Setup"
    echo "  Neon (PostgreSQL) + Render (FastAPI + Redis)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    check_tools

    echo ""
    info "Step 1/5: Setting up Neon PostgreSQL..."
    setup_neon

    echo ""
    info "Step 2/5: Running database migrations..."
    run_migrations

    echo ""
    info "Step 3/5: Seeding initial data..."
    seed_data

    echo ""
    info "Step 4/5: Pushing code to GitHub..."
    push_code

    echo ""
    info "Step 5/5: Deploying to Render..."
    deploy_render

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Deployment Complete!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  Next steps:"
    echo "  1. Set DATABASE_URL in Render dashboard (from $ENV_FILE)"
    echo "  2. Wait for Render to build and deploy"
    echo "  3. Access your app at: https://mybazaar-api.onrender.com"
    echo "  4. Admin panel: https://mybazaar-api.onrender.com/admin"
    echo "  5. Login: 9930668736 / OTP: 5112"
    echo ""
    echo "  Cloudinary (for product images):"
    echo "  1. Sign up free at https://cloudinary.com"
    echo "  2. Go to Dashboard → copy Cloud Name, API Key, API Secret"
    echo "  3. Set in Render env vars:"
    echo "     CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY, CLOUDINARY_API_SECRET"
    echo ""
}

# ─── CLI Router ───────────────────────────────────────────────
case "${1:-}" in
    setup)    full_setup ;;
    neon)     check_tools && setup_neon ;;
    migrate)  run_migrations ;;
    seed)     seed_data ;;
    deploy)   deploy_render ;;
    push)     push_code ;;
    status)   check_status ;;
    logs)     view_logs ;;
    destroy)  destroy ;;
    *)
        echo ""
        echo "Usage: ./deploy.sh <command>"
        echo ""
        echo "Commands:"
        echo "  setup     Full setup (Neon DB + migrations + seed + Render deploy)"
        echo "  neon      Create Neon database only"
        echo "  migrate   Run Alembic migrations against Neon"
        echo "  seed      Seed products and admin user"
        echo "  deploy    Deploy to Render"
        echo "  push      Commit and push code to GitHub"
        echo "  status    Check service status"
        echo "  logs      View Render logs"
        echo "  destroy   Tear down all resources"
        echo ""
        ;;
esac
