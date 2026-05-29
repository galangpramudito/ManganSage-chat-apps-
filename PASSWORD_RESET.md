# Password Reset dengan OTP Email

## Backend (Laravel) ✅

### Endpoints

```
POST /api/forgot-password
  Body: { "email": "user@example.com" }
  Response: { "message": "Kode OTP telah dikirim ke email Anda." }
  Rate limit: 3 request per 10 menit per IP

POST /api/verify-otp
  Body: { "email": "user@example.com", "otp": "123456" }
  Response: { "reset_token": "abc123..." }
  Rate limit: 10 request per 5 menit per IP

POST /api/reset-password
  Body: { 
    "reset_token": "abc123...",
    "password": "newpassword",
    "password_confirmation": "newpassword"
  }
  Response: { "message": "Password berhasil direset. Silakan login dengan password baru." }
  Rate limit: 5 request per 5 menit per IP
```

### Database

Tabel `password_reset_otps`:
- `email` — email user
- `otp_hash` — hash bcrypt dari OTP 6-digit
- `reset_token` — token untuk step reset password (di-set setelah OTP verified)
- `expires_at` — OTP berlaku 10 menit
- `used_at` — timestamp saat password berhasil direset

### Email

OTP dikirim via `App\Mail\OtpMail` dengan template `resources/views/emails/otp.blade.php`.

Default mail driver: `log` (cek `storage/logs/laravel.log` untuk testing).

Production: set `MAIL_MAILER=smtp` di `.env` + konfigurasi SMTP credentials.

### Security

- **Anti-enumeration**: endpoint `/forgot-password` selalu return sukses meskipun email tidak terdaftar
- **OTP hashed**: OTP disimpan sebagai bcrypt hash, bukan plaintext
- **Rate limiting**: throttle per IP untuk mencegah spam
- **Token revocation**: reset password otomatis logout dari semua device (revoke semua Sanctum token)
- **One-time use**: OTP di-mark `used_at` setelah password direset

### Testing

```bash
cd backend
php artisan test --filter=PasswordResetTest
```

6 test cases:
- ✅ Forgot password sends OTP
- ✅ Anti-enumeration (email tidak terdaftar tetap return sukses)
- ✅ Verify OTP success
- ✅ Verify OTP invalid
- ✅ Reset password success
- ✅ Reset password revokes all tokens

---

## Flutter ✅

### Screens

1. **ForgotPasswordScreen** (`/forgot-password`)
   - Input email
   - Kirim OTP ke email

2. **OtpVerificationScreen** (`/verify-otp`)
   - 6 kotak input OTP dengan auto-focus
   - Tombol "Kirim ulang OTP"
   - Validasi OTP di backend

3. **ResetPasswordScreen** (`/reset-password`)
   - Input password baru + konfirmasi
   - Submit dengan reset_token dari step sebelumnya

### Flow

```
LoginScreen
  ↓ tap "Lupa password?"
ForgotPasswordScreen (input email)
  ↓ OTP sent
OtpVerificationScreen (input 6-digit)
  ↓ OTP verified → get reset_token
ResetPasswordScreen (input new password)
  ↓ success
LoginScreen (login dengan password baru)
```

### API Integration

File: `app/lib/features/auth/data/auth_api.dart`

```dart
Future<String> forgotPassword(String email)
Future<String> verifyOtp({required String email, required String otp})
Future<String> resetPassword({
  required String resetToken,
  required String password,
  required String passwordConfirmation,
})
```

### Routes

Public routes (accessible tanpa login):
- `/forgot-password`
- `/verify-otp`
- `/reset-password`

Sudah dikonfigurasi di `app/lib/core/router/app_router.dart`.

---

## Testing End-to-End

### 1. Start Laravel server

```bash
cd backend
php artisan serve
```

### 2. Run Flutter app

```bash
cd app
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

### 3. Test flow

1. Buka app → tap "Lupa password?" di login screen
2. Masukkan email user yang terdaftar (mis. `andi@mangansage.test`)
3. Cek `backend/storage/logs/laravel.log` untuk melihat OTP yang dikirim
4. Copy OTP 6-digit dari log
5. Paste di OTP verification screen
6. Set password baru
7. Login dengan password baru

---

## Production Checklist

- [ ] Set `MAIL_MAILER=smtp` di `.env`
- [ ] Konfigurasi SMTP credentials (Gmail, SendGrid, Mailgun, dll)
- [ ] Test kirim email real (bukan log)
- [ ] Monitor rate limiting di production
- [ ] Setup cron job untuk cleanup OTP expired (opsional):
  ```php
  // app/Console/Kernel.php
  $schedule->call(function () {
      DB::table('password_reset_otps')
        ->where('expires_at', '<', now()->subDay())
        ->delete();
  })->daily();
  ```
