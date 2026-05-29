@echo off
REM ────────────────────────────────────────────────────────────────────────
REM  deploy.bat — Deploy Mangansage ke Fly.io (API + Reverb)
REM
REM  Commit & push ke GitHub dilakukan manual SEBELUM ini. File ini deploy saja.
REM  Wajib cd ke backend dulu: fly pakai folder ini sebagai build context Docker.
REM
REM  Pakai:
REM    deploy.bat            -> deploy API + Reverb
REM    deploy.bat migrate    -> deploy, lalu jalankan migrasi
REM ────────────────────────────────────────────────────────────────────────
setlocal
set DOMIGRATE=
if /i "%1"=="migrate" set DOMIGRATE=1

cd /d "%~dp0backend" || goto :fail

echo === Deploy API ===
fly deploy --config fly.toml --app mangansage-api || goto :fail

echo === Deploy Reverb ===
fly deploy --config fly.reverb.toml --app mangansage-reverb || goto :fail

if defined DOMIGRATE (
    echo === Migrasi DB ===
    fly ssh console --app mangansage-api -C "php artisan migrate --force" || goto :fail
)

echo.
echo Selesai. API: https://mangansage-api.fly.dev
exit /b 0

:fail
echo.
echo [GAGAL] Deploy berhenti karena error di atas.
exit /b 1
