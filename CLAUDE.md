# CLAUDE.md — Mangansage Project Context
> Baca file ini sebelum melakukan apapun. Ini adalah sumber kebenaran project.

---

## Apa ini?

**Mangansage** — aplikasi real-time chat, minimalis iMessage-like.
- Frontend: Flutter (Android & iOS)
- Backend: Laravel 13 + PHP 8.3
- Spesifikasi lengkap: `technical-spec.md`, `design-spec.md`, `JANGAN-FIREBASE.md`

---

## Struktur Project

```
Mangansage/
├── CLAUDE.md               # file ini
├── technical-spec.md       # spesifikasi teknis lengkap
├── design-spec.md          # spesifikasi desain lengkap
├── JANGAN-FIREBASE.md      # larangan penggunaan Firebase berlebihan
├── deploy-guide-flyio.md   # panduan deploy ke Fly.io
├── app/                    # Flutter
└── backend/                # Laravel
```

---

## Tech Stack

| Layer | Tech |
|---|---|
| UI | Flutter 3.44 + Riverpod 3 + Freezed |
| HTTP | Dio + AuthInterceptor |
| Real-time | Laravel Reverb + WebSocket (DIY Pusher protocol) |
| Auth | Laravel Sanctum |
| Storage lokal | sqflite + flutter_secure_storage |
| Notifikasi | Firebase Cloud Messaging (FCM) — **hanya untuk push notif background** |
| Routing | GoRouter |
| Backend | Laravel 13 + PHP 8.3 |
| Database server | Neon (PostgreSQL serverless) |
| Database lokal | SQLite via sqflite |
| Deploy | Fly.io (2 app: `mangansage-api` + `mangansage-reverb`) |
| Container | FrankenPHP (Caddy + PHP, single Dockerfile untuk API & Reverb) |

---

## Aturan Penting — Wajib Diikuti

### ❌ Jangan lakukan ini
- Jangan pakai Firestore / Firebase Realtime DB / Firebase Auth / Firebase Storage
- Jangan pakai polling — semua real-time via WebSocket Reverb
- Jangan tambah database baru — sudah ada Neon + SQLite lokal
- Jangan upgrade Fly.io machine di luar spec yang sudah ditentukan
- Jangan pakai `laravel_echo` Dart package — sudah di-uninstall, pakai DIY WebSocket
- Jangan pakai `pusher_channels_flutter` — sudah di-uninstall

### ✅ Selalu lakukan ini
- Pakai `web_socket_channel` untuk WebSocket di Flutter
- Pakai `kreait/laravel-firebase` untuk dispatch FCM di backend
- Pakai Riverpod 3 dengan code generation (`@riverpod`)
- Pakai Freezed untuk semua model
- Jalankan `dart run build_runner build --delete-conflicting-outputs` setelah ubah model/provider
- Pakai `--dart-define` untuk environment variables Flutter, jangan hardcode URL

---

## Environment

### Flutter (dart-define)
```
API_BASE_URL=https://mangansage-api.fly.dev/api
REVERB_HOST=mangansage-reverb.fly.dev
REVERB_PORT=443
REVERB_APP_KEY=<dari backend .env>
```

### Laravel Backend
- DB: Neon PostgreSQL — `DB_SSLMODE=require` wajib
- WebSocket: Reverb (`BROADCAST_CONNECTION=reverb`)
- FCM: `FIREBASE_CREDENTIALS=storage/firebase-credentials.json`

---

## Fly.io — 2 App

| App | URL | Fungsi |
|---|---|---|
| `mangansage-api` | `https://mangansage-api.fly.dev` | Laravel API |
| `mangansage-reverb` | `https://mangansage-reverb.fly.dev` | Reverb WebSocket |

**Penting:** `mangansage-reverb` harus selalu `min_machines_running = 1`.
**Penting:** `mangansage-api` boleh sleep (`min_machines_running = 0`).

---

## Status Development

