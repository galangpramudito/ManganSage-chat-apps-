<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class UsersTest extends TestCase
{
    use RefreshDatabase;

    public function test_index_returns_other_users_excluding_self(): void
    {
        $self  = User::factory()->create(['name' => 'Self']);
        $alice = User::factory()->create(['name' => 'Alice']);
        $bob   = User::factory()->create(['name' => 'Bob']);

        Sanctum::actingAs($self);

        $response = $this->getJson('/api/users');

        $response->assertOk()
            ->assertJsonStructure([
                'data' => [['id', 'name', 'email', 'avatar', 'is_online', 'last_seen']],
            ])
            ->assertJsonCount(2, 'data');

        $names = collect($response->json('data'))->pluck('name')->all();
        $this->assertContains('Alice', $names);
        $this->assertContains('Bob', $names);
        $this->assertNotContains('Self', $names);
    }

    public function test_index_requires_auth(): void
    {
        $this->getJson('/api/users')->assertUnauthorized();
    }

    public function test_index_returns_users_sorted_by_name(): void
    {
        $self = User::factory()->create();
        User::factory()->create(['name' => 'Charlie']);
        User::factory()->create(['name' => 'Alice']);
        User::factory()->create(['name' => 'Bob']);

        Sanctum::actingAs($self);

        $names = collect($this->getJson('/api/users')->json('data'))->pluck('name')->all();
        $this->assertSame(['Alice', 'Bob', 'Charlie'], $names);
    }
}
