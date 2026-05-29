# ⛔ JANGAN PAKAI FIREBASE

> Dokumen ini ada karena kamu sudah pernah hampir salah langkah.
> Baca sampai habis sebelum `flutter pub add firebase_core` apapun alasannya.

---

## TL;DR

Firebase **sudah diimplementasi** di Step 7 sebagai FCM dispatcher untuk push notification background.
Itu satu-satunya peran Firebase di project ini, dan itu sudah **cukup**.

**Jangan:**
- Pakai Firestore sebagai database
- Pakai Firebase Realtime Database
- Pakai Firebase Auth
- Pakai Firebase Storage
- Pakai Firebase Analytics
- Pakai Firebase Remote Config
- Pakai Firebase Crashlytics *(kecuali kamu memang mau, tapi bukan sekarang)*

---

## Kenapa Tidak?

### 1. Kamu sudah punya backend yang benar

Laravel + Neon (PostgreSQL) sudah menangani semua kebutuhan data:
- Auth → **Laravel Sanctum** ✅
- Database → **Neon PostgreSQL** ✅
- Real-time → **Laravel Reverb** ✅
- Storage file → **Laravel** ✅

Menambah Firebase sebagai sumber data kedua berarti kamu punya **dua sumber kebenaran** yang harus selalu disinkronkan. Itu resep bencana.

### 2. Real-time sudah solved

```
❌ Firebase Realtime Database / Firestore untuk real-time chat
✅ Laravel Reverb + WebSocket (sudah jalan sejak Step 6)
```

Reverb sudah:
- Broadcast pesan baru ke semua participant
- Handle mark-as-read (centang biru)
- Auto-reconnect dengan exponential backoff
- Private channel dengan auth Sanctum

Tidak ada yang perlu digantikan.

### 3. Auth sudah solved

```
❌ Firebase Auth
✅ Laravel Sanctum + flutter_secure_storage
```

Sanctum sudah handle:
- Register / Login / Logout
- Token revocation
- 401 mid-session → auto redirect
- Token tersimpan aman di EncryptedSharedPreferences (Android) / Keychain (iOS)

Menambah Firebase Auth berarti dua sistem auth yang harus dijaga konsistensinya. Tidak worth it.

### 4. Firebase itu ekosistem, bukan library

Sekali kamu mulai pakai satu layanan Firebase, kamu akan tergoda pakai yang lain. Tiba-tiba project yang dimulai dengan arsitektur Laravel yang bersih berubah jadi hybrid berantakan yang separuh logikanya ada di backend PHP dan separuhnya lagi di Firebase Console.

---

## Apa yang Boleh?

Firebase **hanya boleh dipakai untuk satu hal** di project ini:

```
✅ Firebase Cloud Messaging (FCM) — push notification saat app di background
```

Itu saja. Sudah diimplementasi di Step 7. Sudah ada `kreait/laravel-firebase` di backend untuk dispatch notifikasi, dan `firebase_messaging` di Flutter untuk menerima.

Kalau kamu perlu push notification → FCM via backend Laravel. Bukan Firebase langsung dari Flutter.

---

## Checklist Sebelum Kamu Melakukan Sesuatu yang Bodoh

Sebelum menambah package Firebase apapun, tanya diri sendiri:

- [ ] Apakah ini untuk push notification? → Sudah ada, tidak perlu tambah apapun.
- [ ] Apakah ini untuk database? → Pakai Laravel + Neon.
- [ ] Apakah ini untuk auth? → Pakai Sanctum.
- [ ] Apakah ini untuk real-time? → Pakai Reverb.
- [ ] Apakah ini untuk file storage? → Pakai Laravel Storage.
- [ ] Apakah ini untuk analytics/crash reporting? → Boleh dipertimbangkan, tapi bukan prioritas sekarang.

Kalau semua jawaban di atas tidak ada yang cocok, baru diskusikan dulu sebelum install.

---

## Stack yang Benar

```
Notifikasi background  →  FCM (via kreait/laravel-firebase di backend)  ✅ SATU-SATUNYA FIREBASE
Auth                   →  Laravel Sanctum
Database               →  Neon PostgreSQL (server) + SQLite (lokal)
Real-time              →  Laravel Reverb + WebSocket
File/Avatar            →  Laravel Storage
```

Jaga ini tetap bersih.

---

*— Ditulis karena masa depanmu yang bingung perlu diingatkan oleh masa lalumu yang sudah susah payah setup ini semua.*
