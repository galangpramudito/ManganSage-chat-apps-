<#
.SYNOPSIS
  Script otomatis untuk publish update Mangan Group.
  Build APK → Upload ke Supabase Storage → Insert ke tabel app_releases.

.DESCRIPTION
  Jalankan script ini setiap kali kamu mau push update ke user.
  Pastikan kamu sudah menaikkan versi di pubspec.yaml sebelum menjalankan script ini.

.EXAMPLE
  .\publish_update.ps1
  .\publish_update.ps1 -ReleaseNotes "Fix bug login" -ForceUpdate
#>

param(
    [string]$ReleaseNotes = "",
    [switch]$ForceUpdate = $false,
    [switch]$SkipBuild = $false
)

$ErrorActionPreference = "Stop"

# ============================================================
# CONFIG — Sesuaikan ini dengan project kamu
# ============================================================
$SUPABASE_URL      = "https://vcsvbeepbzmcfnwapqog.supabase.co"
$SUPABASE_BUCKET   = "releases"

# Service Role Key (BUKAN anon key) — dibutuhkan untuk upload & insert
# Ambil dari: Supabase Dashboard → Settings → API → service_role (secret)
$SERVICE_ROLE_KEY  = $env:SUPABASE_SERVICE_ROLE_KEY

if (-not $SERVICE_ROLE_KEY) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host " SUPABASE_SERVICE_ROLE_KEY belum di-set!" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Cara set (pilih salah satu):" -ForegroundColor Yellow
    Write-Host ""
    Write-Host '  1. Sementara (session ini saja):' -ForegroundColor Cyan
    Write-Host '     $env:SUPABASE_SERVICE_ROLE_KEY = "eyJhbG..."'
    Write-Host ""
    Write-Host '  2. Permanen (user-level):' -ForegroundColor Cyan
    Write-Host '     [System.Environment]::SetEnvironmentVariable("SUPABASE_SERVICE_ROLE_KEY", "eyJhbG...", "User")'
    Write-Host ""
    Write-Host "Ambil key dari: Supabase Dashboard > Settings > API > service_role (secret)" -ForegroundColor Gray
    exit 1
}

$PROJECT_DIR = $PSScriptRoot

# ============================================================
# 1. Parse versi dari pubspec.yaml
# ============================================================
Write-Host ""
Write-Host "=== MANGAN GROUP — Publish Update ===" -ForegroundColor Cyan
Write-Host ""

$pubspecPath = Join-Path $PROJECT_DIR "pubspec.yaml"
$pubspecContent = Get-Content $pubspecPath -Raw

if ($pubspecContent -match 'version:\s*(\S+)') {
    $fullVersion = $Matches[1]
} else {
    Write-Host "ERROR: Tidak bisa baca versi dari pubspec.yaml" -ForegroundColor Red
    exit 1
}

# Parse "1.3.0+3" → version = "1.3.0", buildNumber = 3
if ($fullVersion -match '^(.+)\+(\d+)$') {
    $version = $Matches[1]
    $buildNumber = [int]$Matches[2]
} else {
    Write-Host "ERROR: Format versi tidak valid: $fullVersion (harus format X.Y.Z+N)" -ForegroundColor Red
    exit 1
}

$apkFileName = "mangan-group-${version}.apk"
$apkSourcePath = Join-Path $PROJECT_DIR "build\app\outputs\flutter-apk\app-release.apk"

Write-Host "  Version     : $version" -ForegroundColor White
Write-Host "  Build Number: $buildNumber" -ForegroundColor White
Write-Host "  APK Name    : $apkFileName" -ForegroundColor White
Write-Host ""

# ============================================================
# 2. Tanya release notes (jika belum di-set via parameter)
# ============================================================
if (-not $ReleaseNotes) {
    $ReleaseNotes = Read-Host "Catatan update (kosongkan jika tidak ada)"
}

$forceUpdateStr = if ($ForceUpdate) { "true" } else { "false" }

Write-Host ""
Write-Host "  Release Notes : $( if ($ReleaseNotes) { $ReleaseNotes } else { '(kosong)' } )" -ForegroundColor White
Write-Host "  Force Update  : $forceUpdateStr" -ForegroundColor White
Write-Host ""

