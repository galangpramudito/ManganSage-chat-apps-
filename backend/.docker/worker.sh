#!/bin/sh
# Cloud Run worker startup script

# Jalankan dummy web server di background agar Cloud Run mendeteksi port 8080 terbuka (health check pass)
php -S 0.0.0.0:${PORT:-8080} -t public &

# Jalankan queue worker di foreground. Jika crash/berhenti, container akan mati dan di-restart otomatis oleh Cloud Run.
echo "Starting Laravel Queue Worker..."
exec php artisan queue:work --tries=3 --max-time=3600
