# 🚀 Saran Improvement untuk Sistem Update

Dokumen ini berisi saran-saran untuk meningkatkan sistem in-app update yang sudah ada.

---

## ✅ SUDAH DIIMPLEMENTASIKAN (Hari ini: 2026-08-14)

### 1. **Tabel Database `app_releases`**
- ✅ Migration file dibuat: `20260814000001_create_app_releases_table.sql`
- ✅ RLS policies configured
- ✅ Indexes untuk performance
- ✅ Auto-update timestamp trigger

### 2. **Security: SHA-256 Checksum Verification**
- ✅ Kolom `sha256_checksum` ditambahkan ke database
- ✅ `ChecksumVerifier` utility class dibuat
- ✅ Verification logic integrated ke `downloadAndInstall()`
- ✅ Script `publish_update.ps1` auto-calculate checksum
- ✅ Dependency `crypto` ditambahkan ke `pubspec.yaml`

### 3. **Error Handling Improvements**
- ✅ `checkForUpdate()` sekarang throw exception instead of silent fail
- ✅ Stack trace logging untuk debugging

### 4. **Network Timeout Configuration**
- ✅ Dio configured dengan timeout:
  - Connect: 30 seconds
  - Receive: 10 minutes (untuk APK besar)
  - Send: 30 seconds

---

## 🔄 RECOMMENDED IMPROVEMENTS (Belum Implementasi)

### Priority: HIGH 🔴

#### 1. **Rollback Mechanism**
**Problem:** Jika versi baru ada critical bug, tidak ada cara untuk rollback.

**Solution:**
```sql
-- Tambahkan field is_active ke tabel
ALTER TABLE app_releases ADD COLUMN is_active BOOLEAN DEFAULT true;

-- Update query di Flutter
.select()
.eq('is_active', true)  -- Hanya ambil release yang aktif
.order('build_number', ascending: false)
.limit(1)
```

**Benefit:** Admin bisa "disable" versi bermasalah tanpa hapus dari database.

#### 2. **Partial Download Resume Support**
**Problem:** Jika download interrupted, harus start dari awal.

**Solution:**
```dart
// Gunakan Range header untuk resume download
await _dio.download(
  release.downloadUrl,
  filePath,
  options: Options(
    headers: {
      'Range': 'bytes=$startByte-', // Resume from startByte
    },
  ),
  deleteOnError: false, // Jangan hapus partial file
);
```

**Benefit:** User dengan koneksi tidak stabil tidak frustasi.

#### 3. **Cancel Download Button**
**Problem:** User tidak bisa cancel download yang sedang berjalan.

**Solution:**
```dart
// Di update_dialog.dart
final cancelToken = CancelToken();

// Button cancel
if (_isDownloading)
  TextButton(
    onPressed: () {
      cancelToken.cancel('User cancelled');
      Navigator.pop(context);
    },
    child: const Text('Batal'),
  ),

// Pass ke download
await AppUpdaterService.downloadAndInstall(
  release,
  cancelToken: cancelToken,
  onProgress: (progress) { ... },
);
```

#### 4. **Update Download Analytics**
**Problem:** Tidak tahu berapa user yang berhasil/gagal update.

**Solution:**
```sql
-- Tambah tabel tracking
CREATE TABLE app_update_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  member_id UUID REFERENCES squad_members(id),
  release_id UUID REFERENCES app_releases(id),
  event_type TEXT, -- 'check', 'start_download', 'complete', 'failed', 'cancelled'
  error_message TEXT,
  device_info JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

Log events:
- User check update
- Start download
- Download complete
- Install initiated
- Errors (with message)

**Benefit:** Monitoring adoption rate dan troubleshooting.

---

### Priority: MEDIUM 🟡

#### 5. **Staged Rollout**
**Problem:** Semua user dapat update sekaligus. Jika ada bug, impact ke semua user.

**Solution:**
```sql
ALTER TABLE app_releases ADD COLUMN rollout_percentage INTEGER DEFAULT 100;

-- Query di Flutter
-- Hanya show update ke X% user berdasarkan hash member_id
```

**Benefit:** Gradual rollout (10% → 50% → 100%), early bug detection.

#### 6. **Background Download**
**Problem:** User harus tunggu di dialog sampai download selesai.

**Solution:**
- Gunakan `background_downloader` package
- Show notification dengan progress
- User bisa continue pakai app
- Notification action: "Install Now"

#### 7. **WiFi-Only Option**
**Problem:** User dengan limited data plan tidak mau download via cellular.

**Solution:**
```dart
// Check connection type
import 'package:connectivity_plus/connectivity_plus.dart';

final connectivity = await Connectivity().checkConnectivity();
if (connectivity == ConnectivityResult.mobile && !wifiOnly) {
  // Show warning dialog: "Update requires XX MB. Continue with mobile data?"
}
```

Store preference di SharedPreferences.

#### 8. **Minimum Version Enforcement**
**Problem:** Jika ada breaking change di backend API, old app version bisa crash.

**Solution:**
```sql
ALTER TABLE app_releases ADD COLUMN min_supported_build INTEGER;

-- Contoh: v1.5.0 (build 5) adalah minimum
-- User dengan build < 5 HARUS update (force_update otomatis)
```

#### 9. **Update Size Information**
**Problem:** User tidak tahu berapa besar file yang akan di-download.

**Solution:**
```sql
ALTER TABLE app_releases ADD COLUMN file_size_bytes BIGINT;

