@echo off
echo ========================================
echo   Deploying ManganSage to Cloud Run
echo ========================================
echo.

cd backend

gcloud run deploy mangansage-api ^
  --source . ^
  --region asia-southeast1 ^
  --allow-unauthenticated ^
  --port 8080 ^
  --memory 1Gi ^
  --cpu 1 ^
  --timeout 300 ^
  --min-instances 0 ^
  --max-instances 10 ^
  --env-vars-file .docker\production.env.yaml ^
  --quiet

if errorlevel 1 (
    echo.
    echo [ERROR] Deployment failed!
    pause
    exit /b 1
)

cd ..

echo.
echo ========================================
echo          DEPLOYMENT COMPLETE!
echo ========================================
echo.
echo Admin UI: https://mangansage-api-722613562569.asia-southeast1.run.app/admin/users
echo.
pause
