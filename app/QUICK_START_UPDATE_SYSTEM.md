# ⚡ Quick Start: Update System

> **Fast reference untuk publish update. Detail lengkap:** `AUTO_UPDATE_GUIDE.md`

---

## 🚀 First Time Setup (HANYA SEKALI)

### 1. Run Migration Database
```sql
-- Copy-paste di Supabase SQL Editor
-- File: ../../web project/supabase/migrations/20260814000001_create_app_releases_table.sql
```

### 2. Set Environment Variable
```powershell
# Di PowerShell (as Admin)
[System.Environment]::SetEnvironmentVariable(
  "SUPABASE_SERVICE_ROLE_KEY", 
  "eyJhbG...", 
  "User"
)
```
*Get key dari: Supabase Dashboard > Settings > API > service_role (secret)*

### 3. Install Dependencies
```bash
cd "app project/app"
flutter pub get
```

---

## 📦 Publish Update (Every Release)

### Step 1: Bump Version
```yaml
# pubspec.yaml
version: 1.3.0+3  # ⬅️ Increment build number (+3)
```

### Step 2: Run Script
```powershell
cd "app project/app"
.\publish_update.ps1
```

**Optional flags:**
```powershell
# Force update (user tidak bisa skip)
.\publish_update.ps1 -ForceUpdate

# With release notes
.\publish_update.ps1 -ReleaseNotes "Fix bug login"

# Skip build (jika APK sudah di-build)
.\publish_update.ps1 -SkipBuild
```

### Step 3: Done! 🎉
Users akan dapat update saat buka app.

---

## 🧪 Testing Checklist

- [ ] Script berhasil upload APK + insert database
- [ ] App detect update (dialog muncul)
- [ ] Download progress berjalan
- [ ] Checksum verified (check console log)
- [ ] Installer terbuka otomatis
- [ ] After install, no dialog (already latest)

---

## 🔧 Troubleshooting

### Script Error: "Service Role Key belum di-set"
```powershell
# Set key (step 2 di atas)
$env:SUPABASE_SERVICE_ROLE_KEY = "eyJhbG..."
```

### Script Error: "Tabel app_releases tidak ditemukan"
```sql
-- Run migration (step 1 di atas)
```

### App Error: "Update check failed"
- Check internet connection
- Check Supabase project online
- Check console log untuk detail error

### Download Stuck at 0%
- Check file size (max 100 MB)
- Check Supabase Storage bucket "releases" exists & public
- Check download URL accessible

---

## 📊 Verify Update Published

### Check Database
```sql
-- Di Supabase SQL Editor
SELECT version, build_number, created_at, sha256_checksum 
FROM app_releases 
ORDER BY created_at DESC 
LIMIT 5;
```

### Check Storage
1. Supabase Dashboard > Storage > releases
2. Should see: `mangan-group-1.3.0.apk`

---

## 🔒 Security Notes

✅ **DO:**
- Keep service role key SECRET
- Always test before production publish
- Monitor checksum verification logs
- Rotate keys every 6 months

❌ **DON'T:**
- Commit service role key to git
- Reuse build numbers
- Skip testing
- Ignore checksum mismatch errors

---

## 📚 Full Documentation

- **How-to Guide:** `AUTO_UPDATE_GUIDE.md`
- **Audit Report:** `AUDIT_REPORT_2026-08-14.md`
- **Improvements:** `UPDATE_SYSTEM_IMPROVEMENTS.md`
- **Code:** `lib/core/updater/`

---

## 💡 Pro Tips

1. **Build numbers must always increment** - 2 → 3 → 4 (never reuse)
2. **Test on real device** - Emulator cannot install APK
3. **Monitor first hour** - Check for error spikes
4. **Keep 3 recent APKs** - For emergency rollback
5. **Clear release notes** - Users appreciate transparency

---

**Last Updated:** 2026-08-14  
**System Version:** 1.0.0  
**Status:** ✅ Production Ready
