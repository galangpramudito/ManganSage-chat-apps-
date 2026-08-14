# 🚀 Panduan Sistem In-App Auto-Update APK (Mangan Group)

Dokumentasi ini menjelaskan arsitektur, cara kerja, dan langkah operasional untuk mempublikasikan pembaruan aplikasi Flutter **Mangan Group** secara otomatis tanpa melalui Google Play Store.

---

## 📌 1. Cara Kerja Sistem

Aplikasi menggunakan **Supabase** sebagai backend penyimpanan APK dan pencatatan versi:

```
[ Developer ]
      │
      │ Jalankan .\publish_update.ps1
      ▼
1. Build APK (flutter build apk --release)
2. Upload APK ───────► Supabase Storage (Bucket: releases)
3. Insert Version ───► Supabase Table (app_releases)
                              │
                              │
[ Pengguna ]                  │
      │                       ▼
1. Buka Aplikasi ────► Query Supabase (app_releases)
2. Cek Versi          - Apakah build_number server > build_number lokal?
      │
      ├─── TIDAK ────► Lanjut gunakan aplikasi normal
      │
      └─── YA ───────► Tampilkan Dialog Update
                           │
                           ├─── User klik "Update Sekarang"
                           │        │
                           │        ▼
                           │    Download APK ke temporary storage (Progress 0-100%)
                           │        │
                           │        ▼
                           │    Trigger Android Package Installer otomatis
                           │
                           └─── User klik "Nanti" (hanya jika force_update: false)
                                    │
                                    ▼
                                Banner reminder tetap tampil di atas Home Screen
                                + Menu "Periksa Pembaruan" tersedia di Tab Profil
```

---

## ⚙️ 2. Persiapan Awal (Hanya Perlu Dilakukan 1x)

### A. Tabel Database di Supabase
Pastikan tabel `app_releases` sudah dibuat di **Supabase SQL Editor**:

```sql
CREATE TABLE app_releases (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  version TEXT NOT NULL,          -- Contoh: "1.3.0"
  build_number INTEGER NOT NULL,  -- Contoh: 3
  download_url TEXT NOT NULL,     -- URL publik file APK
  release_notes TEXT,             -- Catatan pembaruan
  force_update BOOLEAN DEFAULT FALSE, -- Wajib update atau opsional
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Izinkan semua user membaca rilis
ALTER TABLE app_releases ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can read releases"
  ON app_releases FOR SELECT
  USING (true);
```

### B. Storage Bucket di Supabase
1. Buka **Supabase Dashboard** → **Storage**.
2. Pastikan terdapat bucket bernama **`releases`** dengan status **Public**.

### C. Environment Variable untuk Script Publish
Script otomatisasi membutuhkan `service_role` secret key untuk mengunggah APK dan mencatat data rilis baru.

1. Buka **Supabase Dashboard** → **Project Settings (ikon gerigi)** → **API**.
2. Copy key **`service_role` (secret)**.
3. Di PowerShell, set environment variable (permanen di komputer pengembang):
   ```powershell
   [System.Environment]::SetEnvironmentVariable("SUPABASE_SERVICE_ROLE_KEY", "PASTE_KEY_SERVICE_ROLE_DISINI", "User")
   ```

---

## 📦 3. Cara Mempublikasikan Pembaruan (Rilis Baru)

Setiap kali Anda selesai melakukan perubahan kode dan ingin mengirim pembaruan ke pengguna:

### ⚠️ IMPORTANT: Jalankan Migration Database Dulu (HANYA SEKALI)

Sebelum publish update pertama kali, jalankan migration SQL di Supabase:

1. Buka **Supabase Dashboard** → **SQL Editor**
2. Copy-paste isi file `../../web project/supabase/migrations/20260814000001_create_app_releases_table.sql`
3. Run query
4. Verify: Check tabel `app_releases` sudah ada di **Table Editor**

### Langkah 1: Naikkan Versi di `pubspec.yaml`
Buka file `pubspec.yaml`, lalu ubah `version`:
```yaml
# Format: [versionName]+[versionCode/buildNumber]
version: 1.3.0+3
```
> ⚠️ **Penting:** Angka setelah tanda `+` (*build number*) **harus selalu lebih besar** dari versi sebelumnya agar aplikasi pengguna mendeteksi adanya pembaruan.

### Langkah 2: Jalankan Script Otomatis
Buka terminal PowerShell di folder `app project\app`, lalu jalankan:

```powershell
.\publish_update.ps1
```

Script akan memandu Anda:
1. Menanyakan catatan rilis (*Release Notes*), contoh: `Perbaikan bug match dan sistem notifikasi`.
2. Meng-compile APK release secara otomatis (`flutter build apk --release`).
3. Mengunggah file `mangan-group-1.3.0.apk` ke Supabase Storage.
4. Menambahkan baris rilis baru ke tabel `app_releases`.
5. ✅ **Selesai!** Seluruh pengguna akan langsung menerima pembaruan saat membuka aplikasi.

