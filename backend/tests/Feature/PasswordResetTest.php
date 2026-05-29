<?php

namespace Tests\Feature;

use App\Mail\OtpMail;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Tests\TestCase;

class PasswordResetTest extends TestCase
{
    use RefreshDatabase;

    public function test_forgot_password_sends_otp()
    {
        Mail::fake();
        $user = User::factory()->create(['email' => 'test@example.com']);

        $response = $this->postJson('/api/forgot-password', ['email' => 'test@example.com']);

        $response->assertOk();
        Mail::assertSent(OtpMail::class, fn ($mail) => $mail->hasTo('test@example.com'));
        $this->assertDatabaseHas('password_reset_otps', ['email' => 'test@example.com']);
    }

    public function test_forgot_password_anti_enumeration()
    {
        Mail::fake();

        $response = $this->postJson('/api/forgot-password', ['email' => 'nonexistent@example.com']);

        $response->assertOk();
        Mail::assertNothingSent();
    }

    public function test_verify_otp_success()
    {
        $user = User::factory()->create(['email' => 'test@example.com']);
        $otp = '123456';
        DB::table('password_reset_otps')->insert([
            'email' => 'test@example.com',
            'otp_hash' => Hash::make($otp),
            'expires_at' => now()->addMinutes(10),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $response = $this->postJson('/api/verify-otp', [
            'email' => 'test@example.com',
            'otp' => $otp,
        ]);

        $response->assertOk()->assertJsonStructure(['reset_token']);
    }

    public function test_verify_otp_invalid()
    {
        $user = User::factory()->create(['email' => 'test@example.com']);
        DB::table('password_reset_otps')->insert([
            'email' => 'test@example.com',
            'otp_hash' => Hash::make('123456'),
            'expires_at' => now()->addMinutes(10),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $response = $this->postJson('/api/verify-otp', [
            'email' => 'test@example.com',
            'otp' => '999999',
        ]);

        $response->assertStatus(422);
    }

    public function test_reset_password_success()
    {
        $user = User::factory()->create(['email' => 'test@example.com', 'password' => Hash::make('oldpass')]);
        $token = 'valid-reset-token';
        DB::table('password_reset_otps')->insert([
            'email' => 'test@example.com',
            'otp_hash' => Hash::make('123456'),
            'reset_token' => $token,
            'expires_at' => now()->addMinutes(10),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $response = $this->postJson('/api/reset-password', [
            'reset_token' => $token,
            'password' => 'newpassword123',
            'password_confirmation' => 'newpassword123',
        ]);

        $response->assertOk();
        $user->refresh();
        $this->assertTrue(Hash::check('newpassword123', $user->password));
        $this->assertDatabaseHas('password_reset_otps', [
            'email' => 'test@example.com',
            'reset_token' => $token,
        ]);
        $this->assertNotNull(DB::table('password_reset_otps')->where('email', 'test@example.com')->first()->used_at);
    }

    public function test_reset_password_revokes_tokens()
    {
        $user = User::factory()->create(['email' => 'test@example.com']);
        $token = $user->createToken('test')->plainTextToken;
        $resetToken = 'valid-reset-token';
        
        DB::table('password_reset_otps')->insert([
            'email' => 'test@example.com',
            'otp_hash' => Hash::make('123456'),
            'reset_token' => $resetToken,
            'expires_at' => now()->addMinutes(10),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $this->postJson('/api/reset-password', [
            'reset_token' => $resetToken,
            'password' => 'newpass123',
            'password_confirmation' => 'newpass123',
        ]);

        $this->assertCount(0, $user->tokens);
    }
}
