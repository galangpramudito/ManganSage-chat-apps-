<?php

namespace App\Http\Controllers;

use App\Http\Resources\UserResource;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class ProfileController extends Controller
{
    /**
     * GET /api/profile
     */
    public function show(Request $request)
    {
        return UserResource::make($request->user());
    }

    /**
     * PUT /api/profile
     */
    public function update(Request $request)
    {
        $user = $request->user();

        $validated = $request->validate([
            'name' => 'sometimes|string|max:255',
            'email' => ['sometimes', 'email', Rule::unique('users')->ignore($user->id)],
            'avatar' => 'sometimes|nullable|string|max:8', // emoji avatar
        ]);

        if (isset($validated['name'])) {
            $user->name = $validated['name'];
        }

        if (array_key_exists('avatar', $validated)) {
            $user->avatar = $validated['avatar'];
        }

        if (isset($validated['email'])) {
            // Jika email berubah, perlu verifikasi ulang
            if ($user->email !== $validated['email']) {
                $user->email = $validated['email'];
                $user->email_verified = false;

                // Generate OTP baru
                $otp = str_pad((string) random_int(0, 999999), 6, '0', STR_PAD_LEFT);
                $user->verification_otp = $otp;
                $user->verification_otp_expires_at = now()->addMinutes(10);

                \Mail::to($user->email)->send(new \App\Mail\VerificationOtpMail($otp, $user->name));
            }
        }

        $user->save();

        return response()->json([
            'message' => 'Profile berhasil diupdate.',
            'user' => UserResource::make($user),
            'requires_verification' => isset($validated['email']) && $user->email !== $request->user()->email,
        ]);
    }

    /**
     * DELETE /api/profile/avatar — reset emoji avatar.
     */
    public function deleteAvatar(Request $request)
    {
        $user = $request->user();
        $user->avatar = null;
        $user->save();

        return response()->json([
            'message' => 'Avatar berhasil dihapus.',
            'user' => UserResource::make($user),
        ]);
    }
}