- [x] Step 1: Technical Setup
- [x] Step 2: Database Schema
- [x] Step 3: Auth API
- [x] Step 4: Flutter Auth Flow
- [x] Step 5: Users + Conversations + Messages API
- [x] Step 6: WebSocket Realtime (Reverb)
- [x] Step 7: FCM Push Notifications
- [x] Step 8: Flutter UI
- [ ] Polish: animasi pesan baru, search-bar collapse, edit profil, presence channel

---

## Test

```powershell
# Backend
cd backend
php artisan test
# Expected: 56 passed, 187 assertions

# Flutter
cd app
flutter test
# Expected: 13 passed

# Analyze Flutter
flutter analyze
# Expected: 0 issues
```

---

## Run Lokal

```powershell
# Terminal 1 — API
cd backend; php artisan serve

# Terminal 2 — Reverb
cd backend; php artisan reverb:start

# Terminal 3 — Flutter
cd app; flutter run `
  --dart-define=API_BASE_URL=http://10.0.2.2:8000/api `
  --dart-define=REVERB_HOST=10.0.2.2 `
  --dart-define=REVERB_PORT=8080 `
  --dart-define=REVERB_APP_KEY=<dari backend .env>
```

> Android emulator: gunakan `10.0.2.2` untuk localhost.
> iOS simulator: gunakan `localhost`.
> Real device: gunakan IP LAN.

---

## Codegen Flutter

Wajib dijalankan setelah ubah model (`@freezed`) atau provider (`@riverpod`):

```powershell
cd app
dart run build_runner build --delete-conflicting-outputs
```

---

## Deploy ke Fly.io

```powershell
# Deploy API
cd backend
fly deploy

# Deploy Reverb
fly deploy --config fly.reverb.toml

# Migration
fly ssh console --app mangansage-api -C "php artisan migrate --force"

# Logs
fly logs --app mangansage-api
fly logs --app mangansage-reverb
```

Detail lengkap: `deploy-guide-flyio.md`

---

## Konfigurasi Fly.io (TOML) — Hemat Biaya

File TOML ada di `backend/`. **Jangan ubah nilai ini sembarangan.**

> ⚠️ **`Dockerfile.reverb` sudah dihapus.** Reverb pakai Dockerfile yang sama dengan API, tapi CMD di-override via `[experimental] cmd`.

### `backend/fly.toml` — Laravel API
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
  auto_stop_machines = "stop"   # tidur saat tidak ada request
  auto_start_machines = true
  min_machines_running = 0      # boleh 0 — API stateless, aman sleep

  [http_service.concurrency]
    type = "requests"
    hard_limit = 100
    soft_limit = 80

[[vm]]
  memory = "256mb"              # jangan dinaikkan tanpa alasan
  cpu_kind = "shared"
  cpus = 1
```

### `backend/fly.reverb.toml` — Reverb WebSocket
```toml
app = "mangansage-reverb"
primary_region = "sin"

[build]
  dockerfile = "Dockerfile"     # pakai Dockerfile yang SAMA, bukan Dockerfile.reverb

[experimental]
  cmd = ["/reverb.sh"]          # override CMD — jalankan reverb.sh bukan start.sh

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
  REVERB_SCHEME = "http"        # Fly.io handle SSL di edge
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
  memory = "256mb"              # jangan dinaikkan tanpa alasan
  cpu_kind = "shared"
  cpus = 1
```

### Kenapa konfigurasi ini?
- **API sleep (`min_machines_running = 0`)** — Laravel stateless, aman tidur. Bangun otomatis ~1-2 detik saat ada request. Gratis saat idle.
- **Reverb selalu hidup (`min_machines_running = 1`)** — WebSocket butuh koneksi persisten. Kalau tidur, semua client disconnect.
- **Satu Dockerfile untuk keduanya** — Reverb pakai image yang sama, CMD di-override ke `/reverb.sh`.
- **256MB untuk keduanya** — masuk free allowance Fly.io. Total 2 app × 256MB = dalam batas gratis.
- **Jangan scale memory** kecuali ada bottleneck nyata yang terukur.
