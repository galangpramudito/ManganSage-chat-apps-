# Mangansage backend — production container image untuk Oracle Cloud VM.
#
# Stack: FrankenPHP (Caddy + PHP terpadu, single binary).
# Image dipakai 3x oleh docker-compose: app (FrankenPHP), reverb (WS), queue (worker).
#
# Build (dari folder backend/):
#   docker build -t mangansage-app:latest .
# Atau via compose: docker compose build

# Build PHP container
FROM dunglas/frankenphp:latest

# System tools yang dibutuhkan composer untuk extract package + (optional) source.
RUN apt-get update \
    && apt-get install -y --no-install-recommends unzip git \
    && rm -rf /var/lib/apt/lists/*

# Extension PHP yang dibutuhkan Laravel + driver Postgres untuk Neon.
RUN install-php-extensions \
    pdo_pgsql \
    bcmath \
    intl \
    pcntl \
    opcache \
    zip

WORKDIR /app

# Composer dari image resmi.
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Install dependencies dulu (layer cache yang berubah jarang).
COPY composer.json composer.lock ./
RUN composer install \
    --no-dev \
    --no-scripts \
    --no-autoloader \
    --prefer-dist \
    --no-interaction

# Salin source app.
COPY . .

# Optimisasi autoloader untuk produksi.
RUN composer dump-autoload --optimize --no-dev --classmap-authoritative

# Permission Laravel storage + bootstrap/cache (FrankenPHP run as www-data).
RUN chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

# Entrypoint scripts: app server, reverb server, queue worker.
COPY .docker/start.sh /start.sh
COPY .docker/worker.sh /worker.sh
COPY .docker/reverb.sh /reverb.sh
RUN chmod +x /start.sh /worker.sh /reverb.sh

# Default: jalankan FrankenPHP di port 8000.
# Override via docker-compose `environment.SERVER_NAME` (mis. ":8000") atau `command`.
ENV SERVER_NAME=":8000"
EXPOSE 8000 8080

# Healthcheck — Caddy ngecek port 8000 atau 8080 (tergantung service).
# Kalau gagal 3x berturut → container di-mark unhealthy → docker akan restart.
HEALTHCHECK --interval=30s --timeout=10s --start-period=20s --retries=3 \
    CMD wget -q --spider http://127.0.0.1:8000/up 2>/dev/null \
        || wget -q --spider http://127.0.0.1:8080 2>/dev/null \
        || exit 1

CMD ["/start.sh"]
