<?php

namespace Tests\Feature;

use App\Models\Conversation;
use App\Models\Message;
use App\Models\MessageRead;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class MessagesTest extends TestCase
{
    use RefreshDatabase;

    /** @return array{0:User,1:User,2:Conversation} */
    private function pair(): array
    {
        [$a, $b] = User::factory()->count(2)->create();
        $c = Conversation::create();
        $c->users()->attach([$a->id, $b->id]);
        return [$a, $b, $c];
    }

    // ─── Index ───────────────────────────────────────────────────────────────

    public function test_index_returns_paginated_messages_desc(): void
    {
        [$me, $other, $conv] = $this->pair();

        // 25 pesan supaya pagination kelihatan
        for ($i = 1; $i <= 25; $i++) {
            $conv->messages()->create([
                'sender_id' => $i % 2 === 0 ? $me->id : $other->id,
                'body'      => "Pesan #$i",
            ]);
        }

        Sanctum::actingAs($me);
        $response = $this->getJson("/api/conversations/{$conv->id}/messages?per_page=20");

        $response->assertOk()
            ->assertJsonStructure([
                'data' => [['id', 'sender_id', 'body', 'is_read', 'created_at']],
                'meta' => ['current_page', 'last_page', 'per_page'],
            ])
            ->assertJsonPath('meta.per_page', 20)
            ->assertJsonPath('meta.current_page', 1)
            ->assertJsonPath('meta.last_page', 2);

        // Pesan terbaru (#25) ada di awal data
        $this->assertSame('Pesan #25', $response->json('data.0.body'));
    }

    public function test_index_marks_message_as_read_when_other_has_read(): void
    {
        [$me, $other, $conv] = $this->pair();

        $myMsg = $conv->messages()->create(['sender_id' => $me->id, 'body' => 'Halo']);
        MessageRead::create(['message_id' => $myMsg->id, 'user_id' => $other->id, 'read_at' => now()]);

        Sanctum::actingAs($me);
        $this->getJson("/api/conversations/{$conv->id}/messages")
            ->assertJsonPath('data.0.is_read', true);
    }

    public function test_index_message_is_read_false_when_no_one_else_read(): void
    {
        [$me, $other, $conv] = $this->pair();
        $conv->messages()->create(['sender_id' => $me->id, 'body' => 'Halo']);

        Sanctum::actingAs($me);
        $this->getJson("/api/conversations/{$conv->id}/messages")
            ->assertJsonPath('data.0.is_read', false);
    }

    public function test_index_forbidden_for_non_participant(): void
    {
        [, , $conv] = $this->pair();
        $intruder = User::factory()->create();

        Sanctum::actingAs($intruder);
        $this->getJson("/api/conversations/{$conv->id}/messages")->assertForbidden();
    }

    public function test_index_requires_auth(): void
    {
        [, , $conv] = $this->pair();
        $this->getJson("/api/conversations/{$conv->id}/messages")->assertUnauthorized();
    }

    public function test_index_404_for_unknown_conversation(): void
    {
        $me = User::factory()->create();
        Sanctum::actingAs($me);
        $this->getJson('/api/conversations/9999/messages')->assertNotFound();
    }

    // ─── Store ───────────────────────────────────────────────────────────────

    public function test_store_creates_message(): void
    {
        [$me, , $conv] = $this->pair();
        Sanctum::actingAs($me);

        $response = $this->postJson("/api/conversations/{$conv->id}/messages", [
            'body' => 'Hei, apa kabar?',
        ]);

        $response->assertCreated()
            ->assertJsonStructure(['id', 'sender_id', 'body', 'is_read', 'created_at'])
            ->assertJsonPath('sender_id', $me->id)
            ->assertJsonPath('body', 'Hei, apa kabar?')
            ->assertJsonPath('is_read', false);

        $this->assertDatabaseHas('messages', [
            'conversation_id' => $conv->id,
            'sender_id'       => $me->id,
            'body'            => 'Hei, apa kabar?',
        ]);
    }

    public function test_store_validates_body_required(): void
    {
        [$me, , $conv] = $this->pair();
        Sanctum::actingAs($me);

        $this->postJson("/api/conversations/{$conv->id}/messages", ['body' => ''])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['body']);
    }

    public function test_store_forbidden_for_non_participant(): void
    {
        [, , $conv] = $this->pair();
        $intruder = User::factory()->create();

        Sanctum::actingAs($intruder);
        $this->postJson("/api/conversations/{$conv->id}/messages", ['body' => 'Hai'])
            ->assertForbidden();
    }

    public function test_store_restores_soft_deleted_pivots_for_all_participants(): void
    {
        [$me, $other, $conv] = $this->pair();
        $conv->users()->updateExistingPivot($me->id,    ['deleted_at' => now()]);
        $conv->users()->updateExistingPivot($other->id, ['deleted_at' => now()]);

        Sanctum::actingAs($me);
        $this->postJson("/api/conversations/{$conv->id}/messages", ['body' => 'Hai lagi'])
            ->assertCreated();

        $myPivot    = $conv->users()->where('users.id', $me->id)->first()->pivot;
        $otherPivot = $conv->users()->where('users.id', $other->id)->first()->pivot;
        $this->assertNull($myPivot->deleted_at);
        $this->assertNull($otherPivot->deleted_at);
    }

    // ─── Mark as Read ───────────────────────────────────────────────────────

    public function test_mark_as_read_inserts_reads_for_unread_messages_from_others(): void
    {
        [$me, $other, $conv] = $this->pair();

        // 2 pesan dari other, 1 dari me.
        $msg1 = $conv->messages()->create(['sender_id' => $other->id, 'body' => 'A']);
        $msg2 = $conv->messages()->create(['sender_id' => $other->id, 'body' => 'B']);
        $myMsg = $conv->messages()->create(['sender_id' => $me->id,   'body' => 'C']);

        Sanctum::actingAs($me);
        $this->postJson("/api/conversations/{$conv->id}/read")
            ->assertOk()
            ->assertJson(['message' => 'Marked as read']);

        $this->assertDatabaseHas('message_reads', ['message_id' => $msg1->id, 'user_id' => $me->id]);
        $this->assertDatabaseHas('message_reads', ['message_id' => $msg2->id, 'user_id' => $me->id]);
        // Pesan saya sendiri tidak perlu MessageRead.
        $this->assertDatabaseMissing('message_reads', ['message_id' => $myMsg->id, 'user_id' => $me->id]);
    }

    public function test_mark_as_read_is_idempotent(): void
    {
        [$me, $other, $conv] = $this->pair();
        $msg = $conv->messages()->create(['sender_id' => $other->id, 'body' => 'A']);

        Sanctum::actingAs($me);
        $this->postJson("/api/conversations/{$conv->id}/read")->assertOk();
        $this->postJson("/api/conversations/{$conv->id}/read")->assertOk();

        $this->assertDatabaseCount('message_reads', 1);
    }

    public function test_mark_as_read_forbidden_for_non_participant(): void
    {
        [, , $conv] = $this->pair();
        $intruder = User::factory()->create();

        Sanctum::actingAs($intruder);
        $this->postJson("/api/conversations/{$conv->id}/read")->assertForbidden();
    }
}
