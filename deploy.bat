@echo off
REM ────────────────────────────────────────────────────────────────────────
REM  deploy.bat — DEPRECATED, redirect ke deploy.ps1 (Oracle Cloud)
REM ────────────────────────────────────────────────────────────────────────
REM  Project sudah migrasi dari Cloud Run → Oracle Cloud VM.
REM  Lihat ORACLE_DEPLOY.md untuk panduan lengkap.
REM ────────────────────────────────────────────────────────────────────────

echo.
echo [DEPRECATED] deploy.bat sudah tidak dipakai (Cloud Run dropped).
echo.
echo Oracle Cloud deploy:
echo   .\deploy.ps1 -VmIp ^<VM_PUBLIC_IP^>
echo.
echo Setup pertama kali:
echo   Lihat ORACLE_DEPLOY.md
echo.
pause
exit /b 1
