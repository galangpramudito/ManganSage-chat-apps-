<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class FcmTokenTest extends TestCase
{
    use RefreshDatabase;

    public function test_update_saves_fcm_token(): void
    {
        $user = User::factory()->create(['fcm_token' => null]);
        Sanctum::actingAs($user);

        $this->postJson('/api/user/fcm-token', ['fcm_token' => 'device-token-abc'])
            ->assertOk()
            ->assertJson(['message' => 'Token updated']);

        $this->assertSame('device-token-abc', $user->fresh()->fcm_token);
    }

    public function test_update_overwrites_existing_token(): void
    {
        $user = User::factory()->create(['fcm_token' => 'old-token']);
        Sanctum::actingAs($user);

        $this->postJson('/api/user/fcm-token', ['fcm_token' => 'new-token'])->assertOk();

        $this->assertSame('new-token', $user->fresh()->fcm_token);
    }

    public function test_update_validates_required(): void
    {
        Sanctum::actingAs(User::factory()->create());

        $this->postJson('/api/user/fcm-token', [])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['fcm_token']);
    }

    public function test_update_requires_auth(): void
    {
        $this->postJson('/api/user/fcm-token', ['fcm_token' => 'x'])->assertUnauthorized();
    }
}
