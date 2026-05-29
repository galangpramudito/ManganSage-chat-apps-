<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

/**
 * Email berisi 6-digit OTP untuk reset password.
 * Dipicu oleh `PasswordResetController::sendOtp`.
 */
class PasswordResetOtpMail extends Mailable
{
    use Queueable;
    use SerializesModels;

    public function __construct(
        public readonly string $otp,
        public readonly string $userName,
        public readonly int $expiresInMinutes = 10,
    ) {}

    public function envelope(): Envelope
    {
        return new Envelope(
            subject: 'Kode Reset Password Mangansage',
        );
    }

    public function content(): Content
    {
        return new Content(
            view: 'emails.password-reset-otp',
            with: [
                'otp'              => $this->otp,
                'userName'         => $this->userName,
                'expiresInMinutes' => $this->expiresInMinutes,
            ],
        );
    }
}
