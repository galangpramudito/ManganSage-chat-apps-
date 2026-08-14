# 🚀 Mangan Group Mobile App - In-App Auto Update & Release System

Dokumentasi lengkap sistem update otomatis (CI/CD) untuk aplikasi Flutter **Mangan Group**. Sistem ini memungkinkan developer merilis update aplikasi (perombakan UI, logic, routing, dependensi, hingga kode native) hanya dengan melakukan `git push tag`. Pengguna akan menerima notifikasi update langsung di dalam aplikasi dan mengunduhnya secara otomatis.

---

## 📋 Daftar Isi

1. [Cara Kerja Sistem (Architecture)](#-cara-kerja-sistem)
2. [Langkah Rilis Versi Baru (Quick Cheatsheet)](#-langkah-rilis-versi-baru-30-detik)
3. [Mengapa Semua Perubahan Pasti Ter-update?](#-mengapa-semua-perubahan-pasti-ter-update)
4. [Konfigurasi & Komponen Utama](#-konfigurasi--komponen-utama)
5. [Aturan Penting (Best Practices)](#-aturan-penting-best-practices)
6. [Troubleshooting & Solusi Kendala](#-troubleshooting--solusi-kendala)

---

## 🎯 Cara Kerja Sistem

```
[Developer]
    │
    ▼ (1. Bump version di pubspec.yaml & git tag vX.Y.Z)
[GitHub Repository]
    │
    ▼ (2. Trigger GitHub Actions CI/CD)
[GitHub Actions Runner]
    ├─► Build Flutter APK (flutter build apk --release)
    ├─► Hitung SHA-256 Checksum file APK
    ├─► Upload `app-release.apk` ke GitHub Releases (Storage Unlimited)
    └─► Daftarkan metadata rilis ke tabel Supabase `app_releases`
           │
           ▼
[Supabase Database (`app_releases`)]
    │
    ▼ (3. Aplikasi user mendeteksi `build_number` baru)
[Flutter App (User)]
    ├─► Muncul dialog update otomatis / cek via menu Profil
    ├─► Unduh `app-release.apk` dari GitHub CDN
    ├─► Verifikasi integritas APK dengan SHA-256 Checksum
    └─► Buka Android Package Installer untuk menimpa instalasi lama
```

---

## ⚡ Langkah Rilis Versi Baru (30 Detik)

Setiap kali ada fitur baru atau perbaikan bug yang ingin disebarkan ke user/teman:

### 1. Naikkan Versi di `app/pubspec.yaml`
Buka [pubspec.yaml](file:///z:/PROJECTS/VsCode/MANGAN%20GROUP/app%20project/app/pubspec.yaml), ubah baris `version`:
```yaml
# Format: version: <version_name>+<build_number>
# CONTOH:
version: 1.2.9+12  # Naikkan X.Y.Z dan WAJIB naikkan angka build number (+12)
```

### 2. Commit & Push Tag ke GitHub
Jalankan perintah berikut di terminal:
```powershell
cd "Z:\PROJECTS\VsCode\MANGAN GROUP\app project"

# 1. Simpan perubahan kode
git add .
git commit -m "feat: deskripsi perubahan update"
git push origin main

# 2. Buat tag baru (sesuai versi di pubspec) dan push
git tag v1.2.9
git push origin v1.2.9
```

### 3. Selesai! ✅
- GitHub Actions akan otomatis melakukan build (memerlukan waktu ~5-8 menit).
- Pantau status build: 👉 [GitHub Actions Runs](https://github.com/galangpramudito/ManganSage-chat-apps-/actions)
- Setelah sukses (hijau), semua user yang membuka aplikasi versi lama akan langsung mendapat notifikasi update.

---

## 💡 Mengapa Semua Perubahan Pasti Ter-update?

Sistem ini menggunakan metode **Full Binary Replacement (In-Place Upgrade)**:
- **Kompilasi Penuh:** GitHub Actions mengompilasi ulang seluruh project Flutter dari awal (`flutter build apk --release`).
- **Mendukung Segala Perubahan:**
  - ✅ Perubahan UI / Layout / Assets / Font
  - ✅ Perombakan Struktur Routing (`go_router`)
  - ✅ Penambahan dependensi paket baru di `pubspec.yaml`
  - ✅ Penambahan atau perubahan permission native Android
  - ✅ Update logic Riverpod / State Management
- **Data User Tetap Aman:** Saat Android menimpa file APK lama dengan APK baru, sesi login dan storage lokal user tetap tersimpan.

---

## 🔧 Konfigurasi & Komponen Utama

### 1. GitHub Actions Workflow
File: [release-apk.yml](file:///z:/PROJECTS/VsCode/MANGAN%20GROUP/app%20project/.github/workflows/release-apk.yml) *(Wajib berada di root repository `/.github/workflows/`)*.

Poin penting di workflow:
- Path file upload ke release: `app/build/app/outputs/flutter-apk/app-release.apk`
- Menggunakan `curl -f` untuk memastikan workflow gagal jika ada kendala koneksi ke database Supabase.
- Nama file asset yang dirilis: `app-release.apk`.

### 2. GitHub Secrets yang Wajib Ada
Disetel di: **Settings > Secrets and variables > Actions**
| Nama Secret | Deskripsi / Nilai |
|---|---|
| `SUPABASE_URL` | URL project Supabase (`https://vcsvbeepbzmcfnwapqog.supabase.co`) |
| `SUPABASE_SERVICE_ROLE_KEY` | Secret Key Supabase (`sb_secret_...`) untuk insert ke tabel rilis |
| `SUPABASE_ANON_KEY` | Anon Key Supabase untuk build aplikasi |
| `GOOGLE_SERVICES_JSON` | Konten lengkap file `google-services.json` Firebase |

### 3. Service di Aplikasi Flutter
- **[app_updater_service.dart](file:///z:/PROJECTS/VsCode/MANGAN%20GROUP/app%20project/app/lib/core/updater/app_updater_service.dart):** Bertanggung jawab mengecek rilis tertinggi di tabel `app_releases`, mengunduh APK via `Dio`, memicu verifikasi checksum, dan membuka installer via `open_filex`.
- **[checksum_verifier.dart](file:///z:/PROJECTS/VsCode/MANGAN%20GROUP/app%20project/app/lib/core/updater/checksum_verifier.dart):** Menghitung hash SHA-256 file yang terunduh dan mencocokkannya dengan `sha256_checksum` dari database untuk menjamin keamanan file.

---

## ⚠️ Aturan Penting (Best Practices)

1. **Build Number Wajib Selalu Bertambah:**
   Android dan logika aplikasi membandingkan `build_number` (angka setelah tanda `+`). Jika versi saat ini `+11`, versi berikutnya harus `+12` atau lebih tinggi.
2. **Format Tag Harus Menggunakan Huruf `v`:**
   Trigger GitHub Actions membutuhkan format `v*.*.*` (contoh: `v1.2.9`, `v2.0.0`).
3. **Jangan Mengubah Keystore / Signature:**
   Android hanya mengizinkan update menimpa aplikasi lama jika kedua APK menggunakan signature key yang sama.
4. **Hanya Edit Workflow di Root:**
   Jangan membuat atau mengedit file workflow di dalam subfolder `app/.github/...`, karena GitHub hanya mengeksekusi workflow dari root direktori repo.

---

## 🐛 Troubleshooting & Solusi Kendala

| Gejala Masalah | Penyebab | Solusi |
|---|---|---|
| **Aplikasi unduh file HTML / 404 Not Found** | Nama file di GitHub Release tidak cocok dengan URL di Supabase. | Pastikan workflow mengupload file `app-release.apk` dan URL di database menunjuk ke file tersebut. |
| **Gagal verifikasi integritas APK** | File APK korup atau URL mengembalikan respon error 404 (HTML). | Periksa apakah file APK benar-benar ada di tab Assets pada rilis GitHub terkait. |
| **Workflow sukses tapi database tidak ter-update** | Secret `SUPABASE_SERVICE_ROLE_KEY` kedaluwarsa / salah. | Perbarui secret di GitHub Actions dengan secret key (`sb_secret_...`) yang masih aktif dari Dashboard Supabase. |
| **Workflow tidak jalan setelah push tag** | Format tag salah atau tag sudah pernah ada. | Pastikan tag diawali huruf `v` (misal `v1.2.9`). Jika tag pernah dibuat, hapus dulu tag lokal & remote atau gunakan nomor versi baru. |

---

*Dokumentasi diperbarui: Agustus 2026*
