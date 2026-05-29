<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Tabel `password_reset_otps` — flow lupa password berbasis OTP 6-digit.
 * Mengganti tabel default `password_reset_tokens` (link-based) yang tidak
 * dipakai (kita pakai OTP via email).
 *
 * Flow:
 * 1. POST /api/forgot-password (email) → buat OTP, simpan hash, kirim email
 * 2. POST /api/verify-otp (email, otp) → verifikasi → return reset_token
 * 3. POST /api/reset-password (reset_token, password) → ganti password
 */
return new class extends Migration {
    public function up(): void
    {
        Schema::create('password_reset_otps', function (Blueprint $table) {
            $table->id();
            $table->string('email')->index();
            $table->string('otp_hash');
            $table->string('reset_token')->nullable()->unique(); // di-set setelah OTP diverifikasi
            $table->timestamp('expires_at')->index();
            $table->timestamp('used_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('password_reset_otps');
    }
};
