# Deploy Guide — Laravel + Reverb ke Fly.io
> Windows · From Machine · Neon PostgreSQL (sudah ada)

---

## Persiapan

### 1. Install flyctl (CLI Fly.io)

Buka PowerShell sebagai **Administrator**, jalankan:

```powershell
iwr https://fly.io/install.ps1 -useb | iex
```

Verifikasi:
```powershell
fly version
```

### 2. Login ke Fly.io

```powershell
fly auth login
```

Browser akan terbuka, login dengan akun Fly.io kamu.

---

## Setup Project Laravel

Masuk ke folder backend Laravel kamu:

```powershell
cd path\to\Mangansage\backend
```

### 3. Buat `Dockerfile`

Buat file `Dockerfile` di root folder `backend/`:

```dockerfile
FROM php:8.3-fpm-alpine

# Install dependencies
RUN apk add --no-cache \
    nginx \
    supervisor \
    postgresql-dev \
    nodejs \
    npm \
    curl \
    zip \
    unzip

# Install PHP extensions
RUN docker-php-ext-install pdo pdo_pgsql pcntl

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# Copy composer files first (layer cache)
COPY composer.json composer.lock ./
RUN composer install --no-dev --optimize-autoloader --no-scripts

# Copy semua file
COPY . .

# Generate key & optimize
RUN php artisan key:generate --force
RUN php artisan config:cache
RUN php artisan route:cache
RUN php artisan view:cache

# Permissions
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# Copy config files
COPY docker/nginx.conf /etc/nginx/nginx.conf
COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 8080

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
```

### 4. Buat folder `docker/` dan config files

**`docker/nginx.conf`:**
```nginx
worker_processes auto;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    server {
        listen 8080;
        root /var/www/html/public;
        index index.php;

        location / {
            try_files $uri $uri/ /index.php?$query_string;
        }

        location ~ \.php$ {
            fastcgi_pass 127.0.0.1:9000;
            fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
            include fastcgi_params;
        }
    }
}
```

**`docker/supervisord.conf`:**
```ini
[supervisord]
nodaemon=true
logfile=/dev/null
logfile_maxbytes=0

[program:php-fpm]
command=php-fpm
autostart=true
autorestart=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0

[program:nginx]
command=nginx -g "daemon off;"
autostart=true
autorestart=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0
```

### 5. Buat `.dockerignore`

```
.git
node_modules
vendor
.env
.env.*
storage/logs/*
storage/framework/cache/*
storage/framework/sessions/*
storage/framework/views/*
```

---

## Setup Fly.io

### 6. Launch App Laravel

```powershell
fly launch --name mangansage-api --region sin --no-deploy
```

> `sin` = Singapore. Kalau mau region lain: `hkg` (Hong Kong), `nrt` (Tokyo).
> `--no-deploy` = jangan deploy dulu, kita set environment dulu.

Saat ditanya apakah mau pakai Dockerfile yang ada → **Yes**.
Saat ditanya apakah mau tambah database → **No** (sudah pakai Neon).

Ini akan generate file `fly.toml` di folder backend.

### 7. Edit `fly.toml`

Buka `fly.toml`, pastikan isinya seperti ini:

```toml
app = "mangansage-api"
primary_region = "sin"

[build]

[http_service]
  internal_port = 8080
  force_https = true
  auto_stop_machines = "stop"
  auto_start_machines = true
  min_machines_running = 0

[[vm]]
  memory = "512mb"
  cpu_kind = "shared"
  cpus = 1
```

### 8. Set Environment Variables

Set semua `.env` production ke Fly.io secrets:

```powershell
fly secrets set `
  APP_NAME="Mangansage" `
  APP_ENV=production `
  APP_DEBUG=false `
  APP_URL=https://mangansage-api.fly.dev `
  DB_CONNECTION=pgsql `
  DB_HOST=your-neon-host.neon.tech `
  DB_PORT=5432 `
  DB_DATABASE=neondb `
  DB_USERNAME=your-neon-user `
  DB_PASSWORD=your-neon-password `
  DB_SSLMODE=require `
  BROADCAST_CONNECTION=reverb `
  REVERB_APP_ID=your-reverb-app-id `
  REVERB_APP_KEY=your-reverb-app-key `
  REVERB_APP_SECRET=your-reverb-app-secret `
  REVERB_HOST=mangansage-reverb.fly.dev `
  REVERB_PORT=443 `
  REVERB_SCHEME=https `
  QUEUE_CONNECTION=sync `
  CACHE_STORE=file `
  SESSION_DRIVER=file `
  FIREBASE_CREDENTIALS=storage/firebase-credentials.json
```

> Salin nilai dari `backend/.env` lokal kamu untuk `REVERB_APP_ID`, `REVERB_APP_KEY`, `REVERB_APP_SECRET`.
> Nilai Neon ambil dari dashboard Neon.

