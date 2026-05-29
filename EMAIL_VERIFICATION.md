# Email Verification & Profile Management

## Fitur Baru ✨

### 1. Email Verification dengan OTP
- Register → Kirim OTP 6-digit ke email
- Verifikasi OTP → Akun aktif + Welcome email
- Login diblokir sampai email terverifikasi

### 2. Welcome Email
- Design modern dengan gradient
- Fitur highlight ManganSage
- CTA button ke app

### 3. Edit Profile
- Ubah nama
- Ubah email (perlu verifikasi ulang)
- Upload/hapus avatar

---

## API Endpoints

### Register (Updated)
```
POST /api/register
Body: { "name", "email", "password", "password_confirmation" }

Response 201:
{
  "message": "Akun berhasil dibuat. Silakan cek email untuk verifikasi.",
  "email": "user@example.com"
}
```

**Email OTP dikirim otomatis**

### Verify Email
```
POST /api/verify-email
Body: { "email", "otp" }

Response 200:
{
  "message": "Email berhasil diverifikasi!",
  "user": {...},
  "token": "sanctum_token"
}
```

**Welcome email dikirim otomatis setelah verifikasi**

### Resend OTP
```
POST /api/resend-verification
Body: { "email" }

Response 200:
{
  "message": "Kode OTP baru telah dikirim."
}
```

### Login (Updated)
```
POST /api/login
Body: { "email", "password" }

Response 403 (jika belum verifikasi):
{
  "message": "Email belum diverifikasi. Silakan cek inbox Anda.",
  "email": "user@example.com",
  "requires_verification": true
}

Response 200 (jika sudah verifikasi):
{
  "user": {...},
  "token": "sanctum_token"
}
```

### Get Profile
```
GET /api/profile
Header: Authorization: Bearer {token}

Response 200:
{
  "id": 1,
  "name": "User Name",
  "email": "user@example.com",
  "avatar": "avatars/xxx.jpg",
  "email_verified": true
}
```

### Update Profile
```
PUT /api/profile
Header: Authorization: Bearer {token}
Body (multipart/form-data):
{
  "name": "New Name",           // optional
  "email": "new@example.com",   // optional, perlu verifikasi ulang
  "avatar": <file>              // optional, max 2MB
}

Response 200:
{
  "message": "Profile berhasil diupdate.",
  "user": {...},
  "requires_verification": false  // true jika email berubah
}
```

### Delete Avatar
```
DELETE /api/profile/avatar
Header: Authorization: Bearer {token}

Response 200:
{
  "message": "Avatar berhasil dihapus.",
  "user": {...}
}
```

---

## Email Templates

### 1. Verification OTP (`emails/verification-otp.blade.php`)
- **Design**: Modern gradient (purple-blue)
- **Content**: OTP 6-digit besar, timer 10 menit
- **Security warning**: Jangan share OTP

### 2. Welcome Email (`emails/welcome.blade.php`)
- **Design**: Modern gradient dengan badge
- **Content**: 
  - Welcome message
  - 4 fitur highlight (Chat, Notif, Security, UI)
  - CTA button
  - Social links

### 3. Password Reset OTP (`emails/otp.blade.php`)
- Sudah ada dari fitur sebelumnya

---

## Database Schema

```sql
ALTER TABLE users ADD COLUMN email_verified BOOLEAN DEFAULT FALSE;
ALTER TABLE users ADD COLUMN verification_otp VARCHAR(6);
ALTER TABLE users ADD COLUMN verification_otp_expires_at TIMESTAMP;
```

---

## Testing

### 1. Register & Verify
```bash
# Register
curl -X POST http://localhost:8000/api/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com","password":"password123","password_confirmation":"password123"}'

# Cek email OTP di log
php artisan otp:show

# Verify
curl -X POST http://localhost:8000/api/verify-email \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","otp":"123456"}'
```

### 2. Update Profile
```bash
# Update nama
curl -X PUT http://localhost:8000/api/profile \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{"name":"New Name"}'

# Upload avatar
curl -X PUT http://localhost:8000/api/profile \
  -H "Authorization: Bearer {token}" \
  -F "avatar=@/path/to/image.jpg"
```

---

## Flutter Integration (Next Step)

Perlu update Flutter app untuk:
1. Screen verifikasi OTP setelah register
2. Screen edit profile dengan upload avatar
3. Handle login error 403 (belum verifikasi)
4. Resend OTP button

Mau saya buatkan Flutter UI-nya juga?
