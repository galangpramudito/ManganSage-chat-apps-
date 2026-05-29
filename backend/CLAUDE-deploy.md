# CLAUDE.md — Mangansage Backend Deployment Context
> Baca ini sebelum menyentuh apapun yang berhubungan dengan Docker, Fly.io, atau server.

---

## Situasi Saat Ini

Dockerfile dan shell scripts awalnya ditulis untuk **Google Cloud Run + docker-compose (Oracle VM)**.
Sekarang deployment target adalah **Fly.io** — ada beberapa penyesuaian yang sudah dan belum dilakukan.

---

## Struktur Docker

```
backend/
├── Dockerfile              # FrankenPHP — image utama (API + Reverb pakai ini)
├── .docker/
│   ├── start.sh            # Entry point API (FrankenPHP + artisan cache)
│   ├── reverb.sh           # Entry point Reverb WebSocket
│   └── worker.sh           # Entry point Queue Worker (belum dipakai di Fly.io)
├── fly.toml                # Config Fly.io untuk API
└── fly.reverb.toml         # Config Fly.io untuk Reverb
```

---

## Yang Perlu Diketahui Tentang Shell Scripts

### `.docker/start.sh` — untuk API
```sh
php artisan config:cache
php artisan route:cache
php artisan event:cache
php artisan view:cache
exec frankenphp run --config /etc/caddy/Caddyfile
```
- Port dikontrol via env `SERVER_NAME` atau `PORT`
- **Migration TIDAK dijalankan di sini** — harus manual via CLI setelah deploy

### `.docker/reverb.sh` — untuk Reverb
```sh
php artisan config:cache
php artisan route:cache
php artisan event:cache
exec php artisan reverb:start --host=0.0.0.0 --port=8080
```
- Selalu listen di `0.0.0.0:8080`
- Fly.io terminate SSL di edge — Reverb tidak perlu handle HTTPS

### `.docker/worker.sh` — Queue Worker
```sh
exec php artisan queue:work --tries=3 --max-time=3600 --sleep=3
```
- Belum dipakai di Fly.io (QUEUE_CONNECTION=sync untuk sekarang)
- Aktifkan nanti kalau butuh async jobs

---

## Fly.io Setup — 2 App

### App 1: `mangansage-api` (Laravel API)

**`fly.toml`:**
```toml
app = "mangansage-api"
primary_region = "sin"

[build]
  dockerfile = "Dockerfile"

[env]
  SERVER_NAME = ":8080"
  APP_ENV = "production"
  APP_DEBUG = "false"
  APP_URL = "https://mangansage-api.fly.dev"
  DB_CONNECTION = "pgsql"
  DB_PORT = "5432"
  DB_SSLMODE = "require"
  BROADCAST_CONNECTION = "reverb"
  REVERB_HOST = "mangansage-reverb.fly.dev"
  REVERB_PORT = "443"
  REVERB_SCHEME = "https"
  QUEUE_CONNECTION = "sync"
  CACHE_STORE = "file"
  SESSION_DRIVER = "file"

[http_service]
  internal_port = 8080
  force_https = true
  auto_stop_machines = "stop"
  auto_start_machines = true
  min_machines_running = 0      # boleh sleep — API stateless

  [http_service.concurrency]
    type = "requests"
    hard_limit = 100
    soft_limit = 80

[[vm]]
  memory = "256mb"
  cpu_kind = "shared"
  cpus = 1
```

**CMD yang dipakai:** `/start.sh` (default dari Dockerfile)

---

### App 2: `mangansage-reverb` (WebSocket)

**`fly.reverb.toml`:**
```toml
app = "mangansage-reverb"
primary_region = "sin"

[build]
  dockerfile = "Dockerfile"       # pakai Dockerfile yang sama

[env]
  SERVER_NAME = ":8080"
  APP_ENV = "production"
  APP_DEBUG = "false"
  DB_CONNECTION = "pgsql"
  DB_PORT = "5432"
  DB_SSLMODE = "require"
  BROADCAST_CONNECTION = "reverb"
  REVERB_HOST = "0.0.0.0"
  REVERB_PORT = "8080"
  REVERB_SCHEME = "http"
  QUEUE_CONNECTION = "sync"
  CACHE_STORE = "file"
  SESSION_DRIVER = "file"

[http_service]
  internal_port = 8080
  force_https = true
  auto_stop_machines = "stop"
  auto_start_machines = true
  min_machines_running = 1      # WAJIB 1 — WebSocket harus selalu hidup

  [http_service.concurrency]
    type = "connections"
    hard_limit = 1000
    soft_limit = 800

[[vm]]
  memory = "256mb"
  cpu_kind = "shared"
  cpus = 1
```

**CMD override:** harus jalankan `/reverb.sh` bukan `/start.sh`

Tambahkan di `fly.reverb.toml`:
```toml
[experimental]
  cmd = ["/reverb.sh"]
```

---

## Secrets — Wajib Diset via Fly.io Dashboard / CLI

Jangan taruh nilai ini di `fly.toml` — set via **Fly.io Dashboard → Secrets** atau:

```powershell
fly secrets set APP_KEY="base64:xxx" --app mangansage-api
fly secrets set APP_KEY="base64:xxx" --app mangansage-reverb
```

| Secret | Keterangan |
|---|---|
| `APP_KEY` | Laravel app key — sama untuk kedua app |
| `DB_HOST` | Neon PostgreSQL host |
| `DB_DATABASE` | Nama database Neon |
| `DB_USERNAME` | Username Neon |
| `DB_PASSWORD` | Password Neon |
| `REVERB_APP_ID` | Dari `backend/.env` lokal |
| `REVERB_APP_KEY` | Dari `backend/.env` lokal |
| `REVERB_APP_SECRET` | Dari `backend/.env` lokal |
| `FIREBASE_CREDENTIALS` | Path ke JSON file FCM |

---

## Deploy Commands

```powershell
# Deploy API
cd backend
fly deploy

# Deploy Reverb
fly deploy --config fly.reverb.toml

# Migration — jalankan SETELAH deploy API, pakai direct endpoint Neon (bukan pooler)
fly ssh console --app mangansage-api -C "php artisan migrate --force"

# Cek logs
fly logs --app mangansage-api
fly logs --app mangansage-reverb

# Restart
fly machine restart --app mangansage-api
fly machine restart --app mangansage-reverb
```

---

## Hal yang Jangan Dilakukan

- ❌ Jangan jalankan migration di `start.sh` — lakukan manual via `fly ssh console`
- ❌ Jangan naikkan memory di atas `256mb` tanpa alasan terukur
- ❌ Jangan set `min_machines_running = 0` untuk Reverb — WebSocket akan mati
- ❌ Jangan pakai Neon pooler endpoint untuk migration — pakai direct endpoint
- ❌ Jangan commit `.env` atau secrets ke GitHub

---

## Healthcheck

API Laravel sudah ada route `/up` bawaan Laravel 11+ untuk healthcheck.
Dockerfile sudah set HEALTHCHECK ke endpoint ini — tidak perlu diubah.

---

## Database

- **Server:** Neon PostgreSQL (serverless)
- **Lokal Flutter:** SQLite via sqflite
- **Migration:** manual via `fly ssh console` — tidak otomatis saat deploy
- **Neon endpoint:** gunakan **direct connection** (bukan pooler) untuk migration DDL
