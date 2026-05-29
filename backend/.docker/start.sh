#!/bin/sh
# Cloud Run startup script — runs once per container start.
set -e

# Cache config + route + event untuk production performance.
# Idempotent — aman dipanggil ulang.
php artisan config:cache
php artisan route:cache
php artisan event:cache
php artisan view:cache

# Migration TIDAK dijalankan di sini — schema deploy via local CLI:
#   php artisan migrate --force
# (pakai DB_URL direct endpoint, bukan pooler, untuk DDL).

# Storage symlink — tidak diperlukan kalau tidak melayani user uploads via /storage.
# Tambahkan: php artisan storage:link  jika perlu.

# Pre-warm opcache.
echo "Starting FrankenPHP on port ${PORT:-8080}..."

# FrankenPHP serves Laravel public/ via default Caddyfile.
# Listen address controlled by SERVER_NAME env var (set in Dockerfile).
exec frankenphp run --config /etc/caddy/Caddyfile
