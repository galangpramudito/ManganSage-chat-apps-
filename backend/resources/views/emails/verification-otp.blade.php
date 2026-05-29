<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 40px 20px; }
        .container { max-width: 600px; margin: 0 auto; background: white; border-radius: 16px; overflow: hidden; box-shadow: 0 20px 60px rgba(0,0,0,0.3); }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 40px 30px; text-align: center; position: relative; }
        .header::after { content: ''; position: absolute; bottom: -2px; left: 0; right: 0; height: 4px; background: linear-gradient(90deg, #667eea, #764ba2, #667eea); }
        .header img { max-width: 100px; height: auto; margin-bottom: 15px; filter: brightness(0) invert(1); }
        .header h1 { color: white; font-size: 28px; font-weight: 700; margin: 0; }
        .content { padding: 50px 40px; }
        .greeting { font-size: 24px; color: #2d3748; margin-bottom: 20px; font-weight: 600; }
        .message { font-size: 16px; color: #4a5568; line-height: 1.8; margin-bottom: 30px; }
        .otp-container { background: linear-gradient(135deg, #f7fafc 0%, #edf2f7 100%); border-radius: 12px; padding: 30px; text-align: center; margin: 30px 0; border: 2px dashed #667eea; position: relative; }
        .otp-label { font-size: 14px; color: #718096; text-transform: uppercase; letter-spacing: 1px; margin-bottom: 10px; font-weight: 600; }
        .otp-code { font-size: 48px; font-weight: 800; letter-spacing: 12px; color: #667eea; text-shadow: 2px 2px 4px rgba(102, 126, 234, 0.2); }
        .otp-timer { font-size: 13px; color: #e53e3e; margin-top: 15px; font-weight: 500; }
        .warning { background: #fff5f5; border-left: 4px solid #e53e3e; padding: 15px 20px; border-radius: 8px; margin: 20px 0; }
        .warning-text { font-size: 14px; color: #742a2a; line-height: 1.6; }
        .footer { background: #f7fafc; padding: 30px; text-align: center; border-top: 1px solid #e2e8f0; }
        .footer-text { font-size: 13px; color: #718096; line-height: 1.6; }
        .social-links { margin-top: 20px; }
        .social-links a { display: inline-block; margin: 0 10px; color: #667eea; text-decoration: none; font-size: 14px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <img src="{{ asset('images/logo_mangansage.png') }}" alt="ManganSage">
            <h1>ManganSage</h1>
        </div>
        
        <div class="content">
            <div class="greeting">Halo, {{ $userName }}! 👋</div>
            
            <p class="message">
                Terima kasih telah mendaftar di <strong>ManganSage</strong>. 
                Untuk melanjutkan, silakan verifikasi email Anda dengan memasukkan kode OTP di bawah ini:
            </p>
            
            <div class="otp-container">
                <div class="otp-label">Kode Verifikasi</div>
                <div class="otp-code">{{ $otp }}</div>
                <div class="otp-timer">⏱️ Berlaku selama 10 menit</div>
            </div>
            
            <div class="warning">
                <p class="warning-text">
                    <strong>⚠️ Penting:</strong> Jangan bagikan kode ini kepada siapa pun. 
                    Tim ManganSage tidak akan pernah meminta kode OTP Anda.
                </p>
            </div>
            
            <p class="message">
                Jika Anda tidak mendaftar di ManganSage, abaikan email ini.
            </p>
        </div>
        
        <div class="footer">
            <p class="footer-text">
                &copy; {{ date('Y') }} ManganSage. All rights reserved.<br>
                Real-time chat application for modern communication.
            </p>
            <div class="social-links">
                <a href="#">Help Center</a> • 
                <a href="#">Privacy Policy</a> • 
                <a href="#">Terms of Service</a>
            </div>
        </div>
    </div>
</body>
</html>
