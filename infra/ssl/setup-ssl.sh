#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════
# UMIRA — SSL Certificate Setup (Certbot + Let's Encrypt)
# ════════════════════════════════════════════════════════════
# Usage:
#   ./infra/ssl/setup-ssl.sh               # dry-run (staging)
#   ./infra/ssl/setup-ssl.sh --live        # production certificates
# ════════════════════════════════════════════════════════════

set -euo pipefail

DOMAIN="umira.app"
EMAIL="admin@umira.app"          # ← CHANGE to your email
MODE="${1:---dry-run}"
LIVE_FLAG=""

if [ "$MODE" = "--live" ]; then
    echo "→ Obtaining LIVE certificates for $DOMAIN"
else
    echo "→ Dry-run (staging) — no real certificates issued"
    LIVE_FLAG="--dry-run"
fi

# ── Ensure nginx is running with the HTTP-only config first ──
# Before running this script, deploy the HTTP-only nginx config
# (server block listening on port 80 with no SSL) so Certbot
# can verify domain ownership.

echo "→ Running Certbot for $DOMAIN..."

sudo certbot certonly --webroot \
    $LIVE_FLAG \
    -d "$DOMAIN" \
    -d "www.$DOMAIN" \
    --email "$EMAIL" \
    --webroot-path /var/www/certbot \
    --agree-tos \
    --non-interactive

echo ""
echo "✓ Done. Certificates saved to:"
echo "  /etc/letsencrypt/live/$DOMAIN/fullchain.pem"
echo "  /etc/letsencrypt/live/$DOMAIN/privkey.pem"
echo ""
echo "→ Deploy the full nginx config (with SSL) and reload:"
echo "  sudo nginx -s reload"
