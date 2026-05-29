<?php

namespace App\Http\Resources;

use App\Models\Message;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * Format pesan untuk response API.
 * Mengikuti technical-spec.md §2.4.
 *
 * `is_read` adalah dari sudut pandang "non-sender":
 *   - jika message ini saya kirim → true berarti penerima sudah baca (centang biru)
 *   - jika message ini diterima  → true berarti saya (penerima) sudah baca
 * Di chat 1-on-1, lawan partisipan tunggal sehingga maknanya tidak ambigu.
 *
 * @mixin Message
 */
class MessageResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'         => $this->id,
            'sender_id'  => $this->sender_id,
            'body'       => $this->body,
            'is_read'    => $this->isReadByOthers(),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }

    /**
     * True kalau ada MessageRead dari user selain pengirim.
     * Pakai `relationLoaded` agar tidak N+1 saat collection.
     */
    private function isReadByOthers(): bool
    {
        if ($this->relationLoaded('reads')) {
            return $this->reads
                ->where('user_id', '!=', $this->sender_id)
                ->isNotEmpty();
        }

        return $this->reads()
            ->where('user_id', '!=', $this->sender_id)
            ->exists();
    }
}
