<?php
// Quick relationship smoke test for step 2.
// Run via: php artisan tinker --execute="require 'tests/manual/relationship_smoke.php';"

use App\Models\Conversation;
use App\Models\Message;
use App\Models\MessageRead;
use App\Models\User;

$andi = User::where('email', 'andi@mangansage.test')->first();
$budi = User::where('email', 'budi@mangansage.test')->first();

$conv = Conversation::create();
$conv->users()->attach([$andi->id, $budi->id]);

$msg = $conv->messages()->create([
    'sender_id' => $andi->id,
    'body' => 'Hei, apa kabar?',
]);

MessageRead::create([
    'message_id' => $msg->id,
    'user_id' => $budi->id,
    'read_at' => now(),
]);

echo 'Conv participants    : ' . $conv->users->pluck('name')->join(', ') . PHP_EOL;
echo 'Latest message body  : ' . $conv->latestMessage->body . PHP_EOL;
echo 'Sender name          : ' . $msg->sender->name . PHP_EOL;
echo 'Reads count          : ' . $msg->reads->count() . PHP_EOL;
echo 'Andi conversations   : ' . $andi->fresh()->activeConversations->count() . PHP_EOL;

// Test soft-delete sepihak: Andi removes the conversation from his inbox.
$andi->conversations()->updateExistingPivot($conv->id, ['deleted_at' => now()]);

echo 'After soft-delete:' . PHP_EOL;
echo '  Andi active count  : ' . $andi->fresh()->activeConversations->count() . PHP_EOL;
echo '  Budi active count  : ' . $budi->fresh()->activeConversations->count() . PHP_EOL;

// Cleanup
$conv->delete(); // cascades to pivot, messages, message_reads
echo 'Cleanup: OK' . PHP_EOL;
