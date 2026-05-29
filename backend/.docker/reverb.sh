#!/bin/sh
# Laravel Reverb WebSocket startup — dipanggil dari container `reverb` di docker-compose.
set -e

# Cache config + route + event untuk performance.
php artisan config:cache
php artisan route:cache
php artisan event:cache

echo "Starting Laravel Reverb on 0.0.0.0:8080..."
exec php artisan reverb:start --host=0.0.0.0 --port=8080