---

## 🛠️ 4. Variasi Perintah Script

| Kebutuhan | Perintah |
| :--- | :--- |
| **Update Standar** | `.\publish_update.ps1` |
| **Update Wajib (Force Update)**<br>*(User tidak bisa skip/tutup dialog)* | `.\publish_update.ps1 -ReleaseNotes "Pembaruan keamanan penting" -ForceUpdate` |
| **Upload Saja (Skip Build)**<br>*(Jika APK sudah selesai di-build sebelumnya)* | `.\publish_update.ps1 -SkipBuild` |

---

## 📱 5. Fitur di Sisi Aplikasi (User Experience)

1. **Auto-Check saat Buka Aplikasi**:
   Saat pertama kali masuk ke menu Home, aplikasi otomatis memeriksa versi terbaru dari Supabase.
2. **Double-Modal Protection**:
   Dilengkapi pengunci agar dialog update hanya muncul tepat 1 kali dan tidak tumpang tindih.
3. **Banner Reminder (Home Screen)**:
   Jika pengguna memilih tombol *"Nanti"*, banner pengingat berwarna kuning akan tetap berada di bagian atas halaman Home agar mudah diakses kembali.
4. **Manual Check (Tab Profil)**:
   Pengguna dapat memeriksa pembaruan secara manual kapan saja melalui menu **"PERIKSA PEMBARUAN APLIKASI"** di halaman Profil.
5. **In-App Download & Auto-Prompt**:
   File APK diunduh langsung di dalam aplikasi dengan indikator persentase (*progress bar*), lalu otomatis membuka layar instalasi bawaan Android.

---

## 📂 6. Struktur File Terkait

* 📄 `publish_update.ps1` — Script otomatisasi build, upload, dan publish.
* 📄 `lib/core/updater/app_updater_service.dart` — Service logika pengecekan versi, unduh APK via Dio, dan trigger installer Android.
* 📄 `lib/core/updater/app_updater_provider.dart` — State management Riverpod untuk pengecekan versi.
* 📄 `lib/core/updater/checksum_verifier.dart` — Utility SHA-256 verification untuk security.
* 📄 `lib/shared/widgets/update_dialog.dart` — Komponen UI dialog update dengan progress bar dan proteksi dialog ganda.
* 📄 `android/app/src/main/AndroidManifest.xml` — Konfigurasi izin `REQUEST_INSTALL_PACKAGES` dan `FileProvider`.
* 📄 `android/app/src/main/res/xml/file_paths.xml` — Jalur akses storage lokal untuk FileProvider.
* 📄 `UPDATE_SYSTEM_IMPROVEMENTS.md` — Dokumentasi saran improvement dan roadmap.

---

## 🔒 7. Keamanan (Security)

Sistem update ini dilengkapi dengan **SHA-256 checksum verification** untuk mencegah:
- ✅ Tampering (APK dimodifikasi oleh attacker)
- ✅ Man-in-the-middle attacks
- ✅ Corrupted downloads

### Cara Kerja:
1. Saat build APK, script `publish_update.ps1` otomatis hitung SHA-256 hash
2. Hash disimpan di database kolom `sha256_checksum`
3. Setelah download, Flutter app verifikasi hash file yang didownload
4. Jika **TIDAK MATCH** → File dihapus + show error, **TIDAK JADI INSTALL**
5. Jika **MATCH** → Lanjut ke installer ✅

### Best Practices:
- 🔐 **Jangan share Service Role Key** di git atau public
- 🔐 Set environment variable di local machine saja
- 🔐 Rotate key secara berkala (every 6 months)
- 📊 Monitor logs untuk checksum mismatch (indicator of attack)

---

## 🧪 8. Testing Sebelum Production

Sebelum publish update ke production, test dulu:

### Test Checklist:
- [ ] Migration `app_releases` table sudah running
- [ ] Script `publish_update.ps1` berhasil upload APK + insert database
- [ ] App detect update available
- [ ] Download progress bar berfungsi
- [ ] Checksum verification berjalan (check logs)
- [ ] Installer terbuka otomatis
- [ ] Setelah install, app tidak show dialog lagi
- [ ] Force update scenario (dialog tidak bisa di-close)
- [ ] Banner reminder muncul jika user klik "Nanti"
- [ ] Manual check dari profile screen berfungsi

### Test Error Scenarios:
- [ ] No internet → Show error message yang jelas
- [ ] Corrupt checksum (manual edit database) → Block install
- [ ] Download timeout → Show retry option

**Lihat detail testing guide di:** `UPDATE_SYSTEM_IMPROVEMENTS.md`

---

## 📈 9. Monitoring & Analytics (Recommended)

Untuk production, sangat disarankan menambahkan tracking:
- Berapa user yang sudah update ke versi terbaru
- Berapa yang gagal download
- Average download time
- Device yang bermasalah

**Implementasi:** Lihat section "Update Download Analytics" di `UPDATE_SYSTEM_IMPROVEMENTS.md`
