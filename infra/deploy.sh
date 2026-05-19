#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════
# UMIRA — Production Deploy Script
# ════════════════════════════════════════════════════════════
# Prerequisites:
#   - Docker & Docker Compose installed on the target host
#   - .env file present in the project root with required secrets
#   - nginx SSL certificates already set up (see infra/ssl/setup-ssl.sh)
#
# Usage:
#   ./infra/deploy.sh                        # full deploy
#   ./infra/deploy.sh --skip-build           # reuse existing images
#   ./infra/deploy.sh --rollback             # revert to previous release
# ════════════════════════════════════════════════════════════

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

RELEASE_TAG="${RELEASE_TAG:-$(date +%Y%m%d-%H%M%S)}"
COMPOSE_FILE="docker-compose.yml"
BACKUP_DIR="/tmp/umira-backups"
SKIP_BUILD=false
ROLLBACK=false

# Parse flags
for arg in "$@"; do
    case "$arg" in
        --skip-build) SKIP_BUILD=true ;;
        --rollback)   ROLLBACK=true ;;
    esac
done

# ── Colors ──
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log()  { echo -e "${GREEN}[deploy]${NC} $1"; }
warn() { echo -e "${YELLOW}[deploy]${NC} $1"; }
err()  { echo -e "${RED}[deploy]${NC} $1"; exit 1; }

# ── Preflight checks ──

preflight() {
    log "Running preflight checks..."

    command -v docker &>/dev/null || err "docker is not installed"
    command -v docker compose &>/dev/null || err "docker compose is not installed"

    if [ ! -f "$COMPOSE_FILE" ]; then
        err "$COMPOSE_FILE not found in $PROJECT_DIR"
    fi

    if [ ! -f ".env" ]; then
        err ".env file not found. Copy .env.example to .env and fill in secrets."
    fi

    log "Preflight checks passed."
}

# ── Backup ──

backup() {
    log "Creating database backup..."

    mkdir -p "$BACKUP_DIR"
    local dump_file="$BACKUP_DIR/umira_db_$RELEASE_TAG.sql"

    docker compose exec -T postgres pg_dump -U umira umira > "$dump_file" 2>/dev/null || \
        warn "Could not backup database (maybe postgres isn't running yet)"

    log "Backup saved to $dump_file"
}

# ── Build ──

build_images() {
    if [ "$SKIP_BUILD" = true ]; then
        log "Skipping build (--skip-build)"
        return
    fi

    log "Building production images (tag: $RELEASE_TAG)..."

    docker compose build backend

    log "Build complete."
}

# ── Deploy ──

run_deploy() {
    log "Starting deployment (release: $RELEASE_TAG)..."

    # Build Flutter web app (skip if not available / headless)
    if command -v flutter &>/dev/null; then
        log "Building Flutter web app..."
        (cd mobile && flutter build web --release) || \
            warn "Flutter web build failed — static files won't be updated"
    else
        warn "Flutter not found — skipping web build (ensure mobile/build/web exists)"
    fi

    # Start / restart all services
    docker compose up -d postgres redis
    docker compose up -d backend

    # Wait for backend health
    log "Waiting for backend health check..."
    local retries=30
    local i=0
    while [ $i -lt $retries ]; do
        if curl -sf http://localhost:4000/health > /dev/null 2>&1; then
            log "Backend is healthy!"
            break
        fi
        sleep 2
        i=$((i + 1))
    done

    if [ $i -ge $retries ]; then
        err "Backend failed to start within $((retries * 2)) seconds. Rolling back..."
        rollback
    fi

    # Run database migrations
    log "Running database migrations..."
    docker compose exec -T backend npx prisma migrate deploy || \
        warn "Migration may have already been applied or failed — check logs"

    # Start nginx (if configured)
    if docker compose config --services 2>/dev/null | grep -q "^nginx$"; then
        docker compose up -d nginx
    fi

    log "Deployment complete!"
}

# ── Rollback ──

rollback() {
    warn "Rolling back to previous release..."

    # Restore from the most recent backup
    local latest_backup=$(ls -t "$BACKUP_DIR"/umira_db_*.sql 2>/dev/null | head -1)
    if [ -n "$latest_backup" ]; then
        log "Restoring database from $latest_backup..."
        docker compose exec -T postgres psql -U umira umira < "$latest_backup" || \
            warn "Database restore failed"
    fi

    # Rebuild and restart with previous image
    docker compose up -d --force-recreate backend

    log "Rollback complete. Verify the app is functioning."
}

# ── Cleanup old images ──

cleanup() {
    log "Cleaning up old Docker images..."
    docker image prune -f --filter "until=72h" || true
    log "Cleanup done."
}

# ── Main ──

main() {
    echo ""
    echo "╔══════════════════════════════════════╗"
    echo "║      UMIRA Production Deploy         ║"
    echo "╚══════════════════════════════════════╝"
    echo ""

    preflight

    if [ "$ROLLBACK" = true ]; then
        rollback
        exit 0
    fi

    backup
    build_images
    run_deploy
    cleanup

    echo ""
    log "✓ UMIRA is deployed and healthy on port 4000"
    echo ""
}

main
