<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * Feature test untuk endpoint auth.
 * Cover: register, login, logout, /user.
 */
class AuthTest extends TestCase
{
    use RefreshDatabase;

    // ─── Register ────────────────────────────────────────────────────────────

    public function test_register_creates_user_and_returns_token(): void
    {
        $response = $this->postJson('/api/register', [
            'name'                  => 'Andi Pratama',
            'email'                 => 'andi@example.com',
            'password'              => 'password123',
            'password_confirmation' => 'password123',
        ]);

        $response->assertCreated()
            ->assertJsonStructure([
                'user'  => ['id', 'name', 'email', 'avatar', 'is_online', 'last_seen'],
                'token',
            ])
            ->assertJsonPath('user.name', 'Andi Pratama')
            ->assertJsonPath('user.email', 'andi@example.com');

        $this->assertDatabaseHas('users', ['email' => 'andi@example.com']);
        $this->assertNotEmpty($response->json('token'));
    }

    public function test_register_validates_required_fields(): void
    {
        $this->postJson('/api/register', [])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['name', 'email', 'password']);
    }

    public function test_register_rejects_password_mismatch(): void
    {
        $this->postJson('/api/register', [
            'name'                  => 'Andi',
            'email'                 => 'andi@example.com',
            'password'              => 'password123',
            'password_confirmation' => 'different456',
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['password']);
    }

    public function test_register_rejects_duplicate_email(): void
    {
        User::factory()->create(['email' => 'taken@example.com']);

        $this->postJson('/api/register', [
            'name'                  => 'Other User',
            'email'                 => 'taken@example.com',
            'password'              => 'password123',
            'password_confirmation' => 'password123',
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['email']);
    }

    // ─── Login ───────────────────────────────────────────────────────────────

    public function test_login_returns_user_and_token_for_valid_credentials(): void
    {
        $user = User::factory()->create([
            'email'    => 'andi@example.com',
            'password' => 'password123', // di-hash otomatis via cast
        ]);

        $response = $this->postJson('/api/login', [
            'email'    => 'andi@example.com',
            'password' => 'password123',
        ]);

        $response->assertOk()
            ->assertJsonStructure(['user' => ['id', 'name', 'email'], 'token'])
            ->assertJsonPath('user.id', $user->id);

        $this->assertNotEmpty($response->json('token'));
    }

    public function test_login_rejects_invalid_credentials(): void
    {
        User::factory()->create([
            'email'    => 'andi@example.com',
            'password' => 'password123',
        ]);

        $this->postJson('/api/login', [
            'email'    => 'andi@example.com',
            'password' => 'wrong-password',
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['email']);
    }

    public function test_login_updates_last_seen_and_marks_online(): void
    {
        $user = User::factory()->create([
            'email'     => 'andi@example.com',
            'password'  => 'password123',
            'last_seen' => null,
            'is_online' => false,
        ]);

        $this->postJson('/api/login', [
            'email'    => 'andi@example.com',
            'password' => 'password123',
        ])->assertOk();

        $fresh = $user->fresh();
        $this->assertNotNull($fresh->last_seen);
        $this->assertTrue((bool) $fresh->is_online);
    }

    // ─── Logout ──────────────────────────────────────────────────────────────

    public function test_logout_revokes_current_token(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $this->postJson('/api/logout')
            ->assertOk()
            ->assertJson(['message' => 'Logged out']);

        $this->assertDatabaseCount('personal_access_tokens', 0);
    }

    public function test_logout_marks_user_offline_and_clears_fcm_token(): void
    {
        $user = User::factory()->create([
            'is_online' => true,
            'fcm_token' => 'device-token-abc',
        ]);
        Sanctum::actingAs($user);

        $this->postJson('/api/logout')->assertOk();

        $fresh = $user->fresh();
        $this->assertFalse((bool) $fresh->is_online);
        $this->assertNotNull($fresh->last_seen);
        $this->assertNull($fresh->fcm_token);
    }

    public function test_logout_requires_auth(): void
    {
        $this->postJson('/api/logout')->assertUnauthorized();
    }

    // ─── /api/user (session validation) ─────────────────────────────────────

    public function test_user_endpoint_returns_authenticated_user(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $this->getJson('/api/user')
            ->assertOk()
            ->assertJsonPath('id', $user->id)
            ->assertJsonPath('email', $user->email);
    }

    public function test_user_endpoint_requires_auth(): void
    {
        $this->getJson('/api/user')->assertUnauthorized();
    }
}
