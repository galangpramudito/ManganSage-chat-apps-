<?php

namespace App\Http\Resources;

use App\Models\Conversation;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * Format conversation di Inbox.
 * Mengikuti technical-spec.md §2.3 — `participant`, `last_message`, `unread_count`.
 *
 * Asumsi:
 * - Eager load: `users`, `latestMessage.reads`
 * - `unread_count` dihitung via `withCount` di controller (atribut dinamis)
 *
 * @mixin Conversation
 */
class ConversationResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $userId   = $request->user()?->id;
        $other    = $this->users->firstWhere('id', '!=', $userId);
        $latest   = $this->latestMessage;

        return [
            'id'           => $this->id,
            'participant'  => $other ? [
                'id'        => $other->id,
                'name'      => $other->name,
                'avatar'    => $other->avatar,
                'is_online' => (bool) $other->is_online,
                'last_seen' => $other->last_seen?->toIso8601String(),
            ] : null,
            'last_message' => $latest ? [
                'body'       => $latest->body,
                'created_at' => $latest->created_at?->toIso8601String(),
                'is_read'    => $latest->reads
                    ->where('user_id', '!=', $latest->sender_id)
                    ->isNotEmpty(),
            ] : null,
            'unread_count' => (int) ($this->unread_count ?? 0),
        ];
    }
}
