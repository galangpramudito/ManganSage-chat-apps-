# 🔴 URGENT — Rotate Credentials Checklist
> Jalankan ini sekarang. Credentials bocor di git history = siapapun bisa akses server dan database kamu.

---

## Urutan Prioritas

### 1. Neon PostgreSQL — Rotate Password ⚡ PALING URGENT

Database production kamu. Kalau ini diakses orang lain, semua data user bisa dibaca/dihapus.

1. Buka [Neon Console](https://console.neon.tech)
2. Pilih project `mangansage`
3. **Settings → Reset Password**
4. Copy password baru
5. Update di Fly.io:
```powershell
fly secrets set DB_PASSWORD="password-baru" --app mangansage-api
fly secrets set DB_PASSWORD="password-baru" --app mangansage-reverb
```

---

### 2. Laravel APP_KEY — Generate Baru

APP_KEY dipakai untuk enkripsi session dan data sensitif.

```powershell
cd backend
php artisan key:generate --show
# Copy output-nya, format: base64:xxxx...
```

Update di Fly.io:
```powershell
fly secrets set APP_KEY="base64:key-baru" --app mangansage-api
fly secrets set APP_KEY="base64:key-baru" --app mangansage-reverb
```

> ⚠️ Setelah APP_KEY berubah, semua user yang sedang login akan ter-logout otomatis. Normal.

---

### 3. Reverb Credentials — Generate Baru

```powershell
cd backend
php artisan reverb:install
# Atau manual: generate random string 32 karakter untuk key dan secret
```

Atau generate manual via PowerShell:
```powershell
# Generate REVERB_APP_KEY (32 char)
-join ((48..57) + (97..122) | Get-Random -Count 32 | % {[char]$_})

# Generate REVERB_APP_SECRET (32 char)
-join ((48..57) + (97..122) | Get-Random -Count 32 | % {[char]$_})

# REVERB_APP_ID (angka random)
Get-Random -Minimum 100000 -Maximum 999999
```

Update di Fly.io:
```powershell
fly secrets set `
  REVERB_APP_ID="id-baru" `
  REVERB_APP_KEY="key-baru" `
  REVERB_APP_SECRET="secret-baru" `
  --app mangansage-api

fly secrets set `
  REVERB_APP_ID="id-baru" `
  REVERB_APP_KEY="key-baru" `
  REVERB_APP_SECRET="secret-baru" `
  --app mangansage-reverb
```

Update juga di `backend/.env` lokal kamu.

---

### 4. Firebase Service Account — Revoke & Regenerate

Kalau file `firebase-credentials.json` pernah ter-commit:

1. Buka [Firebase Console](https://console.firebase.google.com)
2. **Project Settings → Service Accounts**
3. Klik **"Manage service account permissions"** → Google Cloud Console terbuka
4. Cari service account yang dipakai → **Actions → Disable** (atau Delete)
5. Buat service account baru → **Generate new private key**
6. Download JSON baru, simpan di `backend/storage/firebase-credentials.json`
7. **Jangan commit file ini ke git** — pastikan ada di `.gitignore`

Upload ke Fly.io via SSH:
```powershell
fly ssh console --app mangansage-api
# Di dalam container:
cat > storage/firebase-credentials.json << 'EOF'
{ ... isi JSON baru ... }
EOF
```

---

### 5. Bersihkan Git History

Credentials yang sudah pernah di-commit tetap ada di git history meski sudah dihapus dari file. Perlu di-purge:

**Opsi A — BFG Repo Cleaner (lebih mudah):**
```powershell
# Download BFG dari https://rtyley.github.io/bfg-repo-cleaner/
# Buat file passwords.txt berisi nilai credentials lama (satu per baris)

java -jar bfg.jar --replace-text passwords.txt
git reflog expire --expire=now --all
git gc --prune=now --aggressive
git push --force
```

**Opsi B — git filter-branch (built-in):**
```powershell
git filter-branch --force --index-filter `
  "git rm --cached --ignore-unmatch backend/.env" `
  --prune-empty --tag-name-filter cat -- --all
git push origin --force --all
```

> ⚠️ Force push akan overwrite history di GitHub. Kalau ada collaborator lain, beritahu mereka untuk `git fetch --all && git reset --hard origin/main`.

---

### 6. Update `.gitignore` — Pastikan Tidak Bocor Lagi

Pastikan ini ada di `backend/.gitignore`:

```
.env
.env.*
!.env.example
storage/firebase-credentials.json
storage/*.json
*.pem
*.key
```

---

## Checklist Verifikasi

Setelah semua selesai:

- [ ] Neon password sudah direset
- [ ] `DB_PASSWORD` sudah diupdate di kedua Fly.io app
- [ ] `APP_KEY` sudah di-generate ulang dan diupdate
- [ ] `REVERB_APP_KEY` + `REVERB_APP_SECRET` sudah dirotate
- [ ] Firebase service account lama sudah di-disable/delete
- [ ] Firebase credentials baru sudah di-upload ke Fly.io
- [ ] Git history sudah dibersihkan
- [ ] `.gitignore` sudah diupdate
- [ ] `git push --force` sudah dilakukan
- [ ] Test login masih bisa jalan setelah rotate

---

## Cara Verifikasi Fly.io Secrets Sudah Terupdate

```powershell
fly secrets list --app mangansage-api
fly secrets list --app mangansage-reverb
```

Akan tampil nama secret (tapi bukan nilainya). Pastikan semua secret yang dirotate ada di list.
