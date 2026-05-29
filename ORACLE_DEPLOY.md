# Oracle Cloud Deploy Guide — Mangansage

Panduan step-by-step untuk migrasi dari Cloud Run ke Oracle Cloud Infrastructure (OCI) Free Tier.

> Total waktu: ~30-45 menit (sebagian besar nunggu provisioning + DNS propagation).

---

## Yang Akan Anda Punya Setelah Selesai

```
Internet
  ↓ HTTPS (port 443)
Caddy (reverse proxy + Let's Encrypt SSL otomatis)
  ↓
  ├── /app/*, /apps/*  → Reverb container (WebSocket)
  └── lainnya          → FrankenPHP container (Laravel API)

Database: Neon Postgres (cloud, tidak berubah)
```

Semua running di 1 VM Oracle Free Tier (4 OCPU + 24GB RAM ARM Ampere A1, **gratis selamanya**).

---

## Phase 1 — Setup Akun Oracle Cloud

### 1.1. Daftar
- Buka [oracle.com/cloud/free](https://www.oracle.com/cloud/free/)
- Klik **Start for free** → daftar dengan email
- **Wajib** masukkan kartu kredit (untuk verifikasi identity, **tidak akan ditagih** untuk Always Free resources)
- Pilih home region — **Singapore** (`ap-singapore-1`) atau **Tokyo** (`ap-tokyo-1`) untuk latency rendah dari Indonesia
- Verifikasi email + nomor HP

> Home region tidak bisa diganti setelah set, jadi pilih hati-hati.

### 1.2. Generate SSH Key (di laptop Windows)

```powershell
# PowerShell — buat key baru khusus Oracle VM
ssh-keygen -t ed25519 -f $HOME\.ssh\oracle_vm -C "mangansage-oracle"
# Tekan Enter 2x untuk passphrase kosong (atau set kalau mau)

# Copy public key ke clipboard (akan di-paste saat create VM)
Get-Content $HOME\.ssh\oracle_vm.pub | Set-Clipboard
```

---

## Phase 2 — Provision VM

### 2.1. Buat Compute Instance

1. Login ke [cloud.oracle.com](https://cloud.oracle.com)
2. Hamburger menu → **Compute** → **Instances** → **Create instance**
3. Isi form:
   - **Name**: `mangansage-vm`
   - **Image and shape**: klik **Edit** →
     - **Image**: Canonical Ubuntu 24.04
     - **Shape**: klik **Change shape** → pilih **Ampere** (ARM) → **VM.Standard.A1.Flex**
     - **OCPU**: 4 (max free tier)
     - **Memory**: 24 GB (max free tier)
   - **Networking**: pakai default VCN (otomatis dibuat)
     - **Public IPv4 address**: ✅ **Assign a public IPv4 address**
   - **SSH keys**: pilih **Paste public keys** → paste dari clipboard (langkah 1.2)
4. Klik **Create**
5. Tunggu ~2 menit sampai status **Running**, catat **Public IP Address**

> Kalau muncul "Out of capacity" untuk ARM, coba beberapa kali atau pilih AD (Availability Domain) yang lain.

### 2.2. Buka Port di OCI Security List

Free tier punya 2 layer firewall — VCN security list **DAN** iptables di VM. Buka di OCI dulu:

1. Hamburger menu → **Networking** → **Virtual Cloud Networks**
2. Pilih VCN Anda → **Security Lists** → **Default Security List**
3. **Add Ingress Rules**:
   | Source CIDR | Protocol | Dest. Ports | Description |
   |---|---|---|---|
   | `0.0.0.0/0` | TCP | `80` | HTTP |
   | `0.0.0.0/0` | TCP | `443` | HTTPS |

> Port 8080 (Reverb) **tidak perlu** dibuka — Caddy yang akan proxy ke sana di internal network Docker.

---

## Phase 3 — Bootstrap VM

### 3.1. SSH ke VM

```powershell
# Di laptop Windows
ssh -i $HOME\.ssh\oracle_vm ubuntu@<VM_PUBLIC_IP>
```

> `ubuntu` adalah default user untuk Canonical Ubuntu image. Untuk Oracle Linux pakai `opc`.

### 3.2. Run Bootstrap Script

Dari **laptop**, upload script ke VM:

```powershell
scp -i $HOME\.ssh\oracle_vm oracle-vm-bootstrap.sh ubuntu@<VM_PUBLIC_IP>:~
```

Lalu di **VM** (via SSH):

```bash
chmod +x oracle-vm-bootstrap.sh
./oracle-vm-bootstrap.sh

# Logout & login ulang biar group docker aktif
exit
```

```powershell
# Login ulang
ssh -i $HOME\.ssh\oracle_vm ubuntu@<VM_PUBLIC_IP>
docker --version       # verify
docker compose version # verify
```

---

## Phase 4 — Deploy Pertama

### 4.1. Set Env Variables di Laptop (Optional, supaya tidak ngetik berulang)

```powershell
# Edit profile PowerShell (jadi persistent)
notepad $PROFILE
# Tambahkan:
$env:ORACLE_VM_IP   = "<VM_PUBLIC_IP>"
$env:ORACLE_VM_USER = "ubuntu"
$env:ORACLE_SSH_KEY = "$HOME\.ssh\oracle_vm"
```

### 4.2. Deploy Pertama

```powershell
cd Z:\PROJECTS\VsCode\Mangansage
.\deploy.ps1 -VmIp <VM_PUBLIC_IP>
```

Script akan:
1. Test SSH connection
2. Tar + upload backend ke VM
3. Cek `.env.production` — **akan FAIL** di sini karena belum ada. Itu normal.

### 4.3. Setup `.env.production` di VM

```bash
# SSH ke VM
ssh -i $HOME\.ssh\oracle_vm ubuntu@<VM_PUBLIC_IP>
cd ~/mangansage

cp .env.production.example .env.production
nano .env.production
```

**Yang wajib diisi:**

| Key | Cara dapat |
|---|---|
| `APP_KEY` | Run di VM: `docker run --rm -v $(pwd):/app -w /app dunglas/frankenphp:latest php artisan key:generate --show` (atau setelah deploy: `docker compose exec app php artisan key:generate --show`) |
| `APP_URL` | `http://<VM_IP>` untuk testing, atau `https://<DOMAIN>` setelah DNS aktif |
| `DB_URL` | Copy dari Neon dashboard → Connection string (pooler URL untuk runtime) |
| `REVERB_APP_ID` | Random angka, mis. `1001` |
| `REVERB_APP_KEY` | Random 20 char, mis. `php -r "echo bin2hex(random_bytes(10));"` |
| `REVERB_APP_SECRET` | Random 40 char, mis. `php -r "echo bin2hex(random_bytes(20));"` |
| `REVERB_HOST` | `<DOMAIN>` atau `<VM_IP>` |
| `MAIL_USERNAME`, `MAIL_PASSWORD` | Gmail + App Password (https://myaccount.google.com/apppasswords) |
| `DOMAIN` | Domain Anda (atau biarkan kosong / `:80` untuk HTTP-only) |
| `ACME_EMAIL` | Email Anda untuk Let's Encrypt |

Save (Ctrl+O, Enter, Ctrl+X).

### 4.4. Deploy Ulang (Build Container)

```powershell
# Dari laptop
.\deploy.ps1 -VmIp <VM_PUBLIC_IP>
```

Tunggu ~3-5 menit untuk first build (Docker pull base image + composer install).

### 4.5. Run Database Migration

```bash
# SSH ke VM
ssh -i $HOME\.ssh\oracle_vm ubuntu@<VM_PUBLIC_IP>
cd ~/mangansage

docker compose exec app php artisan migrate --force
docker compose exec app php artisan storage:link

# Optional — seed data dummy
docker compose exec app php artisan db:seed --force
```

### 4.6. Test

```powershell
# Dari laptop
curl http://<VM_IP>/api/user
# Expected: HTTP 401 Unauthorized → ✓ backend hidup
```

---

## Phase 5 — Domain + HTTPS (Optional tapi Recommended)

### 5.1. Setup DNS

Di registrar / Cloudflare:
- **A record**: `api.yourdomain.com` → `<VM_PUBLIC_IP>`
- TTL: 300 (5 menit)

Tunggu DNS propagation (~5-30 menit, cek pakai `nslookup api.yourdomain.com`).

### 5.2. Update `.env.production` di VM

```bash
ssh -i $HOME\.ssh\oracle_vm ubuntu@<VM_PUBLIC_IP>
cd ~/mangansage
nano .env.production
```

Update:
```
APP_URL=https://api.yourdomain.com
DOMAIN=api.yourdomain.com
REVERB_HOST=api.yourdomain.com
```

```bash
# Restart Caddy untuk pick up domain baru → auto-issue SSL cert
docker compose up -d
docker compose logs -f caddy
# Tunggu sampai muncul "certificate obtained successfully"
```

### 5.3. Test HTTPS

```powershell
curl https://api.yourdomain.com/api/user
# Expected: HTTP 401 ✓
```

---

## Phase 6 — Update Flutter App

Edit `app/lib/core/constants/api_constants.dart`:

```dart
static const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://api.yourdomain.com/api',  // ← update ini
);
```

Atau pass via `--dart-define` saat build:

```powershell
cd app
flutter build apk --release `
  --dart-define=API_BASE_URL=https://api.yourdomain.com/api `
  --dart-define=REVERB_HOST=api.yourdomain.com `
  --dart-define=REVERB_PORT=443 `
  --dart-define=REVERB_FORCE_TLS=true `
  --dart-define=REVERB_APP_KEY=<isi_dari_.env.production>
```

---

## Operasi Sehari-hari

### Deploy Update (perubahan code)

```powershell
.\deploy.ps1 -VmIp <VM_IP>
```

### Restart Tanpa Rebuild (perubahan env saja)

```powershell
.\deploy.ps1 -VmIp <VM_IP> -NoBuild
```

### Tail Logs

```powershell
ssh -i $HOME\.ssh\oracle_vm ubuntu@<VM_IP> 'cd ~/mangansage; docker compose logs -f app'
```

Atau service spesifik: `app`, `reverb`, `caddy`, `queue`.

### Restart 1 Service

```bash
docker compose restart app
```

### Migration

```bash
docker compose exec app php artisan migrate --force
```

### Tinker / Artisan Commands

```bash
docker compose exec app php artisan tinker
docker compose exec app php artisan otp:show
docker compose exec app php artisan email:test
```

### Backup `app_storage` Volume

```bash
docker run --rm \
  -v mangansage_app_storage:/data \
  -v $HOME/backups:/backup \
  alpine tar czf /backup/storage-$(date +%F).tar.gz -C /data .
```

---

## Troubleshooting

### "Cannot connect to VM"
- Cek IP benar (Public IP, bukan Private IP)
- Cek Security List di OCI Console — port 22, 80, 443 dibuka
- Cek iptables di VM: `sudo iptables -L INPUT -n --line-numbers`

### "docker compose: command not found" di VM
- Bootstrap script belum jalan, atau belum logout/login setelah usermod
- Run ulang: `./oracle-vm-bootstrap.sh`

### Caddy gagal issue cert (HTTPS tidak jalan)
- DNS belum propagate — cek `dig api.yourdomain.com` dari VM
- Port 80 di Security List belum dibuka — Let's Encrypt butuh HTTP-01 challenge
- Cek log: `docker compose logs caddy | grep -i "tls\|acme\|error"`

### Out of memory saat build
- Container build butuh ~1GB RAM. Free tier 1GB micro tidak cukup.
- Pastikan Anda pakai **Ampere A1 (24GB)**, bukan E2 Micro.
- Atau build image di laptop lalu push ke registry (lihat advanced docs).

### Database connection error
- Neon Postgres punya IP allowlist disabled by default — harusnya jalan dari mana saja
- Cek `DB_URL` di `.env.production` (pakai `?sslmode=require&channel_binding=require`)
- Test dari VM: `docker compose exec app php artisan tinker → DB::connection()->getPdo()`

---

## Decommission Cloud Run (kalau sudah tidak butuh)

```powershell
# Dari laptop
gcloud run services delete mangansage-api --region asia-southeast1
gcloud artifacts repositories delete mangansage --location asia-southeast1
```

Atau biarkan saja — billing sudah disabled, tidak akan kena charge.

---

## Cost Summary

| Resource | Tier | Cost |
|---|---|---|
| VM Ampere A1 4 OCPU + 24GB | Always Free | $0 |
| 50GB Block Storage | Always Free | $0 |
| 10TB egress/month | Always Free | $0 |
| Public IP | Always Free | $0 |
| Domain | Manual (mis. Namecheap) | ~$10/tahun |
| Neon Postgres | Free tier | $0 |
| Let's Encrypt SSL | Free | $0 |
| **Total** | | **~$0/bulan** (selamanya selama Always Free berlaku) |

> ⚠️ Always Free instances bisa di-reclaim Oracle kalau idle >7 hari. Kasih traffic dummy (uptime monitor) supaya tetap aktif.
