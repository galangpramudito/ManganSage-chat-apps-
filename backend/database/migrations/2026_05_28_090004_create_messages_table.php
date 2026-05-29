<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Tabel messages — pesan dalam suatu conversation.
 * Sesuai spec §3: id, conversation_id, sender_id, body, created_at.
 *
 * NOTE: kita tetap pakai timestamps() supaya mudah pakai Eloquent;
 * updated_at akan otomatis sama dengan created_at karena pesan immutable.
 */
return new class extends Migration {
    public function up(): void
    {
        Schema::create('messages', function (Blueprint $table) {
            $table->id();
            $table->foreignId('conversation_id')
                ->constrained('conversations')
                ->cascadeOnDelete();
            $table->foreignId('sender_id')
                ->constrained('users')
                ->cascadeOnDelete();
            $table->text('body');
            $table->timestamps();

            $table->index(['conversation_id', 'created_at']); // untuk pagination
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('messages');
    }
};
