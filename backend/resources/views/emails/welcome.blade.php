<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 40px 20px; }
        .container { max-width: 600px; margin: 0 auto; background: white; border-radius: 16px; overflow: hidden; box-shadow: 0 20px 60px rgba(0,0,0,0.3); }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 50px 30px; text-align: center; position: relative; }
        .header::after { content: ''; position: absolute; bottom: -2px; left: 0; right: 0; height: 4px; background: linear-gradient(90deg, #667eea, #764ba2, #667eea); }
        .header img { max-width: 120px; height: auto; margin-bottom: 20px; filter: brightness(0) invert(1); }
        .header h1 { color: white; font-size: 32px; font-weight: 700; margin: 0 0 10px 0; }
        .header p { color: rgba(255,255,255,0.9); font-size: 16px; }
        .content { padding: 50px 40px; }
        .welcome-badge { display: inline-block; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 8px 20px; border-radius: 20px; font-size: 14px; font-weight: 600; margin-bottom: 20px; }
        .greeting { font-size: 28px; color: #2d3748; margin-bottom: 20px; font-weight: 700; }
        .message { font-size: 16px; color: #4a5568; line-height: 1.8; margin-bottom: 20px; }
        .features { background: linear-gradient(135deg, #f7fafc 0%, #edf2f7 100%); border-radius: 12px; padding: 30px; margin: 30px 0; }
        .feature-item { display: flex; align-items: start; margin-bottom: 20px; }
        .feature-item:last-child { margin-bottom: 0; }
        .feature-icon { font-size: 24px; margin-right: 15px; }
        .feature-text { flex: 1; }
        .feature-title { font-size: 16px; font-weight: 600; color: #2d3748; margin-bottom: 5px; }
        .feature-desc { font-size: 14px; color: #718096; line-height: 1.6; }
        .cta-button { display: inline-block; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 15px 40px; border-radius: 8px; text-decoration: none; font-weight: 600; font-size: 16px; margin: 20px 0; box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4); }
        .footer { background: #f7fafc; padding: 30px; text-align: center; border-top: 1px solid #e2e8f0; }
        .footer-text { font-size: 13px; color: #718096; line-height: 1.6; }
        .social-links { margin-top: 20px; }
        .social-links a { display: inline-block; margin: 0 10px; color: #667eea; text-decoration: none; font-size: 14px; font-weight: 500; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <img src="{{ asset('images/logo_mangansage.png') }}" alt="ManganSage">
            <h1>Selamat Datang! 🎉</h1>
            <p>Anda sekarang bagian dari komunitas ManganSage</p>
        </div>
        
        <div class="content">
            <div class="welcome-badge">✨ AKUN TERVERIFIKASI</div>
            
            <div class="greeting">Halo, {{ $userName }}!</div>
            
            <p class="message">
                Terima kasih telah bergabung dengan <strong>ManganSage</strong>! 
                Kami sangat senang Anda menjadi bagian dari komunitas kami.
            </p>
            
            <p class="message">
                ManganSage adalah aplikasi chat real-time yang dirancang untuk 
                membuat komunikasi Anda lebih mudah, cepat, dan menyenangkan.
            </p>
            
            <div class="features">
                <div class="feature-item">
                    <div class="feature-icon">💬</div>
                    <div class="feature-text">
                        <div class="feature-title">Chat Real-Time</div>
                        <div class="feature-desc">Kirim dan terima pesan secara instan tanpa delay</div>
                    </div>
                </div>
                
                <div class="feature-item">
                    <div class="feature-icon">🔔</div>
                    <div class="feature-text">
                        <div class="feature-title">Push Notifications</div>
                        <div class="feature-desc">Tidak akan ketinggalan pesan penting</div>
                    </div>
                </div>
                
                <div class="feature-item">
                    <div class="feature-icon">🔒</div>
                    <div class="feature-text">
                        <div class="feature-title">Aman & Private</div>
                        <div class="feature-desc">Data Anda terlindungi dengan enkripsi</div>
                    </div>
                </div>
                
                <div class="feature-item">
                    <div class="feature-icon">✨</div>
                    <div class="feature-text">
                        <div class="feature-title">UI Modern</div>
                        <div class="feature-desc">Desain minimalis ala iMessage yang elegan</div>
                    </div>
                </div>
            </div>
            
            <center>
                <a href="https://mangansage-api-722613562569.asia-southeast1.run.app" class="cta-button">
                    Mulai Chat Sekarang →
                </a>
            </center>
            
            <p class="message" style="margin-top: 30px;">
                Jika Anda memiliki pertanyaan atau butuh bantuan, jangan ragu untuk menghubungi kami.
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
