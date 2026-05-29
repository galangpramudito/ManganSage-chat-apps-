<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

#[Fillable(['name', 'email', 'password', 'avatar', 'is_online', 'last_seen', 'fcm_token', 'email_verified', 'verification_otp', 'verification_otp_expires_at'])]
#[Hidden(['password', 'remember_token', 'fcm_token', 'verification_otp'])]
class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, Notifiable;

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'is_online' => 'boolean',
            'last_seen' => 'datetime',
            'email_verified' => 'boolean',
            'verification_otp_expires_at' => 'datetime',
        ];
    }

    /**
     * Semua conversation user ini ikut serta (termasuk yang dihapus sepihak).
     */
    public function conversations(): BelongsToMany
    {
        return $this->belongsToMany(Conversation::class)
            ->withPivot(['deleted_at'])
            ->withTimestamps();
    }

    /**
     * Conversation aktif di inbox (yang belum dihapus sepihak).
     */
    public function activeConversations(): BelongsToMany
    {
        return $this->conversations()->wherePivotNull('deleted_at');
    }

    /**
     * Pesan yang dikirim user ini.
     */
    public function sentMessages(): HasMany
    {
        return $this->hasMany(Message::class, 'sender_id');
    }

    public function messageReads(): HasMany
    {
        return $this->hasMany(MessageRead::class);
    }
}
