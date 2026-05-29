<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; background: #f5f5f5; margin: 0; padding: 20px; }
        .container { max-width: 600px; margin: 0 auto; background: white; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 8px rgba(0,0,0,0.1); }
        .header { background: #007bff; color: white; padding: 30px 20px; text-align: center; }
        .header img { max-width: 120px; height: auto; margin-bottom: 10px; }
        .header h1 { margin: 0; font-size: 24px; }
        .content { padding: 40px 30px; }
        .otp-box { background: #f8f9fa; border: 2px dashed #007bff; border-radius: 8px; padding: 20px; text-align: center; margin: 30px 0; }
        .otp-code { font-size: 36px; font-weight: bold; letter-spacing: 8px; color: #007bff; }
        .footer { background: #f8f9fa; padding: 20px; text-align: center; font-size: 12px; color: #666; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <img src="{{ asset('images/logo_mangansage.png') }}" alt="ManganSage Logo">
            <h1>ManganSage</h1>
        </div>
        <div class="content">
            <p>Halo <strong>{{ $userName }}</strong>,</p>
            <p>Anda menerima email ini karena ada permintaan reset password untuk akun Anda.</p>
            <p>Gunakan kode OTP berikut untuk melanjutkan:</p>
            
            <div class="otp-box">
                <div class="otp-code">{{ $otp }}</div>
            </div>

            <p><strong>Kode ini berlaku selama 10 menit.</strong></p>
            <p>Jika Anda tidak meminta reset password, abaikan email ini.</p>
        </div>
        <div class="footer">
            <p>&copy; {{ date('Y') }} ManganSage. All rights reserved.</p>
        </div>
    </div>
</body>
</html>
