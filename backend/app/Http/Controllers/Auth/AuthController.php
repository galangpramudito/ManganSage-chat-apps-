<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use App\Http\Requests\Auth\LoginRequest;
use App\Http\Requests\Auth\RegisterRequest;
use App\Http\Resources\UserResource;
use App\Mail\VerificationOtpMail;
use App\Mail\WelcomeMail;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Validation\ValidationException;

/**
 * Endpoint auth — register, login, logout.
 * Mengikuti technical-spec.md §2.1.
 */
class AuthController extends Controller
{
    private const TOKEN_NAME = 'mobile';

    /**
     * POST /api/register — buat user baru + kirim OTP verifikasi.
     */
    public function register(RegisterRequest $request): JsonResponse
    {
        $user = User::create([
            'name'     => $request->string('name')->toString(),
            'email'    => $request->string('email')->toString(),
            'password' => $request->string('password')->toString(),
            'email_verified' => false,
        ]);

        // Generate OTP 6-digit
        $otp = str_pad((string) random_int(0, 999999), 6, '0', STR_PAD_LEFT);
        $user->verification_otp = $otp;
        $user->verification_otp_expires_at = now()->addMinutes(10);
        $user->save();

        // Kirim OTP via email
        Mail::to($user->email)->send(new VerificationOtpMail($otp, $user->name));

        return response()->json([
            'message' => 'Akun berhasil dibuat. Silakan cek email untuk verifikasi.',
            'email' => $user->email,
        ], 201);
    }

    /**
     * POST /api/verify-email — verifikasi OTP dari email.
     */
    public function verifyEmail(Request $request): JsonResponse
    {
        $request->validate([
            'email' => 'required|email',
            'otp' => 'required|string|size:6',
        ]);

        $user = User::where('email', $request->email)->first();

        if (!$user) {
            return response()->json(['message' => 'User tidak ditemukan.'], 404);
        }

        if ($user->email_verified) {
            return response()->json(['message' => 'Email sudah terverifikasi.'], 400);
        }

        if ($user->verification_otp !== $request->otp) {
            return response()->json([
                'message' => 'Kode OTP salah.',
                'errors' => ['otp' => ['Kode OTP tidak valid.']]
            ], 422);
        }

        if (now()->isAfter($user->verification_otp_expires_at)) {
            return response()->json([
                'message' => 'Kode OTP sudah kadaluarsa.',
                'errors' => ['otp' => ['OTP kadaluarsa.']]
            ], 422);
        }

        // Verifikasi berhasil
        $user->email_verified = true;
        $user->verification_otp = null;
        $user->verification_otp_expires_at = null;
        $user->save();

        // Kirim welcome email
        Mail::to($user->email)->send(new WelcomeMail($user->name));

        // Issue token
        $token = $user->createToken(self::TOKEN_NAME)->plainTextToken;

        return response()->json([
            'message' => 'Email berhasil diverifikasi!',
            'user' => UserResource::make($user),
            'token' => $token,
        ]);
    }

    /**
     * POST /api/resend-verification — kirim ulang OTP.
     */
    public function resendVerification(Request $request): JsonResponse
    {
        $request->validate(['email' => 'required|email']);

        $user = User::where('email', $request->email)->first();

        if (!$user) {
            return response()->json(['message' => 'User tidak ditemukan.'], 404);
        }

        if ($user->email_verified) {
            return response()->json(['message' => 'Email sudah terverifikasi.'], 400);
        }

        // Generate OTP baru
        $otp = str_pad((string) random_int(0, 999999), 6, '0', STR_PAD_LEFT);
        $user->verification_otp = $otp;
        $user->verification_otp_expires_at = now()->addMinutes(10);
        $user->save();

        Mail::to($user->email)->send(new VerificationOtpMail($otp, $user->name));

        return response()->json(['message' => 'Kode OTP baru telah dikirim.']);
    }

    /**
     * POST /api/login — verifikasi credential, issue token baru.
     */
    public function login(LoginRequest $request): JsonResponse
    {
        $user = User::where('email', $request->string('email')->toString())->first();

        if (! $user || ! Hash::check($request->string('password')->toString(), $user->password)) {
            throw ValidationException::withMessages([
                'email' => __('auth.failed'),
            ]);
        }

        // Cek apakah email sudah diverifikasi
        if (!$user->email_verified) {
            return response()->json([
                'message' => 'Email belum diverifikasi. Silakan cek inbox Anda.',
                'email' => $user->email,
                'requires_verification' => true,
            ], 403);
        }

        // Update last_seen + is_online — menandai sesi aktif.
        $user->forceFill([
            'last_seen' => now(),
            'is_online' => true,
        ])->save();

        $token = $user->createToken(self::TOKEN_NAME)->plainTextToken;

        return response()->json([
            'user'  => UserResource::make($user),
            'token' => $token,
        ]);
    }

    /**
     * POST /api/logout — revoke token aktif + tandai offline.
     */
    public function logout(Request $request): JsonResponse
    {
        $user = $request->user();

        $user->forceFill([
            'is_online' => false,
            'last_seen' => now(),
            // Bersihkan FCM token — supaya notif tidak dikirim ke device yang
            // sudah logout (atau tetap dipakai user lain di device sama).
            'fcm_token' => null,
        ])->save();

        $user->currentAccessToken()->delete();

        return response()->json(['message' => 'Logged out']);
    }
}
