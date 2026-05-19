#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════
# UMIRA — SSL Certificate Auto-Renewal
# ════════════════════════════════════════════════════════════
# Add to crontab:
#   0 3 * * * /path/to/umira/infra/ssl/renew-ssl.sh >> /var/log/umira_ssl_renew.log 2>&1
# ════════════════════════════════════════════════════════════

set -euo pipefail

echo "[$(date)] Checking certificate renewal..."

# Attempt renewal
sudo certbot renew --quiet --non-interactive

# Reload nginx if a certificate was renewed
if sudo nginx -t 2>/dev/null; then
    sudo nginx -s reload
    echo "[$(date)] nginx reloaded (if cert was renewed, new cert is active)"
else
    echo "[$(date)] ERROR: nginx config test failed — not reloading"
    exit 1
fi