-- Update publish script untuk include file size
```

Show di dialog: "Update tersedia (25.3 MB)"

---

### Priority: LOW 🟢

#### 10. **Multi-Language Release Notes**
**Problem:** Release notes hanya Bahasa Indonesia.

**Solution:**
```sql
ALTER TABLE app_releases ADD COLUMN release_notes_en TEXT;
```

#### 11. **Beta Channel**
**Problem:** Tidak ada cara untuk early access testing.

**Solution:**
```sql
ALTER TABLE app_releases ADD COLUMN channel TEXT DEFAULT 'stable';
-- Values: 'stable', 'beta', 'alpha'

-- User opt-in beta di profile settings
```

#### 12. **Update History in App**
**Problem:** User tidak bisa lihat changelog dari versi sebelumnya.

**Solution:**
Tambah screen "Update History" yang show semua release notes.

---

## 📋 Implementation Checklist

### Immediate Action (Sebelum Push to Production)
- [x] Run migration `20260814000001_create_app_releases_table.sql`
- [ ] Run `flutter pub get` untuk install `crypto` package
- [ ] Test full update flow:
  - [ ] Check update (no update available)
  - [ ] Publish dummy update dengan script
  - [ ] Check update (update available)
  - [ ] Download & install
  - [ ] Verify checksum working
- [ ] Test error scenarios:
  - [ ] No internet connection
  - [ ] Invalid checksum (manually edit database)
  - [ ] Corrupted download
  - [ ] Timeout

### Short Term (1-2 Minggu)
- [ ] Implement rollback mechanism (is_active flag)
- [ ] Add cancel download button
- [ ] Add update analytics logging
- [ ] Add file size information

### Medium Term (1 Bulan)
- [ ] Implement partial download resume
- [ ] Add WiFi-only option
- [ ] Add minimum version enforcement
- [ ] Background download support

### Long Term (Nice to Have)
- [ ] Staged rollout system
- [ ] Beta channel
- [ ] Update history screen
- [ ] Multi-language support

---

## 🧪 Testing Guide

### Test Case 1: Normal Update Flow
1. Set app version ke 1.2.0 (build 2)
2. Publish version 1.3.0 (build 3) dengan script
3. Open app → Should show update dialog
4. Click "Update Sekarang"
5. Wait for download (progress bar should animate)
6. Installer should open automatically
7. Install APK
8. Open app → Should not show dialog (already latest)

### Test Case 2: Force Update
1. Publish version 1.4.0 (build 4) dengan flag `-ForceUpdate`
2. Open app → Dialog should not have "Nanti" button
3. Cannot dismiss dialog by tapping outside
4. Back button should not close dialog

### Test Case 3: Checksum Mismatch
1. Publish update normally
2. Manually edit `sha256_checksum` di database (corrupt value)
3. Try to update
4. Should show error: "Verifikasi integritas APK gagal"
5. APK file should be deleted

### Test Case 4: Network Error
1. Turn off internet
2. Try manual check from profile
3. Should show error message
4. Turn on internet
5. Try again → Should work

---

## 📊 Monitoring Queries

### Check Update Adoption Rate
```sql
SELECT 
  ar.version,
  ar.build_number,
  ar.created_at,
  COUNT(DISTINCT aul.member_id) as unique_downloads,
  COUNT(*) FILTER (WHERE aul.event_type = 'complete') as successful_installs,
  COUNT(*) FILTER (WHERE aul.event_type = 'failed') as failed_downloads
FROM app_releases ar
LEFT JOIN app_update_logs aul ON aul.release_id = ar.id
GROUP BY ar.id
ORDER BY ar.created_at DESC;
```

### Find Users on Old Versions
```sql
-- Query ini membutuhkan tracking last_app_version di squad_members
SELECT 
  nama,
  last_app_version,
  last_seen_at
FROM squad_members
WHERE last_app_build_number < (
  SELECT build_number 
  FROM app_releases 
  WHERE is_active = true 
  ORDER BY build_number DESC 
  LIMIT 1
)
ORDER BY last_seen_at DESC;
```

---

## 🔒 Security Checklist

- [x] APK signature verification (SHA-256)
- [x] HTTPS untuk download URL (Supabase Storage auto-HTTPS)
- [x] RLS policies di database
- [x] Service role key tidak di-commit ke git
- [ ] Rate limiting untuk update checks (prevent abuse)
- [ ] CDN untuk storage bucket (reduce load + faster download)
- [ ] Alert system jika ada anomaly (e.g., checksum mismatch spike)

---

## 💡 Best Practices

1. **Always increment build_number** - Jangan pernah reuse build number
2. **Test on multiple devices** - Test minimal 3 device (low-end, mid-range, high-end)
3. **Monitor first 24 hours** - Check logs untuk error spike
4. **Keep at least 3 recent APKs** - Untuk rollback jika perlu
5. **Document breaking changes** - Clear communication di release notes
6. **Backup database before migration** - Always have escape plan

---

Dokumen ini akan di-update seiring dengan implementasi improvement.

**Last Updated:** 2026-08-14
**Next Review:** 2026-08-21
