@echo off
REM ────────────────────────────────────────────────────────────────────────
REM  deploy.bat — Deploy Mangansage ke Fly.io (API + Reverb)
REM
REM  Commit & push ke GitHub dilakukan manual SEBELUM ini. File ini deploy saja.
REM
REM  Pakai:
REM    deploy.bat            -> deploy API + Reverb
REM    deploy.bat migrate    -> deploy, lalu jalankan migrasi
REM ────────────────────────────────────────────────────────────────────────
setlocal
set ROOT=%~dp0
set DOMIGRATE=
if /i "%1"=="migrate" set DOMIGRATE=1

echo === Deploy API ===
fly deploy -c "%ROOT%backend\fly.toml" --app mangansage-api || goto :fail

echo === Deploy Reverb ===
fly deploy -c "%ROOT%backend\fly.reverb.toml" --app mangansage-reverb || goto :fail

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
