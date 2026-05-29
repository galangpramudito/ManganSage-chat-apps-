<?php

namespace Tests\Feature;

use App\Models\Conversation;
use App\Models\Message;
use App\Models\MessageRead;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ConversationsTest extends TestCase
{
    use RefreshDatabase;

    // ─── Index ───────────────────────────────────────────────────────────────

    public function test_index_returns_conversations_with_participant_and_last_message(): void
    {
        [$me, $other] = User::factory()->count(2)->create();

        $conversation = Conversation::create();
        $conversation->users()->attach([$me->id, $other->id]);

        // Other sends 2 messages, I send 1.
        $msg1 = $conversation->messages()->create(['sender_id' => $other->id, 'body' => 'Hai']);
        $conversation->messages()->create(['sender_id' => $me->id, 'body' => 'Hai juga']);
        $msg3 = $conversation->messages()->create(['sender_id' => $other->id, 'body' => 'Apa kabar?']);

        // I read msg1 only.
        MessageRead::create(['message_id' => $msg1->id, 'user_id' => $me->id, 'read_at' => now()]);

        Sanctum::actingAs($me);
        $response = $this->getJson('/api/conversations');

        $response->assertOk()
            ->assertJsonStructure([
                'data' => [[
                    'id',
                    'participant'  => ['id', 'name', 'avatar'],
                    'last_message' => ['body', 'created_at', 'is_read'],
                    'unread_count',
                ]],
            ])
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.participant.id', $other->id)
            ->assertJsonPath('data.0.last_message.body', 'Apa kabar?')
            ->assertJsonPath('data.0.unread_count', 1) // hanya msg3 yang belum dibaca
            ->assertJsonPath('data.0.last_message.is_read', false); // last msg dari other, belum saya baca
    }

    public function test_index_excludes_soft_deleted_conversations(): void
    {
        [$me, $other] = User::factory()->count(2)->create();

        $conversation = Conversation::create();
        $conversation->users()->attach([$me->id, $other->id]);
        $conversation->users()->updateExistingPivot($me->id, ['deleted_at' => now()]);

        Sanctum::actingAs($me);
        $this->getJson('/api/conversations')
            ->assertOk()
            ->assertJsonCount(0, 'data');
    }

    public function test_index_sorts_by_latest_message_desc(): void
    {
        [$me, $a, $b] = User::factory()->count(3)->create();

        $conv1 = Conversation::create();
        $conv1->users()->attach([$me->id, $a->id]);
        $msg1 = $conv1->messages()->create(['sender_id' => $a->id, 'body' => 'Lama']);
        $msg1->forceFill(['created_at' => now()->subHour()])->save();

        $conv2 = Conversation::create();
        $conv2->users()->attach([$me->id, $b->id]);
        $conv2->messages()->create(['sender_id' => $b->id, 'body' => 'Baru']);

        Sanctum::actingAs($me);
        $bodies = collect($this->getJson('/api/conversations')->json('data'))
            ->pluck('last_message.body')->all();

        $this->assertSame(['Baru', 'Lama'], $bodies);
    }

    public function test_index_requires_auth(): void
    {
        $this->getJson('/api/conversations')->assertUnauthorized();
    }

    // ─── Store ───────────────────────────────────────────────────────────────

    public function test_store_creates_new_conversation(): void
    {
        [$me, $other] = User::factory()->count(2)->create();
        Sanctum::actingAs($me);

        $response = $this->postJson('/api/conversations', ['user_id' => $other->id]);

        $response->assertCreated()
            ->assertJsonPath('participant.id', $other->id)
            ->assertJsonPath('participant.name', $other->name);

        $this->assertDatabaseCount('conversations', 1);
        $this->assertDatabaseHas('conversation_user', [
            'user_id' => $me->id,
        ]);
    }

    public function test_store_returns_existing_conversation_with_200(): void
    {
        [$me, $other] = User::factory()->count(2)->create();
        $existing = Conversation::create();
        $existing->users()->attach([$me->id, $other->id]);

        Sanctum::actingAs($me);
        $response = $this->postJson('/api/conversations', ['user_id' => $other->id]);

        $response->assertOk()
            ->assertJsonPath('id', $existing->id);

        $this->assertDatabaseCount('conversations', 1);
    }

    public function test_store_restores_soft_deleted_pivot_for_self(): void
    {
        [$me, $other] = User::factory()->count(2)->create();
        $existing = Conversation::create();
        $existing->users()->attach([$me->id, $other->id]);
        $existing->users()->updateExistingPivot($me->id, ['deleted_at' => now()]);

        Sanctum::actingAs($me);
        $this->postJson('/api/conversations', ['user_id' => $other->id])->assertOk();

        $this->assertDatabaseHas('conversation_user', [
            'conversation_id' => $existing->id,
            'user_id'         => $me->id,
            'deleted_at'      => null,
        ]);
    }

    public function test_store_rejects_self_chat(): void
    {
        $me = User::factory()->create();
        Sanctum::actingAs($me);

        $this->postJson('/api/conversations', ['user_id' => $me->id])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['user_id']);
    }

    public function test_store_validates_user_exists(): void
    {
        $me = User::factory()->create();
        Sanctum::actingAs($me);

        $this->postJson('/api/conversations', ['user_id' => 9999])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['user_id']);
    }

    // ─── Destroy ─────────────────────────────────────────────────────────────

    public function test_destroy_soft_deletes_pivot_only_for_self(): void
    {
        [$me, $other] = User::factory()->count(2)->create();
        $conv = Conversation::create();
        $conv->users()->attach([$me->id, $other->id]);

        Sanctum::actingAs($me);
        $this->deleteJson("/api/conversations/{$conv->id}")
            ->assertOk()
            ->assertJson(['message' => 'Conversation removed']);

        $this->assertDatabaseHas('conversation_user', [
            'conversation_id' => $conv->id,
            'user_id'         => $me->id,
        ]);
        $myPivot    = $conv->users()->where('users.id', $me->id)->first()?->pivot;
        $otherPivot = $conv->users()->where('users.id', $other->id)->first()?->pivot;
        $this->assertNotNull($myPivot->deleted_at);
        $this->assertNull($otherPivot->deleted_at);
    }

    public function test_destroy_forbidden_for_non_participant(): void
    {
        [$a, $b, $intruder] = User::factory()->count(3)->create();
        $conv = Conversation::create();
        $conv->users()->attach([$a->id, $b->id]);

        Sanctum::actingAs($intruder);
        $this->deleteJson("/api/conversations/{$conv->id}")->assertForbidden();
    }
}
