# Flutter UI - Email Verification & Profile Management

## ✅ Fitur yang Sudah Diimplementasi

### 1. Email Verification Flow
- **RegisterScreen** → Kirim OTP ke email
- **OtpVerificationScreen** (reuse) → Verifikasi OTP
  - Support 2 mode: email verification & password reset
  - Auto-login setelah verifikasi berhasil
  - Resend OTP button
- **Welcome email** otomatis terkirim setelah verifikasi

### 2. Edit Profile
- **EditProfileScreen** → Edit nama & upload avatar
- **ProfileScreen** → Tombol "Edit Profil"
- Upload foto dari gallery (max 2MB)
- Preview foto sebelum upload
- Auto-update UI setelah save

---

## File Changes

### New Files
```
app/lib/features/auth/screens/edit_profile_screen.dart
app/lib/features/auth/providers/profile_notifier.dart
```

### Modified Files
```
app/lib/features/auth/data/auth_api.dart
  - register() return email (bukan AuthResult)
  - verifyEmail() method baru
  - resendVerification() method baru

app/lib/features/auth/providers/auth_notifier.dart
  - setAuthResult() method baru
  - Hapus register() method

app/lib/features/auth/screens/register_screen.dart
  - Redirect ke /verify-email setelah register

app/lib/features/auth/screens/otp_verification_screen.dart
  - Support isEmailVerification flag
  - Handle 2 flow berbeda (email vs password)

app/lib/core/constants/api_constants.dart
  - verifyEmail, resendVerification, profile, profileAvatar

app/lib/core/router/app_router.dart
  - Route /verify-email

app/lib/features/profile/screens/profile_screen.dart
  - Tombol "Edit Profil"

app/pubspec.yaml
  - image_picker: ^1.0.7
```

---

## User Flow

### Register & Verify
```
1. User tap "Daftar" di RegisterScreen
2. Input nama, email, password
3. Tap "Daftar" → OTP dikirim ke email
4. Redirect ke OtpVerificationScreen
5. Input OTP 6-digit dari email
6. Tap "Verifikasi" → Welcome email terkirim
7. Auto-login → Redirect ke /inbox
```

### Edit Profile
```
1. User buka tab "Profil"
2. Tap "Edit Profil"
3. Ubah nama / upload foto
4. Tap "Simpan"
5. Profile terupdate → Kembali ke ProfileScreen
```

---

## Setup

### 1. Install dependencies
```bash
cd app
flutter pub get
```

### 2. Android permissions (sudah ada)
File `android/app/src/main/AndroidManifest.xml` sudah include:
```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
```

### 3. iOS permissions
Tambahkan ke `ios/Runner/Info.plist`:
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Kami perlu akses galeri untuk upload foto profil</string>
<key>NSCameraUsageDescription</key>
<string>Kami perlu akses kamera untuk foto profil</string>
```

---

## Testing

### 1. Register & Verify
```bash
# Start backend
cd backend
php artisan serve

# Start Flutter
cd app
flutter run
```

1. Tap "Daftar"
2. Isi form → Submit
3. Cek OTP di backend log: `php artisan otp:show`
4. Input OTP di app
5. Verify → Welcome screen muncul

### 2. Edit Profile
1. Login
2. Tab "Profil"
3. Tap "Edit Profil"
4. Ubah nama / upload foto
5. Tap "Simpan"
6. Profile terupdate

---

## Next Steps (Optional)

1. **Email change** - Tambah field email di EditProfileScreen (perlu re-verify)
2. **Crop image** - Pakai `image_cropper` untuk crop foto sebelum upload
3. **Loading state** - Skeleton loading saat upload foto
4. **Error handling** - Better error message untuk upload gagal
5. **Offline mode** - Cache profile data di SQLite

Mau implementasi salah satu dari ini?
