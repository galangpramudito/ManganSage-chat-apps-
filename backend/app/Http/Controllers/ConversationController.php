<?php

namespace App\Http\Controllers;

use App\Http\Requests\Conversation\StoreConversationRequest;
use App\Http\Resources\ConversationResource;
use App\Models\Conversation;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

/**
 * Endpoint conversations — Inbox.
 * Mengikuti technical-spec.md §2.3.
 */
class ConversationController extends Controller
{
    /**
     * GET /api/conversations
     */
    public function index(Request $request): AnonymousResourceCollection
    {
        $user = $request->user();

        $conversations = $user->activeConversations()
            ->with([
                'users:id,name,avatar,is_online,last_seen',
                'latestMessage.reads:id,message_id,user_id',
            ])
            ->withCount([
                'messages as unread_count' => function ($q) use ($user) {
                    $q->where('sender_id', '!=', $user->id)
                        ->whereDoesntHave('reads', fn ($r) => $r->where('user_id', $user->id));
                },
            ])
            ->get()
            // Sort by latest message timestamp DESC; null (no messages) last.
            ->sortByDesc(fn (Conversation $c) => $c->latestMessage?->created_at)
            ->values();

        return ConversationResource::collection($conversations);
    }

    /**
     * POST /api/conversations
     * Body: { user_id }
     *
     * Cari conversation yang mengandung kedua user; kalau ada → restore pivot
     * current user (jika sebelumnya soft-deleted) dan return 200; kalau tidak →
     * buat baru dan return 201.
     */
    public function store(StoreConversationRequest $request): JsonResponse
    {
        $userId  = $request->user()->id;
        $otherId = (int) $request->validated('user_id');

        $conversation = Conversation::query()
            ->whereHas('users', fn ($q) => $q->where('users.id', $userId))
            ->whereHas('users', fn ($q) => $q->where('users.id', $otherId))
            ->first();

        $status = 200;
        if (! $conversation) {
            $conversation = Conversation::create();
            $conversation->users()->attach([$userId, $otherId]);
            $status = 201;
        } else {
            // Pulihkan jika current user sebelumnya soft-delete sepihak.
            $conversation->users()->updateExistingPivot($userId, ['deleted_at' => null]);
        }

        $other = User::find($otherId);

        return response()->json([
            'id'          => $conversation->id,
            'participant' => [
                'id'        => $other->id,
                'name'      => $other->name,
                'avatar'    => $other->avatar,
                'is_online' => (bool) $other->is_online,
                'last_seen' => $other->last_seen?->toIso8601String(),
            ],
        ], $status);
    }

    /**
     * DELETE /api/conversations/{conversation}
     * Soft delete sepihak — hanya tandai pivot current user.
     */
    public function destroy(Request $request, Conversation $conversation): JsonResponse
    {
        $user = $request->user();
        $this->ensureParticipant($conversation, $user->id);

        $conversation->users()->updateExistingPivot($user->id, ['deleted_at' => now()]);

        return response()->json(['message' => 'Conversation removed']);
    }

    /**
     * Throw 403 kalau user bukan participant.
     */
    private function ensureParticipant(Conversation $conversation, int $userId): void
    {
        abort_unless(
            $conversation->users()->where('users.id', $userId)->exists(),
            403,
            'Bukan participant percakapan ini.'
        );
    }
}
