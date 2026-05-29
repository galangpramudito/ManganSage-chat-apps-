# 💬 Mangansage

[![Flutter Version](https://img.shields.io/badge/Flutter-3.44-02569B?logo=flutter)](https://flutter.dev)
[![Laravel Version](https://img.shields.io/badge/Laravel-13-FF2D20?logo=laravel)](https://laravel.com)
[![PHP Version](https://img.shields.io/badge/PHP-8.3-777BB4?logo=php)](https://php.net)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**Mangansage** adalah aplikasi *real-time chat* berdesain minimalis yang terinspirasi dari iMessage. Dibangun menggunakan ekosistem modern **Flutter** untuk sisi *client* dan **Laravel 13** untuk sisi *backend*, aplikasi ini mendukung komunikasi WebSocket *real-time* berkinerja tinggi, manajemen profil, dan sistem autentikasi yang aman.

> **Spesifikasi Dokumen:** [Spesifikasi Teknis](./technical-spec.md) · [Spesifikasi Desain](./design-spec.md)

---

## ✨ Fitur Utama

### 🔒 Autentikasi & Keamanan
* **Email Verification:** Sistem verifikasi email berbasis OTP 6-digit (berlaku 10 menit) pasca-registrasi.
* **Password Recovery:** Alur 3 tahap untuk *reset password* (Request OTP → Verifikasi → Set Password Baru).
* **Token Management:** Autentikasi aman menggunakan Laravel Sanctum dengan fitur pembatalan token saat *reset password* atau *logout*.
* **Anti-Enumeration:** Endpoint keamanan dirancang untuk mencegah eksploitasi data pengguna.

### 💬 Real-Time Messaging
* **WebSocket Integration:** Pesan diantarkan secara instan menggunakan **Laravel Reverb** (protokol Pusher).
* **FCM Push Notifications:** Notifikasi latar belakang menggunakan Firebase Cloud Messaging (dengan mekanisme *graceful fallback* jika Firebase tidak dikonfigurasi).
* **Smart Indicators:** Tanda terima baca (*read receipts* ✓✓) dan format waktu pesan yang dinamis.

### 👤 Manajemen Profil
* Ubah nama dan unggah avatar kustom (mendukung *multipart/form-data*, maks 2MB).
* Perubahan email wajib melalui proses re-verifikasi.
* Avatar *fallback* deterministik dengan 10 variasi warna.

---

## 🛠️ Tech Stack

| Layer | Teknologi Utama |
|---|---|
| **Frontend/UI** | Flutter 3.44, Riverpod 3, Freezed, GoRouter |
| **Backend/API** | Laravel 13, PHP 8.3, FrankenPHP |
| **Database** | Neon Postgres (Cloud) / SQLite (Lokal) |
| **Real-time & Notifikasi** | Laravel Reverb, Firebase Cloud Messaging (FCM) |
| **Infrastruktur & Deploy** | Oracle Cloud Free Tier, Docker, Caddy |

---

## 🚀 Quick Start (Pengembangan Lokal)

Untuk menjalankan proyek ini di mesin lokal Anda, ikuti langkah-langkah berikut:

### 1. Menjalankan Backend (Terminal 1)
```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate:fresh --seed
php artisan serve --host=0.0.0.0 --port=8000