<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

#[Fillable([])]
class Conversation extends Model
{
    use HasFactory;

    /**
     * Semua participant (termasuk yang sudah soft-delete sepihak).
     */
    public function users(): BelongsToMany
    {
        return $this->belongsToMany(User::class)
            ->withPivot(['deleted_at'])
            ->withTimestamps();
    }

    /**
     * Participant aktif (yang belum soft-delete sepihak).
     */
    public function activeUsers(): BelongsToMany
    {
        return $this->users()->wherePivotNull('deleted_at');
    }

    public function messages(): HasMany
    {
        return $this->hasMany(Message::class);
    }

    public function latestMessage(): HasOne
    {
        return $this->hasOne(Message::class)->latestOfMany();
    }
}
