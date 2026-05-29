<?php

namespace Tests\Feature;

use App\Events\MessageMarkedRead;
use App\Events\MessageSent;
use App\Models\Conversation;
use App\Models\User;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Event;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * Verifikasi event broadcasting (technical-spec.md §4).
 * Pakai Event::fake() agar tidak butuh Reverb running.
 */
class BroadcastingTest extends TestCase
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

    public function test_store_message_dispatches_message_sent_event(): void
    {
        Event::fake();

        [$me, $other, $conv] = $this->pair();
        Sanctum::actingAs($me);

        $this->postJson("/api/conversations/{$conv->id}/messages", ['body' => 'Hai'])
            ->assertCreated();

        Event::assertDispatched(MessageSent::class, function ($e) use ($conv, $me) {
            return $e->conversation->id === $conv->id
                && $e->message->sender_id === $me->id
                && $e->message->body === 'Hai';
        });
    }

    public function test_message_sent_broadcasts_only_to_recipient_channel(): void
    {
        [$me, $other, $conv] = $this->pair();
        $conv->loadMissing('users');

        $msg = $conv->messages()->create(['sender_id' => $me->id, 'body' => 'Hai']);

        $event = new MessageSent($msg, $conv);
        $channels = $event->broadcastOn();

        $names = collect($channels)
            ->map(fn (PrivateChannel $c) => $c->name)
            ->all();

        $this->assertContains('private-user.'.$other->id, $names);
        $this->assertNotContains('private-user.'.$me->id, $names);
    }

    public function test_message_sent_payload_shape(): void
    {
        [$me, , $conv] = $this->pair();
        $conv->loadMissing('users');

        $msg = $conv->messages()->create(['sender_id' => $me->id, 'body' => 'Hai']);

        $payload = (new MessageSent($msg, $conv))->broadcastWith();

        $this->assertSame($conv->id, $payload['conversation_id']);
        $this->assertSame($msg->id, $payload['message']['id']);
        $this->assertSame($me->id, $payload['message']['sender_id']);
        $this->assertSame('Hai', $payload['message']['body']);
        $this->assertFalse($payload['message']['is_read']);
        $this->assertNotEmpty($payload['message']['created_at']);
    }

    public function test_message_sent_event_uses_message_dot_sent_alias(): void
    {
        [$me, , $conv] = $this->pair();
        $conv->loadMissing('users');
        $msg = $conv->messages()->create(['sender_id' => $me->id, 'body' => 'Hai']);

        $this->assertSame('message.sent', (new MessageSent($msg, $conv))->broadcastAs());
    }

    public function test_mark_read_dispatches_message_marked_read_event(): void
    {
        Event::fake();

        [$me, $other, $conv] = $this->pair();
        // Other kirim 1 pesan.
        $conv->messages()->create(['sender_id' => $other->id, 'body' => 'Hai']);

        Sanctum::actingAs($me);
        $this->postJson("/api/conversations/{$conv->id}/read")->assertOk();

        Event::assertDispatched(MessageMarkedRead::class, function ($e) use ($conv, $me) {
            return $e->conversation->id === $conv->id
                && $e->reader->id === $me->id;
        });
    }

    public function test_mark_read_does_not_dispatch_when_nothing_to_mark(): void
    {
        Event::fake();

        [$me, , $conv] = $this->pair();
        // Tidak ada pesan dari other. Mark-read jadi no-op.

        Sanctum::actingAs($me);
        $this->postJson("/api/conversations/{$conv->id}/read")->assertOk();

        Event::assertNotDispatched(MessageMarkedRead::class);
    }

    public function test_message_marked_read_broadcasts_only_to_other(): void
    {
        [$me, $other, $conv] = $this->pair();
        $conv->loadMissing('users');

        $event = new MessageMarkedRead($conv, $me, now());
        $names = collect($event->broadcastOn())
            ->map(fn (PrivateChannel $c) => $c->name)
            ->all();

        $this->assertContains('private-user.'.$other->id, $names);
        $this->assertNotContains('private-user.'.$me->id, $names);
        $this->assertSame('message.read', $event->broadcastAs());
    }
}
