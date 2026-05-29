# Mangansage backend — production container image untuk Cloud Run.
#
# Stack: FrankenPHP (Caddy + PHP terpadu, single binary) — sederhana, cepat,
# dan cocok untuk Cloud Run yang scale-to-zero.
#
# Build:  gcloud builds submit --tag <ARTIFACT_REGISTRY_IMAGE> backend
# Run:    gcloud run deploy mangansage-api --image <IMAGE> --region asia-southeast1

# Stage 1: Build frontend assets
FROM node:20-alpine AS node_builder
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm ci || npm install
COPY . .
RUN npm run build

# Stage 2: Build PHP container
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

# Salin frontend build dari stage node_builder
COPY --from=node_builder /app/public/build ./public/build

# Optimisasi autoloader untuk produksi.
RUN composer dump-autoload --optimize --no-dev --classmap-authoritative

# Permission Laravel storage + bootstrap/cache (FrankenPHP run as www-data).
RUN chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

# Entrypoint: cache config/route, lalu jalankan FrankenPHP.
COPY .docker/start.sh /start.sh
COPY .docker/worker.sh /worker.sh
COPY .docker/reverb.sh /reverb.sh
RUN chmod +x /start.sh /worker.sh /reverb.sh

# Cloud Run inject PORT env var (default 8080). FrankenPHP akan listen di
# `:{$PORT}` lewat Caddyfile default-nya kalau SERVER_NAME=":{$PORT}".
ENV SERVER_NAME=":8080"
EXPOSE 8080

CMD ["/start.sh"]
