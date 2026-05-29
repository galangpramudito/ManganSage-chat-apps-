<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Pivot conversation_user — relasi many-to-many participants.
 * `deleted_at` mendukung soft-delete sepihak: user A bisa hapus conversation
 * dari inbox-nya tanpa mempengaruhi user B.
 */
return new class extends Migration {
    public function up(): void
    {
        Schema::create('conversation_user', function (Blueprint $table) {
            $table->id();
            $table->foreignId('conversation_id')
                ->constrained('conversations')
                ->cascadeOnDelete();
            $table->foreignId('user_id')
                ->constrained('users')
                ->cascadeOnDelete();
            $table->timestamp('deleted_at')->nullable();
            $table->timestamps();

            $table->unique(['conversation_id', 'user_id']);
            $table->index(['user_id', 'deleted_at']); // untuk query inbox
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('conversation_user');
    }
};
