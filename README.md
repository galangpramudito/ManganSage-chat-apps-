# Mangansage

Aplikasi real-time chat — minimalis, iMessage-like, Flutter + Laravel.

> Spesifikasi lengkap: [`technical-spec.md`](./technical-spec.md) · [`design-spec.md`](./design-spec.md)
> Dokumentasi fitur baru: [`EMAIL_VERIFICATION.md`](./EMAIL_VERIFICATION.md) · [`PASSWORD_RESET.md`](./PASSWORD_RESET.md)

---

## ⚠️ Status Production (29 Mei 2026)

Cloud Run service **mangansage-api** saat ini balikin **HTTP 503** karena billing GCP project `galangpramudito-496322` di-disable. Aktifkan billing di [GCP Billing Console](https://console.cloud.google.com/billing/linkedaccount?project=galangpramudito-496322) untuk pulih. Pakai backend lokal sementara (lihat [Dev Lokal](#dev-lokal)).

---

## Quick Start

```powershell
cd app
flutter pub get
flutter run
```

Default-nya pakai backend Cloud Run (`https://mangansage-api-722613562569.asia-southeast1.run.app`). Login dengan user seeded di Neon: `andi@mangansage.test` / `password123`.

WebSocket realtime non-aktif by default — banner "Tidak tersambung" akan tampil di ChatRoom; REST tetap jalan (pull-to-refresh untuk update). Untuk realtime, jalankan Reverb lokal + override URL (lihat [Dev Lokal](#dev-lokal)).

---

## 🆕 What's New — Step 9: Email Verification, Password Reset & Profile Management

### Email Verification dengan OTP
- Register → OTP 6-digit dikirim ke email (berlaku 10 menit)
- Login diblokir (HTTP 403) sampai email diverifikasi (`requires_verification: true` di response)
- Endpoint baru:
  - `POST /api/verify-email` — verifikasi OTP, return `{ user, token }`
  - `POST /api/resend-verification` — kirim ulang OTP (throttle 3/10 menit)
- Welcome email otomatis dikirim setelah verifikasi sukses

### Password Reset Flow (OTP via email)
- 3-step: minta OTP → verifikasi → reset password
- Endpoint:
  - `POST /api/forgot-password` — kirim OTP (anti-enumeration: selalu return sukses, throttle 3/10 menit)
  - `POST /api/verify-otp` — return `reset_token` (throttle 10/5 menit)
  - `POST /api/reset-password` — set password baru + revoke semua Sanctum token (throttle 5/5 menit)
- OTP di-hash bcrypt di tabel `password_reset_otps`
- One-time use (`used_at` di-mark setelah reset)
- Setup SMTP: lihat [`backend/MAIL_SETUP.md`](./backend/MAIL_SETUP.md)

### Profile Management
- Endpoint:
  - `GET /api/profile`
  - `PUT /api/profile` — update name/email/avatar (multipart, max 2MB image)
  - `DELETE /api/profile/avatar`
- Email change wajib re-verifikasi
- Avatar disimpan di `storage/app/public/avatars/`

### Admin Panel (Web)
- Resource controller `Admin\UserManagementController` di `routes/web.php`
- Akses via `http://localhost:8000/admin/users`
- CRUD user dasar (untuk dev/admin tooling)

### Flutter Screens Baru
- `splash_screen.dart` — animasi logo 2.8 detik (paralel dengan auth validation)
- `forgot_password_screen.dart` — input email
- `otp_verification_screen.dart` — input OTP 6-digit (dipakai untuk email-verification & password-reset, dibedakan via `isEmailVerification` flag)
- `reset_password_screen.dart` — input password baru
- `edit_profile_screen.dart` — edit name + avatar upload + delete avatar

### Konsol Tools (Dev)
- `php artisan otp:show` — tampilkan OTP terakhir di log (testing tanpa SMTP)
- `php artisan email:test` — kirim test email

---

## Endpoint Reference (Full)

```
Public
  POST   /api/register                       { name, email, password, password_confirmation } → { message, email }
  POST   /api/verify-email                   { email, otp }                                   → { user, token }
  POST   /api/resend-verification            { email }                                        → { message }
  POST   /api/login                          { email, password }                              → { user, token } | 403
  POST   /api/forgot-password                { email }                                        → { message }
  POST   /api/verify-otp                     { email, otp }                                   → { reset_token }
  POST   /api/reset-password                 { reset_token, password, password_confirmation } → { message }

Protected (auth:sanctum)
  POST   /api/logout
  GET    /api/user
  GET    /api/profile
  PUT    /api/profile                        (multipart: name?, email?, avatar?)
  DELETE /api/profile/avatar
  POST   /api/user/fcm-token                 { token }
  GET    /api/users
  GET    /api/conversations
  POST   /api/conversations                  { user_id }
  DELETE /api/conversations/{id}
  GET    /api/conversations/{id}/messages?page=1&per_page=20
  POST   /api/conversations/{id}/messages    { body }
  POST   /api/conversations/{id}/read
  POST   /api/broadcasting/auth              (untuk subscribe Reverb private channel)
```

---

## Tech Stack

| Layer | Tech |
|---|---|
| UI | Flutter 3.44 + Riverpod 3 + Freezed |
| HTTP | Dio + AuthInterceptor |
| Real-time | Laravel Reverb + WebSocket (Pusher protocol via `web_socket_channel`) |
| Auth | Laravel Sanctum + Email OTP verification |
| Email | Laravel Mail (SMTP / log driver di dev) |
| Storage lokal | sqflite + flutter_secure_storage |
| Notifikasi | Firebase Cloud Messaging (graceful fallback kalau tidak dikonfigurasi) |
| Routing | GoRouter dengan redirect guard |
| Backend | Laravel 13 + PHP 8.3 |
| Database | Neon Postgres (cloud) / SQLite (lokal opsional) |
| Deploy | Cloud Run (FrankenPHP) di `asia-southeast1` |

---

## Test Status

```
Backend  : 59 passed, 3 failed (183 assertions)
Flutter  : 13 passed
Analyze  : 0 issues
```

> ⚠️ **3 test gagal di `Tests\Feature\AuthTest`** — fixture-nya belum di-update untuk flow email verification baru. Test berasumsi register langsung balikin `{ user, token }` (perilaku lama), padahal sekarang balikin `{ message, email }` dan login akan balas 403 sampai email diverifikasi. Perlu update factory/seeder untuk set `email_verified=true` di test setup.

Run test:
```powershell
cd backend ; php artisan test
cd app ; flutter test
```

---

## Dev Lokal

```powershell
# Terminal 1 — API
cd backend
php artisan serve --host=0.0.0.0 --port=8000

# Terminal 2 — Reverb (kalau perlu real-time)
cd backend
php artisan reverb:start --host=0.0.0.0 --port=8080

# Terminal 3 — Flutter

# Android emulator
cd app
flutter run `
  --dart-define=API_BASE_URL=http://10.0.2.2:8000/api `
  --dart-define=REVERB_HOST=10.0.2.2 `
  --dart-define=REVERB_PORT=8080 `
  --dart-define=REVERB_APP_KEY=sblfi7mbcspn5nlttzpx

# Real device (ganti 192.168.100.13 dengan IP LAN laptop)
flutter run -d <DEVICE_ID> `
  --dart-define=API_BASE_URL=http://192.168.100.13:8000/api `
  --dart-define=REVERB_HOST=192.168.100.13 `
  --dart-define=REVERB_PORT=8080 `
  --dart-define=REVERB_APP_KEY=sblfi7mbcspn5nlttzpx
```

> `network_security_config.xml` sudah whitelist `localhost`, `10.0.2.2`, dan `192.168.100.13` untuk cleartext HTTP. IP LAN beda? Edit `app/android/app/src/main/res/xml/network_security_config.xml`.
>
> Production traffic ke Cloud Run otomatis HTTPS — cleartext whitelist tidak berdampak ke production.

### Setup Email Lokal (untuk testing OTP)

Default `MAIL_MAILER=log` — OTP otomatis tertulis di `backend/storage/logs/laravel.log`. Cek cepat:

```powershell
cd backend
php artisan otp:show
```

Untuk SMTP real, lihat [`backend/MAIL_SETUP.md`](./backend/MAIL_SETUP.md).

---

## Re-deploy Backend

```powershell
cd Z:\PROJECTS\VsCode\Mangansage
$tag = 'asia-southeast1-docker.pkg.dev/galangpramudito-496322/mangansage/backend:latest'
gcloud builds submit --tag $tag backend
gcloud run deploy mangansage-api --image $tag --region asia-southeast1
```

Atau pakai shortcut:
```powershell
.\deploy.bat
```

Setelah edit migration:
```powershell
cd backend
# Pakai endpoint Neon DIRECT (tanpa -pooler) untuk DDL
php artisan migrate --force
# Lalu rebuild & redeploy
```

Update env var saja (tanpa rebuild):
```powershell
gcloud run services update mangansage-api --region asia-southeast1 `
  --env-vars-file backend\.docker\local.env.yaml
```

---

## Production Endpoint

```
API:    https://mangansage-api-722613562569.asia-southeast1.run.app
Region: asia-southeast1 (Singapore)
DB:     Neon Postgres (ap-southeast-1)
```

Schema migrated, 3 user seeded (`andi@`, `budi@`, `citra@mangansage.test` — password `password123`). User seeded sudah di-flag `email_verified=true` jadi bisa langsung login.

---

## Struktur Proyek

```
Mangansage/
├── README.md                 # ← file ini
├── technical-spec.md         # spec teknis
├── design-spec.md            # spec desain
├── EMAIL_VERIFICATION.md     # detail flow email verification
├── PASSWORD_RESET.md         # detail flow password reset
├── JANGAN-FIREBASE.md        # aturan: Firebase HANYA untuk FCM
├── deploy.bat                # shortcut deploy ke Cloud Run
├── logo_mangansage.png
│
├── app/                      # Flutter (Android & iOS)
│   ├── lib/
│   │   ├── core/             # constants, network, router, theme, websocket, notifications
│   │   ├── features/
│   │   │   ├── auth/         # login, register, splash, forgot/reset password, OTP, edit profile
│   │   │   ├── conversations/
│   │   │   ├── home/
│   │   │   ├── messages/
│   │   │   ├── profile/
│   │   │   └── users/
│   │   └── shared/           # models (freezed), widgets, utils
│   ├── android/
│   └── ios/
│
└── backend/                  # Laravel 13 (API + Reverb + FCM + Mail)
    ├── app/
    │   ├── Console/Commands/ # otp:show, email:test
    │   ├── Events/           # MessageSent, MessageMarkedRead
    │   ├── Http/
    │   │   ├── Controllers/
    │   │   │   ├── Auth/     # AuthController, PasswordResetController
    │   │   │   ├── Admin/    # UserManagementController (web)
    │   │   │   ├── ConversationController, MessageController, UserController
    │   │   │   ├── ProfileController, FcmTokenController
    │   │   ├── Requests/
    │   │   └── Resources/
    │   ├── Listeners/        # SendFcmOnMessageSent
    │   ├── Mail/             # VerificationOtpMail, WelcomeMail, OtpMail, PasswordResetOtpMail
    │   └── Models/           # User, Conversation, Message, MessageRead, PasswordResetOtp
    ├── routes/
    │   ├── api.php           # mobile API
    │   ├── web.php           # admin panel + dev test routes
    │   └── channels.php
    ├── database/migrations/
    ├── tests/
    ├── Dockerfile            # FrankenPHP image untuk Cloud Run
    ├── MAIL_SETUP.md
    └── .docker/
        ├── start.sh
        └── local.env.yaml    # gitignored — env vars Cloud Run
```

---

## Codegen (Flutter)

Setelah membuat model dengan `@freezed` atau provider dengan `@riverpod`:

```powershell
cd app
dart run build_runner build --delete-conflicting-outputs
```

---

## Reset DB & Seed Ulang

```powershell
cd backend
php artisan migrate:fresh --seed
```

Seeder akan generate 3 user dummy yang sudah `email_verified=true` (siap login).

---

## Roadmap & Known Issues

### To Do
- [ ] Update `Tests\Feature\AuthTest` untuk flow email verification baru (3 test gagal saat ini)
- [ ] Animasi transisi pesan baru (slide up + fade)
- [ ] Search bar collapse-on-scroll di Inbox
- [ ] Presence channel (status online realtime via Reverb)
- [ ] Push notif scheduling (kalau pakai queue worker)
- [ ] Re-aktivasi billing GCP untuk pulihkan production endpoint

### Trade-offs Saat Ini
- Listener `SendFcmOnMessageSent` sync (bukan `ShouldQueue`) — sederhana untuk dev, ~100-200ms FCM call. Production: switch ke `ShouldQueue` + `queue:work`.
- Event broadcast pakai `ShouldBroadcastNow` — sama alasannya.
- DIY Pusher protocol di Flutter (`pusher_channels_flutter` 2.6.0 tidak expose `wsHost`/`wsPort`). Trade-off: kontrol penuh, tapi reconnect/ping-pong/subscribe lifecycle jadi tanggung jawab kita.
- Skip foreground FCM notif kalau user di chat aktif (cek `activeConversationProvider`) — WebSocket sudah munculin pesan langsung, notif tambahan jadi noise.

---

## Riwayat Step Build

<details>
<summary>Step 1 — Technical Setup ✅</summary>

- Scaffold Flutter + Laravel
- Install Sanctum, Reverb, kreait/laravel-firebase
- Design tokens, avatar widget deterministik 10-color, folder architecture
</details>

<details>
<summary>Step 2 — Database Schema ✅</summary>

- Migration: users (`avatar`, `is_online`, `last_seen`, `fcm_token`)
- `conversations`, `conversation_user` (soft-delete sepihak), `messages`, `message_reads`
- Eloquent models + relationships, seeder 3 user dummy
</details>

<details>
<summary>Step 3 — Auth API ✅</summary>

- Register, login, logout, /api/user (12 test passing)
- (Step 9 menambahkan email verification — fixture test perlu update)
</details>

<details>
<summary>Step 4 — Flutter Auth Flow ✅</summary>

- AuthNotifier (`AsyncNotifier<User?>`) + GoRouter redirect guard
- AuthInterceptor (clear sesi pada 401 mid-session)
- LoginScreen, RegisterScreen, InboxScreen placeholder
</details>

<details>
<summary>Step 5 — Users + Conversations + Messages + FCM Token ✅</summary>

- UserController, ConversationController (firstOrCreate-style + soft-delete sepihak)
- MessageController (pagination 20/page, mark-as-read idempotent)
- FcmTokenController, Form Requests, Resources
- 45 test, 165 assertion
</details>

<details>
<summary>Step 6 — WebSocket Realtime ✅</summary>

- Backend: `MessageSent` + `MessageMarkedRead` events (ShouldBroadcastNow), `routes/channels.php`, `/api/broadcasting/auth`
- Flutter: `RealtimeService` DIY Pusher protocol via `web_socket_channel`, auto-reconnect exponential backoff
- Banner "Menghubungkan ulang…" di ChatRoom
</details>

<details>
<summary>Step 7 — FCM Push Notifications ✅</summary>

- Backend: `SendFcmOnMessageSent` listener (graceful fallback, clear stale token on NotFound)
- Flutter: `FcmService` foreground/background/tap handlers, `flutter_local_notifications`
- Default `FIREBASE_ENABLED=false` — graceful tanpa `google-services.json`
- Core library desugaring fix di `android/app/build.gradle.kts`
</details>

<details>
<summary>Step 8 — Flutter UI ✅</summary>

- StatefulShellRoute (Inbox, Users, Profile) + ChatRoom di luar shell
- Models Freezed, providers Riverpod 3 (AsyncNotifier + family)
- Widget: ConversationTile, UserTile, MessageBubble (smart corner radius + ✓✓), ChatInputBar, EmptyState
- Util: TimestampFormat (Inbox: HH.mm / Kemarin / nama hari / dd MMM / dd MMM yyyy)
</details>

**Step 9 — Email Verification + Password Reset + Profile + Admin ✅** (lihat [What's New](#-whats-new--step-9-email-verification-password-reset--profile-management) di atas)

---

## Catatan Font

`AppTypography` mereferensikan family `Inter`. File font belum di-bundle ke assets — Flutter fallback ke font sistem. Untuk visual sesuai spec, unduh [Inter](https://rsms.me/inter/), letakkan di `app/assets/fonts/`, lalu daftarkan di `pubspec.yaml` di `flutter.fonts`.
