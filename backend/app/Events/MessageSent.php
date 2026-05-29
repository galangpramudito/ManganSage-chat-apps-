<?php

namespace App\Events;

use App\Models\Conversation;
use App\Models\Message;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

/**
 * Pesan baru terkirim — push ke semua participant kecuali pengirim.
 * Mengikuti technical-spec.md §4 (channel `private-user.{userId}`,
 * event `message.sent`, payload `{ conversation_id, message }`).
 */
class MessageSent implements ShouldBroadcastNow
{
    use Dispatchable;
    use InteractsWithSockets;
    use SerializesModels;

    public function __construct(
        public Message $message,
        public Conversation $conversation,
    ) {}

    /**
     * @return array<int, PrivateChannel>
     */
    public function broadcastOn(): array
    {
        return $this->conversation->users
            ->where('id', '!=', $this->message->sender_id)
            ->map(fn ($u) => new PrivateChannel('user.'.$u->id))
            ->values()
            ->all();
    }

    public function broadcastAs(): string
    {
        return 'message.sent';
    }

    /**
     * @return array<string, mixed>
     */
    public function broadcastWith(): array
    {
        return [
            'conversation_id' => $this->conversation->id,
            'message' => [
                'id'         => $this->message->id,
                'sender_id'  => $this->message->sender_id,
                'body'       => $this->message->body,
                'is_read'    => false,
                'created_at' => $this->message->created_at?->toIso8601String(),
            ],
        ];
    }
}
