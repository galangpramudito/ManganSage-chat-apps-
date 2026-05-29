<?php

namespace App\Events;

use App\Models\Conversation;
use App\Models\User;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Carbon;

/**
 * User sudah membaca pesan-pesan di sebuah conversation — push ke
 * pengirim asli supaya centang biru muncul.
 *
 * channel: private-user.{senderUserId}
 * event:   message.read
 * payload: { conversation_id, reader_id, read_at }
 */
class MessageMarkedRead implements ShouldBroadcastNow
{
    use Dispatchable;
    use InteractsWithSockets;
    use SerializesModels;

    public function __construct(
        public Conversation $conversation,
        public User $reader,
        public Carbon $readAt,
    ) {}

    /**
     * @return array<int, PrivateChannel>
     */
    public function broadcastOn(): array
    {
        // Push ke participant LAIN (pengirim pesan-pesan tsb).
        return $this->conversation->users
            ->where('id', '!=', $this->reader->id)
            ->map(fn ($u) => new PrivateChannel('user.'.$u->id))
            ->values()
            ->all();
    }

    public function broadcastAs(): string
    {
        return 'message.read';
    }

    /**
     * @return array<string, mixed>
     */
    public function broadcastWith(): array
    {
        return [
            'conversation_id' => $this->conversation->id,
            'reader_id'       => $this->reader->id,
            'read_at'         => $this->readAt->toIso8601String(),
        ];
    }
}
