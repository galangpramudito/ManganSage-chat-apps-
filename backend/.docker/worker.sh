#!/bin/sh
# Laravel queue worker — dipanggil dari container `queue` di docker-compose.
#
# Auto-restart oleh Docker kalau crash (restart: unless-stopped).
# Tidak butuh dummy HTTP server (itu khusus Cloud Run health check).
set -e

# Cache config + event.
php artisan config:cache
php artisan event:cache

echo "Starting Laravel Queue Worker..."
exec php artisan queue:work --tries=3 --max-time=3600 --sleep=3
