<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <title>Kode Reset Password Mangansage</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; background: #F8F9FB; margin: 0; padding: 32px 16px; color: #0D1117; }
        .card { max-width: 480px; margin: 0 auto; background: #FFFFFF; border-radius: 16px; padding: 32px; box-shadow: 0 1px 3px rgba(0,0,0,0.06); }
        h1 { margin: 0 0 12px; font-size: 22px; color: #0A84FF; }
        p { margin: 0 0 16px; line-height: 1.6; color: #0D1117; }
        .otp-box { background: #E8F2FF; border-radius: 12px; padding: 24px; margin: 24px 0; text-align: center; }
        .otp-code { font-size: 36px; letter-spacing: 8px; font-weight: 700; color: #0A84FF; font-variant-numeric: tabular-nums; }
        .footer { margin-top: 32px; font-size: 12px; color: #8A94A6; text-align: center; }
    </style>
</head>
<body>
    <div class="card">
        <h1>Reset Password</h1>
        <p>Halo {{ $userName }},</p>
        <p>Kami menerima permintaan untuk me-reset password akun Mangansage kamu. Gunakan kode di bawah ini untuk lanjut ke langkah berikutnya:</p>
        <div class="otp-box">
            <div class="otp-code">{{ $otp }}</div>
        </div>
        <p>Kode ini berlaku selama <strong>{{ $expiresInMinutes }} menit</strong>. Jangan bagikan ke siapapun, termasuk yang mengaku dari Mangansage.</p>
        <p>Kalau bukan kamu yang minta, abaikan email ini — password akun kamu tidak akan berubah.</p>
        <div class="footer">
            Email otomatis dari Mangansage. Tidak perlu dibalas.
        </div>
    </div>
</body>
</html>
