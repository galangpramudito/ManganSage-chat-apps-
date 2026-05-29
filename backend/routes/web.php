<?php

use App\Http\Controllers\Admin\UserManagementController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return redirect()->route('admin.users.index');
});

// Test OTP email (development only)
if (app()->environment('local')) {
    Route::get('/test-otp', function () {
        $user = \App\Models\User::first();
        if (!$user) {
            return 'No users found. Run: php artisan db:seed';
        }
        
        \Mail::to($user->email)->send(new \App\Mail\OtpMail('123456', $user->name));
        
        return 'OTP email sent! Check storage/logs/laravel.log or run: php artisan otp:show';
    });
}

Route::prefix('admin')->name('admin.')->group(function () {
    Route::resource('users', UserManagementController::class);
});
