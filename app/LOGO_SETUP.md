# Setup Logo ManganSage

## Langkah-langkah

### 1. Copy logo ke folder assets

```bash
# Buat folder assets kalau belum ada
mkdir app\assets

# Copy file logo_mangansage.png ke app\assets\logo_mangansage.png
```

### 2. Copy logo ke backend (untuk email)

```bash
# Copy juga ke backend public folder
mkdir backend\public\images
copy logo_mangansage.png backend\public\images\logo_mangansage.png
```

### 3. Install dependencies & generate icons

```bash
cd app
flutter pub get
dart run flutter_launcher_icons
```

Output akan generate icon untuk semua resolusi Android & iOS.

### 4. Rebuild app

```bash
flutter clean
flutter pub get
flutter run
```

### 5. Verifikasi

- ✅ Icon app di home screen berubah jadi logo kamu
- ✅ Nama app berubah jadi "ManganSage"
- ✅ Email OTP akan tampil dengan logo di header

---

## Troubleshooting

**Icon tidak berubah?**
```bash
flutter clean
flutter pub get
dart run flutter_launcher_icons
flutter run
```

**Logo email tidak muncul?**
- Pastikan file ada di `backend/public/images/logo_mangansage.png`
- Kalau pakai mail driver `log`, logo tidak akan terlihat (hanya di email real)

