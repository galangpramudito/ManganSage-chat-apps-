# 🚀 Mangan Group Mobile App - Auto Release System

Sistem otomatis untuk build, publish, dan distribute update aplikasi Flutter menggunakan GitHub Actions.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Setup (One-Time)](#setup-one-time)
- [Release New Version](#release-new-version)
- [Troubleshooting](#troubleshooting)
- [Architecture](#architecture)

---

## 🎯 Overview

### **Workflow Otomatis:**

```
Developer push tag → GitHub Actions → Build APK → Upload to GitHub Releases → Update Supabase → Users notified
```

### **Keuntungan:**

- ✅ **Unlimited Storage** - GitHub Releases (no 50 MB limit)
- ✅ **Fully Automated** - Build, checksum, upload, database update
- ✅ **Security** - SHA-256 APK verification
- ✅ **Fast CDN** - GitHub global network
- ✅ **Version Control** - All releases tracked

---

## ⚡ Quick Start

### **Cara Release Version Baru (30 detik):**

```powershell
# 1. Bump version di app/pubspec.yaml
# version: 1.2.3+6 → 1.2.4+7

# 2. Create & push tag
cd "Z:\PROJECTS\VsCode\MANGAN GROUP\app project"
git add app/pubspec.yaml
git commit -m "Release v1.2.4"
git push origin main
git tag v1.2.4
git push origin v1.2.4

# 3. Done! Workflow auto-triggered ✅
# Wait 5-10 minutes, APK ready di GitHub Releases
```

**Monitor progress:**
- 👉 https://github.com/galangpramudito/ManganSage-chat-apps-/actions

**Download APK:**
- 👉 https://github.com/galangpramudito/ManganSage-chat-apps-/releases

---

## 🔧 Setup (One-Time)

> **⚠️ Setup ini SUDAH SELESAI!** Section ini untuk reference jika perlu setup ulang.

### **1. GitHub Secrets** ✅

Required secrets (Settings → Secrets and variables → Actions):

| Secret Name | Value | Purpose |
|-------------|-------|---------|
| `SUPABASE_URL` | `https://vcsvbeepbzmcfnwapqog.supabase.co` | Supabase project URL |
| `SUPABASE_SERVICE_ROLE_KEY` | `eyJhbGc...` (secret key) | Admin access untuk update database |
| `SUPABASE_ANON_KEY` | `eyJhbGc...` (public key) | Public API key untuk app |
| `GOOGLE_SERVICES_JSON` | `{...}` (full JSON content) | Firebase config untuk push notifications |

**How to add:**
1. GitHub repo → Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Name: (pilih dari table di atas)
4. Value: (paste value)
5. Add secret

---

### **2. Workflow File** ✅

File: `.github/workflows/release-apk.yml`

**Location:** Root repo (BUKAN di subfolder `app/`)

**Trigger:** Push tag dengan format `v*.*.*`

**Working directory:** `app/` (Flutter app di subfolder)

---

### **3. Database Migration** ✅

Table `app_releases` dengan columns:
- `version` (TEXT) - e.g., "1.2.3"
- `build_number` (INTEGER UNIQUE) - e.g., 6
- `download_url` (TEXT) - GitHub release URL
- `sha256_checksum` (TEXT) - Security verification
- `release_notes` (TEXT) - Optional notes
- `force_update` (BOOLEAN) - User must update?

**Migration file:** `web project/supabase/migrations/20260814000003_simple_enhance.sql`

---

## 🚀 Release New Version

### **Step-by-Step:**

#### **1. Edit Version di `app/pubspec.yaml`:**

```yaml
# Current
version: 1.2.3+6

# New (increment both version AND build number)
version: 1.2.4+7
```

**Rules:**
- ✅ Build number (+7) HARUS lebih besar dari sebelumnya
- ✅ Version (1.2.4) bisa sama atau increment
- ❌ JANGAN reuse build number yang sudah pernah dipakai

---

#### **2. Commit & Push:**

```powershell
cd "Z:\PROJECTS\VsCode\MANGAN GROUP\app project"

# Commit version bump
git add app/pubspec.yaml
git commit -m "Bump version to v1.2.4"
git push origin main
```

---

#### **3. Create & Push Tag:**

```powershell
# Format tag: v{VERSION}
git tag v1.2.4

# Push tag (ini yang trigger workflow!)
git push origin v1.2.4
```

**Expected output:**
```
Total 0 (delta 0), reused 0 (delta 0)
To https://github.com/galangpramudito/ManganSage-chat-apps-.git
 * [new tag]         v1.2.4 -> v1.2.4
```

---

#### **4. Monitor Workflow:**

**Open Actions page:**
```
https://github.com/galangpramudito/ManganSage-chat-apps-/actions
```

**Workflow stages (5-10 minutes total):**
1. 🟡 Setup Java & Flutter (2 min)
2. 🟡 Install dependencies (1 min)
3. 🟡 Build APK (3-5 min)
4. 🟡 Calculate SHA-256 checksum (10 sec)
5. 🟡 Create GitHub Release (30 sec)
6. 🟡 Update Supabase database (10 sec)
7. 🟢 **Done!** ✅

---

#### **5. Verify Release:**

**A. Check GitHub Releases:**
```
https://github.com/galangpramudito/ManganSage-chat-apps-/releases
```

Should see:
- Release `v1.2.4`
- APK file: `mangan-group-1.2.4.apk`
- SHA-256 checksum listed

**B. Check Supabase Database:**

Supabase Dashboard → Table Editor → `app_releases`

New record:
```
version: 1.2.4
build_number: 7
download_url: https://github.com/.../v1.2.4/mangan-group-1.2.4.apk
sha256_checksum: abc123... (64 chars)
```

**C. Test Flutter App:**

Open app (with build < 7) → Should show update dialog ✅

---

## 🐛 Troubleshooting

### **Problem: Workflow Tidak Trigger**

**Symptoms:** Actions page kosong setelah push tag

**Causes & Solutions:**

1. **Tag format salah**
   ```powershell
   # ❌ Wrong
   git tag 1.2.4          # Missing 'v'
   git tag release-1.2.4  # Wrong format
   
   # ✅ Correct
   git tag v1.2.4
   ```

2. **Workflow file tidak di root**
   ```
   ❌ app/.github/workflows/release-apk.yml
   ✅ .github/workflows/release-apk.yml
   ```

3. **Tag sudah ada**
   ```powershell
   # Error: tag 'v1.2.4' already exists
   
   # Solution: Use new tag
   git tag v1.2.5
   
   # Or delete & recreate
   git tag -d v1.2.4
   git push origin --delete v1.2.4
   git tag v1.2.4
   git push origin v1.2.4
   ```

---

### **Problem: Workflow Failed**

**Symptoms:** Red X di Actions page

**Check logs:**
1. Click failed workflow
2. Click failed step
3. Read error message

**Common errors:**

#### **A. Missing Secret**
```
Error: secret GOOGLE_SERVICES_JSON not found
```

**Solution:** Add missing secret di Settings → Secrets

---

#### **B. Build Failed**
```
FAILURE: Build failed with an exception
```

**Solution:** 
1. Test build locally: `flutter build apk --release`
2. Fix errors di local
3. Commit & push
4. Re-trigger workflow

---

#### **C. Database Insert Failed**
```
Error: duplicate key violates unique constraint
```

**Cause:** Build number sudah dipakai

**Solution:** Increment build number di pubspec.yaml

---

### **Problem: APK Size Too Large**

**Symptoms:** File > 50 MB (not an issue with GitHub, just FYI)

**Solution:** Workflow already builds universal APK. If needed:

```powershell
# Edit workflow to build split APK
flutter build apk --split-per-abi --release
```

---

### **Problem: Update Tidak Muncul di App**

**Symptoms:** Open app, no update dialog

**Checks:**

1. **Build number correct?**
   ```sql
   -- Supabase SQL Editor
   SELECT build_number FROM app_releases ORDER BY build_number DESC LIMIT 1;
   ```
   
   Should be GREATER than app build number.

2. **App connected to internet?**
   Check console log for update check.

3. **Database updated?**
   Check `app_releases` table has new record.

---

## 🏗️ Architecture

### **System Components:**

```
┌─────────────────────────────────────────────────────────┐
│                     DEVELOPER                           │
│  1. Edit code                                           │
│  2. Bump version in pubspec.yaml                        │
│  3. git tag v1.2.4 && git push --tags                   │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│              GITHUB ACTIONS (CI/CD)                     │
│  ┌───────────────────────────────────────────────────┐  │
│  │ 1. Checkout code                                  │  │
│  │ 2. Setup Java + Flutter                           │  │
│  │ 3. Install dependencies                           │  │
│  │ 4. Create .env & google-services.json (secrets)   │  │
│  │ 5. Run code generation (build_runner)             │  │
│  │ 6. Build APK (flutter build apk --release)        │  │
│  │ 7. Calculate SHA-256 checksum                     │  │
│  │ 8. Create GitHub Release                          │  │
│  │ 9. Upload APK to GitHub Releases                  │  │
│  │ 10. Insert to Supabase app_releases table         │  │
│  └───────────────────────────────────────────────────┘  │
└────────────────┬────────────────────────────────────────┘
                 │
                 ├──────────────┬─────────────────────────┐
                 ▼              ▼                         ▼
      ┌──────────────┐  ┌─────────────┐  ┌──────────────────┐
      │   GITHUB     │  │  SUPABASE   │  │  FLUTTER APP     │
      │   RELEASES   │  │  DATABASE   │  │   (Users)        │
      │              │  │             │  │                  │
      │ APK Storage  │  │ app_releases│  │ 1. Check update  │
      │ (Unlimited)  │  │   table     │  │ 2. Download APK  │
      │              │  │             │  │ 3. Verify SHA256 │
      │ Download:    │  │ Version:    │  │ 4. Install       │
      │ github.com/  │  │  1.2.4      │  │                  │
      │ .../releases │  │ Build: 7    │  │                  │
      │              │  │ URL: github │  │                  │
      └──────────────┘  └─────────────┘  └──────────────────┘
```

---

### **Security Flow:**

```
1. Developer builds APK locally
2. GitHub Actions calculates SHA-256: abc123...
3. Stores in database: sha256_checksum = "abc123..."
4. User downloads APK from GitHub
5. Flutter app calculates SHA-256 of downloaded file
6. Compare: downloaded_hash == database_hash?
   ├─ ✅ Match → Install (safe)
   └─ ❌ Mismatch → Delete + error (tampered file)
```

---

## 📊 Monitoring & Analytics

### **Track Release Adoption:**

```sql
-- Check active versions
SELECT 
  version,
  build_number,
  created_at,
  download_url
FROM app_releases
ORDER BY build_number DESC;
```

### **Workflow History:**

```
https://github.com/galangpramudito/ManganSage-chat-apps-/actions/workflows/release-apk.yml
```

---

## 📝 Release Checklist

Use this checklist for every release:

```
[ ] Code changes tested locally
[ ] Version bumped in app/pubspec.yaml (increment build_number!)
[ ] Committed & pushed to main
[ ] Tag created: git tag v1.2.4
[ ] Tag pushed: git push origin v1.2.4
[ ] Workflow triggered (check Actions page)
[ ] Workflow completed successfully (green check)
[ ] GitHub Release created with APK
[ ] Supabase database updated
[ ] Tested update notification in app
[ ] Announced to users (if major release)
```

---

## 🔗 Useful Links

- **GitHub Actions:** https://github.com/galangpramudito/ManganSage-chat-apps-/actions
- **GitHub Releases:** https://github.com/galangpramudito/ManganSage-chat-apps-/releases
- **Supabase Dashboard:** https://supabase.com/dashboard/project/vcsvbeepbzmcfnwapqog
- **Workflow File:** `.github/workflows/release-apk.yml`

---

## 📚 Additional Documentation

- **[Full Setup Guide](GITHUB_ACTIONS_RELEASE_GUIDE.md)** - Complete documentation
- **[System Improvements](UPDATE_SYSTEM_IMPROVEMENTS.md)** - Future enhancements roadmap
- **[Audit Report](AUDIT_REPORT_2026-08-14.md)** - Security audit & implementation details

---

## 💡 Pro Tips

1. **Always increment build_number** - Never reuse!
2. **Tag format matters** - Must be `v{X.Y.Z}` (with 'v' prefix)
3. **Monitor first 24h** - Check for user reports after release
4. **Keep APKs accessible** - GitHub Releases stores all versions
5. **Test before release** - Build locally first: `flutter build apk --release`

---

## 🆘 Support

**Issues or questions?**
- Check [Troubleshooting](#troubleshooting) section
- Review [GitHub Actions logs](https://github.com/galangpramudito/ManganSage-chat-apps-/actions)
- Contact development team

---

**Last Updated:** 2026-08-14  
**System Version:** 1.0  
**Status:** ✅ Production Ready
