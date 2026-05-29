<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use App\Mail\OtpMail;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Str;

class PasswordResetController extends Controller
{
    public function forgotPassword(Request $request)
    {
        $request->validate(['email' => 'required|email']);

        $user = User::where('email', $request->email)->first();

        // Anti-enumeration: selalu return sukses
        if (!$user) {
            return response()->json(['message' => 'Jika email terdaftar, OTP akan dikirim.']);
        }

        $otp = str_pad((string) random_int(0, 999999), 6, '0', STR_PAD_LEFT);
        $expiresAt = now()->addMinutes(10);

        // Hapus OTP lama untuk email ini
        DB::table('password_reset_otps')->where('email', $request->email)->delete();

        DB::table('password_reset_otps')->insert([
            'email' => $request->email,
            'otp_hash' => Hash::make($otp),
            'reset_token' => null,
            'expires_at' => $expiresAt,
            'used_at' => null,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        Mail::to($user->email)->send(new OtpMail($otp, $user->name));

        return response()->json(['message' => 'Kode OTP telah dikirim ke email Anda.']);
    }

    public function verifyOtp(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'otp' => 'required|string|size:6',
        ]);

        $record = DB::table('password_reset_otps')
            ->where('email', $request->email)
            ->whereNull('used_at')
            ->first();

        if (!$record) {
            return response()->json(['message' => 'Kode OTP tidak valid.', 'errors' => ['otp' => ['Kode OTP tidak ditemukan.']]], 422);
        }

        if (!Hash::check($request->otp, $record->otp_hash)) {
            return response()->json(['message' => 'Kode OTP tidak valid.', 'errors' => ['otp' => ['Kode OTP salah.']]], 422);
        }

        if (now()->isAfter($record->expires_at)) {
            return response()->json(['message' => 'Kode OTP sudah kadaluarsa.', 'errors' => ['otp' => ['OTP kadaluarsa.']]], 422);
        }

        $resetToken = Str::random(64);

        DB::table('password_reset_otps')
            ->where('id', $record->id)
            ->update(['reset_token' => $resetToken]);

        return response()->json(['reset_token' => $resetToken]);
    }

    public function resetPassword(Request $request)
    {
        $request->validate([
            'reset_token' => 'required|string',
            'password' => 'required|string|min:8|confirmed',
        ]);

        $record = DB::table('password_reset_otps')
            ->where('reset_token', $request->reset_token)
            ->whereNull('used_at')
            ->first();

        if (!$record) {
            return response()->json(['message' => 'Token reset tidak valid.'], 422);
        }

        if (now()->isAfter($record->expires_at)) {
            return response()->json(['message' => 'Token reset sudah kadaluarsa.'], 422);
        }

        $user = User::where('email', $record->email)->first();

        if (!$user) {
            return response()->json(['message' => 'User tidak ditemukan.'], 404);
        }

        $user->password = Hash::make($request->password);
        $user->save();

        // Revoke semua token (logout dari semua device)
        $user->tokens()->delete();

        // Mark OTP sebagai used
        DB::table('password_reset_otps')
            ->where('id', $record->id)
            ->update(['used_at' => now()]);

        return response()->json(['message' => 'Password berhasil direset. Silakan login dengan password baru.']);
    }
}
