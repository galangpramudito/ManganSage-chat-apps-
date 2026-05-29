#!/bin/sh
# Cloud Run WebSocket (Reverb) startup script
set -e

# Cache config & route for performance
php artisan config:cache
php artisan route:cache
php artisan event:cache

echo "Starting Laravel Reverb on port ${PORT:-8080}..."
exec php artisan reverb:start --host=0.0.0.0 --port=${PORT:-8080}
