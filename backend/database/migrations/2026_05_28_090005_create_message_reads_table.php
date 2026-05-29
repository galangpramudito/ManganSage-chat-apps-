<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Tabel message_reads — log per-user kapan suatu pesan dibaca.
 * Unique pada (message_id, user_id) — satu user hanya bisa baca pesan sekali.
 */
return new class extends Migration {
    public function up(): void
    {
        Schema::create('message_reads', function (Blueprint $table) {
            $table->id();
            $table->foreignId('message_id')
                ->constrained('messages')
                ->cascadeOnDelete();
            $table->foreignId('user_id')
                ->constrained('users')
                ->cascadeOnDelete();
            $table->timestamp('read_at');

            $table->unique(['message_id', 'user_id']);
            $table->index(['user_id', 'read_at']); // untuk hitung unread
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('message_reads');
    }
};