# ============================================================
# 3. Build APK
# ============================================================
if (-not $SkipBuild) {
    Write-Host "[1/3] Building APK..." -ForegroundColor Yellow
    Push-Location $PROJECT_DIR
    flutter build apk --release
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Build gagal!" -ForegroundColor Red
        Pop-Location
        exit 1
    }
    Pop-Location
    Write-Host "[1/3] Build selesai!" -ForegroundColor Green
} else {
    Write-Host "[1/3] Build di-skip (--SkipBuild)" -ForegroundColor Gray
}

# Pastikan file APK ada
if (-not (Test-Path $apkSourcePath)) {
    Write-Host "ERROR: File APK tidak ditemukan di: $apkSourcePath" -ForegroundColor Red
    exit 1
}

$apkSize = [math]::Round((Get-Item $apkSourcePath).Length / 1MB, 2)
Write-Host "  APK size: ${apkSize} MB" -ForegroundColor Gray

# Calculate SHA-256 checksum untuk security verification
Write-Host "  Calculating SHA-256 checksum..." -ForegroundColor Gray
$apkHash = (Get-FileHash -Path $apkSourcePath -Algorithm SHA256).Hash.ToLower()
Write-Host "  SHA-256: $apkHash" -ForegroundColor Gray

# ============================================================
# 4. Upload APK ke Supabase Storage
# ============================================================
Write-Host ""
Write-Host "[2/3] Uploading APK ke Supabase Storage..." -ForegroundColor Yellow

$uploadUrl = "$SUPABASE_URL/storage/v1/object/$SUPABASE_BUCKET/$apkFileName"
$apkBytes = [System.IO.File]::ReadAllBytes($apkSourcePath)

try {
    # Coba update dulu (jika file sudah ada)
    $response = Invoke-RestMethod -Uri $uploadUrl -Method Put `
        -Headers @{
            "Authorization" = "Bearer $SERVICE_ROLE_KEY"
            "Content-Type"  = "application/vnd.android.package-archive"
            "x-upsert"     = "true"
        } `
        -Body $apkBytes

    Write-Host "[2/3] Upload selesai!" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Upload gagal — $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "       Pastikan bucket '$SUPABASE_BUCKET' sudah ada di Supabase Storage" -ForegroundColor Gray
    exit 1
}

$downloadUrl = "$SUPABASE_URL/storage/v1/object/public/$SUPABASE_BUCKET/$apkFileName"
Write-Host "  URL: $downloadUrl" -ForegroundColor Gray

# ============================================================
# 5. Insert row ke tabel app_releases
# ============================================================
Write-Host ""
Write-Host "[3/3] Insert ke tabel app_releases..." -ForegroundColor Yellow

$insertUrl = "$SUPABASE_URL/rest/v1/app_releases"
$body = @{
    version       = $version
    build_number  = $buildNumber
    download_url  = $downloadUrl
    release_notes = if ($ReleaseNotes) { $ReleaseNotes } else { $null }
    force_update  = $ForceUpdate.IsPresent
    sha256_checksum = $apkHash
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri $insertUrl -Method Post `
        -Headers @{
            "Authorization" = "Bearer $SERVICE_ROLE_KEY"
            "apikey"        = $SERVICE_ROLE_KEY
            "Content-Type"  = "application/json"
            "Prefer"        = "return=representation"
        } `
        -Body $body

    Write-Host "[3/3] Insert selesai!" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Insert gagal — $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "       Pastikan tabel 'app_releases' sudah dibuat di Supabase" -ForegroundColor Gray
    exit 1
}

# ============================================================
# DONE
# ============================================================
Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host " PUBLISH BERHASIL!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "  App       : Mangan Group" -ForegroundColor White
Write-Host "  Version   : v$version (build $buildNumber)" -ForegroundColor White
Write-Host "  APK URL   : $downloadUrl" -ForegroundColor White
Write-Host "  Force     : $forceUpdateStr" -ForegroundColor White
Write-Host ""
Write-Host "  Semua user akan mendapat notifikasi update" -ForegroundColor Cyan
Write-Host "  saat membuka aplikasi." -ForegroundColor Cyan
Write-Host ""
