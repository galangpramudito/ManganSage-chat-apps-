<?php

use App\Http\Controllers\Auth\AuthController;
use App\Http\Controllers\Auth\PasswordResetController;
use App\Http\Controllers\ConversationController;
use App\Http\Controllers\FcmTokenController;
use App\Http\Controllers\MessageController;
use App\Http\Controllers\UserController;
use App\Http\Resources\UserResource;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Broadcast;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
| Endpoints mengikuti technical-spec.md §2.
*/

// ─── Public ────────────────────────────────────────────────────────────────
Route::post('/register', [AuthController::class, 'register']);
Route::post('/verify-email', [AuthController::class, 'verifyEmail'])->middleware('throttle:10,5');
Route::post('/resend-verification', [AuthController::class, 'resendVerification'])->middleware('throttle:3,10');
// throttle: max 5 attempt/menit per IP+email — basic anti brute-force.
Route::post('/login',    [AuthController::class, 'login'])->middleware('throttle:5,1');

// Password reset flow (OTP via email).
Route::post('/forgot-password', [PasswordResetController::class, 'forgotPassword'])
    ->middleware('throttle:3,10'); // 3 OTP per 10 menit per IP — anti spam
Route::post('/verify-otp',     [PasswordResetController::class, 'verifyOtp'])
    ->middleware('throttle:10,5');
Route::post('/reset-password', [PasswordResetController::class, 'resetPassword'])
    ->middleware('throttle:5,5');

// ─── Protected (Sanctum) ───────────────────────────────────────────────────
Route::middleware('auth:sanctum')->group(function () {
    // Auth
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/user', fn (Request $request) =>
        UserResource::make($request->user())->resolve($request)
    );

    // Profile
    Route::get('/profile', [\App\Http\Controllers\ProfileController::class, 'show']);
    Route::put('/profile', [\App\Http\Controllers\ProfileController::class, 'update']);
    Route::delete('/profile/avatar', [\App\Http\Controllers\ProfileController::class, 'deleteAvatar']);

    // FCM
    Route::post('/user/fcm-token', [FcmTokenController::class, 'update']);

    // Users (global contact list)
    Route::get('/users', [UserController::class, 'index']);

    // Conversations
    Route::get('/conversations', [ConversationController::class, 'index']);
    Route::post('/conversations', [ConversationController::class, 'store']);
    Route::delete('/conversations/{conversation}', [ConversationController::class, 'destroy']);

    // Messages
    Route::get('/conversations/{conversation}/messages',  [MessageController::class, 'index']);
    Route::post('/conversations/{conversation}/messages', [MessageController::class, 'store']);
    Route::post('/conversations/{conversation}/read',     [MessageController::class, 'markAsRead']);

    // Broadcasting auth — Sanctum-protected.
    // Flutter akan POST ke `/api/broadcasting/auth` saat subscribe ke
    // private channel di Reverb. Default `/broadcasting/auth` (web auth)
    // tetap ada tapi tidak kita pakai untuk mobile API.
    Route::post('/broadcasting/auth', fn (Request $request) => Broadcast::auth($request));
});
