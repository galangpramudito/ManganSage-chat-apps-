<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * Representasi User di response API.
 * Mengikuti format technical-spec.md §2.1, §2.2.
 */
class UserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'        => $this->id,
            'name'      => $this->name,
            'email'     => $this->email,
            'avatar'    => $this->avatar,
            'is_online' => (bool) $this->is_online,
            'last_seen' => $this->last_seen?->toIso8601String(),
        ];
    }
}
