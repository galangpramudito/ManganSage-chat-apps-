<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Tambah kolom chat-specific ke tabel users.
 * Source: technical-spec.md §3
 */
return new class extends Migration {
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('avatar')->nullable()->after('password');
            $table->boolean('is_online')->default(false)->after('avatar');
            $table->timestamp('last_seen')->nullable()->after('is_online');
            $table->string('fcm_token')->nullable()->after('last_seen');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['avatar', 'is_online', 'last_seen', 'fcm_token']);
        });
    }
};
