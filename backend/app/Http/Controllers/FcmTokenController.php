<?php

namespace App\Http\Controllers;

use App\Http\Requests\User\UpdateFcmTokenRequest;
use Illuminate\Http\JsonResponse;

/**
 * POST /api/user/fcm-token — update token FCM perangkat user.
 * Mengikuti technical-spec.md §2.5.
 */
class FcmTokenController extends Controller
{
    public function update(UpdateFcmTokenRequest $request): JsonResponse
    {
        $request->user()->forceFill([
            'fcm_token' => $request->validated('fcm_token'),
        ])->save();

        return response()->json(['message' => 'Token updated']);
    }
}
