# 🚀 Panduan Rilis Otomatis Menggunakan GitHub Actions

Dengan setup ini, kamu **tidak perlu lagi build dan upload APK manual dari laptop**. Cukup buat git tag (misal: `v1.2.1`) dan push ke GitHub, server GitHub akan otomatis:
1. ⚙️ Meng-compile APK Flutter secara cloud.
2. 📦 Menyimpan dan meng-hosting file APK di **GitHub Releases** (gratis tanpa batas kuota).
3. 🔒 Menghitung SHA-256 checksum untuk keamanan.
4. 📥 Mendaftarkan versi baru ke database Supabase agar aplikasi pengguna langsung mendeteksi update.

---

## ⚙️ Langkah 1: Pasang GitHub Secrets (Hanya Perlu 1x)

Agar GitHub Actions bisa build project dan mendaftarkan update ke Supabase, masukkan 3 Secrets ke repository GitHub kamu:

1. Buka repo GitHub kamu di browser.
2. Klik tab **Settings** → menu samping **Secrets and variables** → **Actions**.
3. Klik tombol hijau **"New repository secret"**, tambahkan 3 secret berikut:

| Name | Value | Keterangan |
| :--- | :--- | :--- |
| `SUPABASE_URL` | `https://vcsvbeepbzmcfnwapqog.supabase.co` | URL Supabase project kamu |
| `SUPABASE_ANON_KEY` | `sb_publishable_ERJZP35FRoSkfmc3qD823g_OLPuHkWc` | Supabase Anon / Publishable Key |
| `SUPABASE_SERVICE_ROLE_KEY` | *(Paste Service Role Key kamu)* | Ambil dari Supabase: **Settings** → **API** → `service_role` (secret) |

---

## ⚙️ Langkah 2: Beri Izin Workflow Write Permissions di GitHub (1x)

1. Di repository GitHub kamu, buka **Settings** → **Actions** → **General**.
2. Scroll ke bawah ke bagian **Workflow permissions**.
3. Pilih **"Read and write permissions"** lalu klik **Save**.
   *(Ini wajib agar GitHub Actions boleh membuat Release dan mengunggah file APK).*

---

## 📦 Langkah 3: Cara Rilis Update Baru

Setiap kali kamu selesai mengubah kode dan ingin merilis update ke pengguna:

### 1. Naikkan Versi di `pubspec.yaml`
```yaml
# Naikkan angka build number setelah tanda +
version: 1.2.1+5
```

### 2. Commit, Beri Tag, dan Push
Buka terminal dan jalankan 3 perintah ini:

```bash
# 1. Simpan perubahan kode
git add .
git commit -m "Rilis v1.2.1"

# 2. Buat tag sesuai versi
git tag v1.2.1

# 3. Push ke GitHub beserta tag-nya
git push origin main --tags
```

---

## 🔍 Langkah 4: Pantau Proses Rilis

1. Buka tab **Actions** di repo GitHub kamu.
2. Kamu akan melihat workflow **"Build and Release APK"** sedang berjalan.
3. Setelah selesai (sekitar 3-5 menit):
   * File APK akan muncul di halaman **Releases** GitHub kamu.
   * Supabase database otomatis terisi dengan link download GitHub Release tersebut.
   * Pengguna yang membuka aplikasi akan langsung mendapatkan notifikasi popup & banner update! 🚀
