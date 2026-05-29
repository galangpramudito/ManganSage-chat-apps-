<?php

namespace App\Listeners;

use App\Events\MessageSent;
use App\Models\User;
use Illuminate\Support\Facades\Log;
use Kreait\Firebase\Contract\Messaging;
use Kreait\Firebase\Exception\FirebaseException;
use Kreait\Firebase\Exception\Messaging\NotFound;
use Kreait\Firebase\Messaging\CloudMessage;

/**
 * Kirim FCM push ke recipients setiap kali MessageSent dispatched.
 * Mengikuti technical-spec.md §5.
 *
 * Sengaja TIDAK menerima Messaging via constructor — agar Laravel container
 * tidak mencoba resolve Messaging saat listener di-instantiate (yang akan
 * gagal recursive kalau FIREBASE_CREDENTIALS kosong). Resolve lazily di
 * `handle()` dengan try/catch.
 *
 * Untuk testing, bind mock ke container dengan `app()->instance(Messaging::class, $mock)`.
 */
class SendFcmOnMessageSent
{
    public function handle(MessageSent $event): void
    {
        $messaging = $this->resolveMessaging();
        if ($messaging === null) {
            return;
        }

        $sender = User::find($event->message->sender_id);
        if (! $sender) {
            return;
        }

        $recipients = $event->conversation->users
            ->where('id', '!=', $sender->id)
            ->filter(fn (User $u) => filled($u->fcm_token));

        foreach ($recipients as $recipient) {
            $this->sendOne($messaging, $sender, $recipient, $event);
        }
    }

    private function sendOne(
        Messaging $messaging,
        User $sender,
        User $recipient,
        MessageSent $event,
    ): void {
        try {
            $msg = CloudMessage::fromArray([
                'token' => $recipient->fcm_token,
                'notification' => [
                    'title' => $sender->name,
                    'body'  => $event->message->body,
                ],
                'data' => [
                    'conversation_id' => (string) $event->conversation->id,
                    'sender_id'       => (string) $sender->id,
                    'type'            => 'new_message',
                ],
            ]);

            $messaging->send($msg);
        } catch (NotFound) {
            Log::info('FCM token stale; clearing', ['user_id' => $recipient->id]);
            $recipient->forceFill(['fcm_token' => null])->save();
        } catch (FirebaseException $e) {
            Log::warning('FCM dispatch failed', [
                'user_id' => $recipient->id,
                'error'   => $e->getMessage(),
            ]);
        }
    }

    private function resolveMessaging(): ?Messaging
    {
        try {
            if (app()->bound(Messaging::class)) {
                $instance = app(Messaging::class);
                if ($instance instanceof Messaging) {
                    return $instance;
                }
            }

            $instance = app('firebase.messaging');
            return $instance instanceof Messaging ? $instance : null;
        } catch (\Throwable) {
            return null; // Firebase belum dikonfigurasi.
        }
    }
}
