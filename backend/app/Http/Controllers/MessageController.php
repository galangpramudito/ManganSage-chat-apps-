<?php

namespace App\Http\Controllers;

use App\Events\MessageMarkedRead;
use App\Events\MessageSent;
use App\Http\Requests\Message\StoreMessageRequest;
use App\Http\Resources\MessageResource;
use App\Models\Conversation;
use App\Models\MessageRead;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\DB;

/**
 * Endpoint messages — chat room.
 * Mengikuti technical-spec.md §2.4 + broadcast events §4.
 */
class MessageController extends Controller
{
    /**
     * GET /api/conversations/{conversation}/messages?page=1&per_page=20
     */
    public function index(Request $request, Conversation $conversation): AnonymousResourceCollection
    {
        $this->ensureParticipant($conversation, $request->user()->id);

        $perPage = (int) $request->integer('per_page', 20);
        $perPage = max(1, min($perPage, 50));

        $messages = $conversation->messages()
            ->with(['reads:id,message_id,user_id'])
            ->orderByDesc('created_at')
            ->orderByDesc('id')
            ->paginate($perPage);

        return MessageResource::collection($messages);
    }

    /**
     * POST /api/conversations/{conversation}/messages
     * Broadcast: MessageSent ke semua participant kecuali pengirim.
     */
    public function store(StoreMessageRequest $request, Conversation $conversation): JsonResponse
    {
        $message = $conversation->messages()->create([
            'sender_id' => $request->user()->id,
            'body'      => $request->validated('body'),
        ]);

        // Restore semua pivot (re-engage setelah delete sepihak).
        DB::table('conversation_user')
            ->where('conversation_id', $conversation->id)
            ->update(['deleted_at' => null]);

        // Update timestamp conversation untuk sortir inbox.
        $conversation->touch();

        $message->load('reads:id,message_id,user_id');

        // Pastikan relasi `users` ter-load buat broadcastOn().
        $conversation->loadMissing('users');

        broadcast(new MessageSent($message, $conversation))->toOthers();

        return response()->json(
            MessageResource::make($message)->resolve($request),
            201
        );
    }

    /**
     * POST /api/conversations/{conversation}/read
     * Broadcast: MessageMarkedRead ke pengirim asli (centang biru).
     */
    public function markAsRead(Request $request, Conversation $conversation): JsonResponse
    {
        $user   = $request->user();
        $userId = $user->id;
        $this->ensureParticipant($conversation, $userId);

        $unreadIds = $conversation->messages()
            ->where('sender_id', '!=', $userId)
            ->whereDoesntHave('reads', fn ($q) => $q->where('user_id', $userId))
            ->pluck('id');

        $now = now();

        if ($unreadIds->isNotEmpty()) {
            $rows = $unreadIds->map(fn ($id) => [
                'message_id' => $id,
                'user_id'    => $userId,
                'read_at'    => $now,
            ])->all();

            MessageRead::insert($rows);

            $conversation->loadMissing('users');
            broadcast(new MessageMarkedRead($conversation, $user, $now))->toOthers();
        }

        return response()->json(['message' => 'Marked as read']);
    }

    private function ensureParticipant(Conversation $conversation, int $userId): void
    {
        abort_unless(
            $conversation->users()->where('users.id', $userId)->exists(),
            403,
            'Bukan participant percakapan ini.'
        );
    }
}