---

## Deploy App Laravel (API)

### 9. Deploy

```powershell
fly deploy
```

Tunggu sampai selesai. Jika sukses, API kamu live di:
```
https://mangansage-api.fly.dev
```

### 10. Jalankan Migration

```powershell
fly ssh console -C "php artisan migrate --force"
```

---

## Setup Reverb (WebSocket) — App Terpisah

Reverb perlu app Fly.io tersendiri karena butuh port WebSocket yang berbeda dan proses yang selalu hidup.

### 11. Buat App Baru untuk Reverb

```powershell
fly launch --name mangansage-reverb --region sin --no-deploy
```

### 12. Buat `Dockerfile.reverb`

Di folder `backend/`, buat file baru `Dockerfile.reverb`:

```dockerfile
FROM php:8.3-cli-alpine

RUN apk add --no-cache postgresql-dev curl zip unzip

RUN docker-php-ext-install pdo pdo_pgsql pcntl

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

COPY composer.json composer.lock ./
RUN composer install --no-dev --optimize-autoloader --no-scripts

COPY . .

RUN php artisan config:cache

EXPOSE 8080

CMD ["php", "artisan", "reverb:start", "--host=0.0.0.0", "--port=8080"]
```

### 13. Edit `fly.toml` Reverb

Buat file `fly.reverb.toml` terpisah:

```toml
app = "mangansage-reverb"
primary_region = "sin"

[build]
  dockerfile = "Dockerfile.reverb"

[http_service]
  internal_port = 8080
  force_https = true
  auto_stop_machines = "stop"
  auto_start_machines = true
  min_machines_running = 1        # jangan sleep — WebSocket harus selalu hidup

[[vm]]
  memory = "256mb"
  cpu_kind = "shared"
  cpus = 1
```

### 14. Set Secrets Reverb

```powershell
fly secrets set `
  --app mangansage-reverb `
  APP_ENV=production `
  DB_CONNECTION=pgsql `
  DB_HOST=your-neon-host.neon.tech `
  DB_PORT=5432 `
  DB_DATABASE=neondb `
  DB_USERNAME=your-neon-user `
  DB_PASSWORD=your-neon-password `
  DB_SSLMODE=require `
  BROADCAST_CONNECTION=reverb `
  REVERB_APP_ID=your-reverb-app-id `
  REVERB_APP_KEY=your-reverb-app-key `
  REVERB_APP_SECRET=your-reverb-app-secret `
  REVERB_HOST=0.0.0.0 `
  REVERB_PORT=8080
```

### 15. Deploy Reverb

```powershell
fly deploy --config fly.reverb.toml
```

---

## Update Flutter — Arahkan ke Production

Setelah kedua app deploy, update dart-define saat build Flutter:

```powershell
flutter build apk `
  --dart-define=API_BASE_URL=https://mangansage-api.fly.dev/api `
  --dart-define=REVERB_HOST=mangansage-reverb.fly.dev `
  --dart-define=REVERB_PORT=443 `
  --dart-define=REVERB_APP_KEY=your-reverb-app-key
```

> Port 443 karena Fly.io terminate SSL — Reverb di belakangnya pakai 8080 tapi Flutter connect via HTTPS/WSS.

---

## Verifikasi

### Cek API
```
https://mangansage-api.fly.dev/api/user
```
Harus return 401 (artinya API hidup, hanya butuh auth).

### Cek Reverb
```powershell
fly logs --app mangansage-reverb
```
Harus ada log: `Starting Reverb server on 0.0.0.0:8080`

### Cek dari Flutter
Login → kirim pesan → pastikan pesan muncul real-time di device lain.

---

## Perintah Berguna

```powershell
# Lihat logs API
fly logs --app mangansage-api

# Lihat logs Reverb
fly logs --app mangansage-reverb

# SSH masuk ke VM
fly ssh console --app mangansage-api

# Jalankan artisan command
fly ssh console --app mangansage-api -C "php artisan migrate:status"

# Restart app
fly machine restart --app mangansage-api

# Scale memory kalau butuh
fly scale memory 1024 --app mangansage-api
```

---

## Catatan Penting

- **`min_machines_running = 1`** di Reverb wajib — kalau 0, machine sleep dan semua WebSocket connection putus
- **Firebase credentials** — kalau pakai FCM, upload file JSON via:
  ```powershell
  fly ssh sftp shell --app mangansage-api
  # lalu upload file ke storage/firebase-credentials.json
  ```
- **Auto-stop API** boleh (set ke `stop`) karena Laravel API stateless — akan wake otomatis saat ada request
- **Neon** — pastikan connection string sudah pakai `sslmode=require`, Neon enforce SSL
