# ─── Mangansage — Deploy ke Oracle Cloud VM ─────────────────────────────
#
# Pengganti `deploy.bat` (Cloud Run lama).
#
# Usage:
#   .\deploy.ps1 -VmIp 123.45.67.89
#   .\deploy.ps1 -VmIp 123.45.67.89 -VmUser opc -KeyPath C:\keys\oracle.pem
#   .\deploy.ps1 -VmIp 123.45.67.89 -NoBuild        # restart tanpa rebuild image
#
# Atau set env var sekali, lalu cukup `.\deploy.ps1`:
#   $env:ORACLE_VM_IP   = "123.45.67.89"
#   $env:ORACLE_VM_USER = "ubuntu"
#   $env:ORACLE_SSH_KEY = "$HOME\.ssh\oracle_vm"
#
# Prasyarat:
#   - OpenSSH client di Windows (default ada di Win10+)
#   - tar.exe (default ada di Win10+)
#   - VM sudah di-bootstrap dengan oracle-vm-bootstrap.sh
# ─────────────────────────────────────────────────────────────────────────
[CmdletBinding()]
param(
    [string]$VmIp,
    [string]$VmUser,
    [string]$KeyPath,
    [string]$RemotePath = "~/mangansage",
    [switch]$NoBuild,
    [switch]$SkipUpload
)

$ErrorActionPreference = 'Stop'

# ─── Resolve params dari env var kalau tidak di-pass ──────────────────
if (-not $VmIp)   { $VmIp   = $env:ORACLE_VM_IP }
if (-not $VmUser) { $VmUser = if ($env:ORACLE_VM_USER) { $env:ORACLE_VM_USER } else { 'ubuntu' } }
if (-not $KeyPath){ $KeyPath= if ($env:ORACLE_SSH_KEY) { $env:ORACLE_SSH_KEY } else { "$HOME\.ssh\oracle_vm" } }

if (-not $VmIp) {
    Write-Host "ERROR: VM IP tidak diset." -ForegroundColor Red
    Write-Host "  Pass: .\deploy.ps1 -VmIp <IP>"
    Write-Host "  Atau: `$env:ORACLE_VM_IP = '<IP>'"
    exit 1
}
if (-not (Test-Path $KeyPath)) {
    Write-Host "ERROR: SSH key tidak ditemukan: $KeyPath" -ForegroundColor Red
    Write-Host "  Pass: .\deploy.ps1 -KeyPath <path>"
    exit 1
}

$sshTarget = "${VmUser}@${VmIp}"
$sshOpts   = @(
    '-i', $KeyPath,
    '-o', 'StrictHostKeyChecking=accept-new',
    '-o', 'ConnectTimeout=10'
)

Write-Host ""
Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Deploy Mangansage → $sshTarget" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# ─── 1. Test SSH connection ───────────────────────────────────────────
Write-Host "[1/4] Test SSH connection..." -ForegroundColor Yellow
& ssh @sshOpts $sshTarget 'echo "SSH OK: $(hostname)"'
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Tidak bisa SSH ke VM." -ForegroundColor Red
    exit 1
}

# ─── 2. Upload backend (kecuali kalau -SkipUpload) ─────────────────────
if (-not $SkipUpload) {
    Write-Host "[2/4] Upload backend..." -ForegroundColor Yellow

    $backendDir = Join-Path $PSScriptRoot 'backend'
    if (-not (Test-Path $backendDir)) {
        Write-Host "ERROR: Folder backend/ tidak ditemukan di $PSScriptRoot" -ForegroundColor Red
        exit 1
    }

    $tarFile = Join-Path $env:TEMP "mangansage-deploy-$(Get-Date -Format 'yyyyMMddHHmmss').tar"

    # Build tar dengan exclude (Win10+ punya BSD tar built-in).
    Push-Location $backendDir
    try {
        $excludes = @(
            '--exclude=vendor',
            '--exclude=node_modules',
            '--exclude=.git',
            '--exclude=storage/logs',
            '--exclude=storage/framework/cache/data',
            '--exclude=storage/framework/sessions',
            '--exclude=storage/framework/views',
            '--exclude=bootstrap/cache',
            '--exclude=public/build',
            '--exclude=tests',
            '--exclude=.docker/local.env*',
            '--exclude=.docker/production.env*',
            '--exclude=.env',
            '--exclude=.env.production'
        )
        & tar @excludes -cf $tarFile .
        if ($LASTEXITCODE -ne 0) { throw "tar gagal" }
    } finally {
        Pop-Location
    }

    Write-Host "      → tarball: $((Get-Item $tarFile).Length / 1MB | ForEach-Object { [math]::Round($_, 2) }) MB"

    # Upload tar via scp.
    & ssh @sshOpts $sshTarget "mkdir -p $RemotePath"
    & scp @sshOpts $tarFile "${sshTarget}:/tmp/mangansage-deploy.tar"
    if ($LASTEXITCODE -ne 0) { throw "scp gagal" }

    # Extract di VM.
    & ssh @sshOpts $sshTarget @"
set -e
tar -xf /tmp/mangansage-deploy.tar -C $RemotePath
rm /tmp/mangansage-deploy.tar
"@

    Remove-Item $tarFile -ErrorAction SilentlyContinue
} else {
    Write-Host "[2/4] Skip upload (--SkipUpload)" -ForegroundColor DarkGray
}

# ─── 3. Validasi .env.production di VM ─────────────────────────────────
Write-Host "[3/4] Validasi .env.production..." -ForegroundColor Yellow
$envCheck = & ssh @sshOpts $sshTarget "test -f $RemotePath/.env.production && echo OK || echo MISSING"
if ($envCheck -notmatch 'OK') {
    Write-Host ""
    Write-Host "  ⚠ .env.production belum ada di VM." -ForegroundColor Yellow
    Write-Host "  SSH ke VM dan setup:" -ForegroundColor Yellow
    Write-Host "    ssh -i $KeyPath $sshTarget" -ForegroundColor White
    Write-Host "    cd $RemotePath" -ForegroundColor White
    Write-Host "    cp .env.production.example .env.production" -ForegroundColor White
    Write-Host "    nano .env.production    # isi semua <PLACEHOLDER>" -ForegroundColor White
    Write-Host ""
    Write-Host "  Lalu jalankan ulang: .\deploy.ps1 -VmIp $VmIp" -ForegroundColor White
    exit 1
}

# ─── 4. Build & start containers ───────────────────────────────────────
Write-Host "[4/4] docker compose up..." -ForegroundColor Yellow
$composeCmd = if ($NoBuild) { 'up -d' } else { 'up --build -d' }

& ssh @sshOpts $sshTarget @"
set -e
cd $RemotePath
docker compose $composeCmd
echo ""
echo "─── docker compose ps ────────────────────────"
docker compose ps
"@

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "ERROR: docker compose gagal." -ForegroundColor Red
    Write-Host "  Cek logs: ssh -i $KeyPath $sshTarget 'cd $RemotePath; docker compose logs --tail=100'"
    exit 1
}

Write-Host ""
Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  ✓ Deploy selesai" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "Tail log:"
Write-Host "  ssh -i $KeyPath $sshTarget 'cd $RemotePath; docker compose logs -f app'"
Write-Host ""
Write-Host "Test health:"
Write-Host "  curl http://${VmIp}/api/user      # 401 = backend hidup ✓"
Write-Host ""
