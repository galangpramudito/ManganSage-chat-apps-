# Mail Configuration untuk Mangansage

## Option 1: Log Driver (Default - Easiest for Testing)

**Sudah dikonfigurasi by default**. OTP akan ditulis ke `storage/logs/laravel.log`.

### Testing Flow

1. **Trigger forgot password di Flutter app**:
   - Buka app → tap "Lupa password?"
   - Masukkan email (mis. `andi@mangansage.test`)
   - Tap "Kirim Kode OTP"

2. **Lihat OTP di log**:
   ```bash
   cd backend
   php artisan otp:show
   ```
   
   Output:
   ```
   📧 Latest OTPs from log:
   
     🔑 123456
     🔑 789012
   
   Use the most recent OTP in your Flutter app
   ```

3. **Copy OTP** → paste di Flutter app → lanjut reset password

**Pros**: Tidak perlu setup SMTP, langsung jalan.  
**Cons**: Harus manual cek log untuk dapat OTP.

---

## Option 2: Gmail SMTP (Real Email)

### 1. Buat App Password di Google Account

1. Buka https://myaccount.google.com/security
2. **Enable 2-Step Verification** (wajib untuk app password)
3. Buka https://myaccount.google.com/apppasswords
4. Pilih "Mail" dan "Other (Custom name)" → ketik "Mangansage"
5. Copy **16-digit app password** yang muncul (format: `xxxx xxxx xxxx xxxx`)

### 2. Update `backend/.env`

```env
MAIL_MAILER=smtp
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=your-email@gmail.com
MAIL_PASSWORD=xxxxxxxxxxxxxxxx
MAIL_ENCRYPTION=tls
MAIL_FROM_ADDRESS="noreply@mangansage.app"
MAIL_FROM_NAME="MANGAN"
```

**Ganti**:
- `your-email@gmail.com` → email Gmail kamu
- `xxxxxxxxxxxxxxxx` → 16-digit app password (tanpa spasi)

### 3. Clear config cache & restart

```bash
cd backend
php artisan config:clear
php artisan serve
```

### 4. Test email

```bash
php artisan mail:test your-email@gmail.com
```

Kalau muncul `✅ Email sent successfully!`, cek inbox kamu.

### 5. Test forgot password flow

Buka Flutter app → tap "Lupa password?" → masukkan email → cek inbox untuk OTP.

---

## Alternative: Mailtrap (Testing tanpa kirim email real)

Untuk testing tanpa spam inbox real:

1. Daftar gratis di https://mailtrap.io
2. Buat inbox baru → copy credentials
3. Update `.env`:

```env
MAIL_MAILER=smtp
MAIL_HOST=sandbox.smtp.mailtrap.io
MAIL_PORT=2525
MAIL_USERNAME=your-mailtrap-username
MAIL_PASSWORD=your-mailtrap-password
MAIL_ENCRYPTION=tls
MAIL_FROM_ADDRESS="noreply@mangansage.app"
MAIL_FROM_NAME="MANGAN"
```

Semua email akan masuk ke Mailtrap inbox (tidak ke email real).

---

## Production: SendGrid (Recommended)

SendGrid free tier: 100 email/hari gratis.

1. Daftar di https://sendgrid.com
2. Buat API Key di Settings → API Keys
3. Update `.env`:

```env
MAIL_MAILER=smtp
MAIL_HOST=smtp.sendgrid.net
MAIL_PORT=587
MAIL_USERNAME=apikey
MAIL_PASSWORD=SG.xxxxxxxxxxxxxxxxxxxxxx
MAIL_ENCRYPTION=tls
MAIL_FROM_ADDRESS="noreply@mangansage.app"
MAIL_FROM_NAME="MANGAN"
```

**Note**: `MAIL_USERNAME` harus literal string `apikey`, bukan email kamu.

---

## Troubleshooting

### Error: "Connection could not be established"

- Cek firewall/antivirus tidak block port 587
- Pastikan 2-Step Verification aktif (Gmail)
- Pastikan app password benar (16 digit tanpa spasi)

### Error: "Username and Password not accepted"

- Jangan pakai password Gmail biasa, harus app password
- Regenerate app password baru kalau perlu

### Email masuk spam

- Tambahkan SPF/DKIM record di domain DNS (production)
- Pakai email provider profesional (SendGrid, Mailgun)

### Test via tinker

```bash
php artisan tinker
```

```php
Mail::raw('Test', fn($m) => $m->to('test@example.com')->subject('Test'));
```

