<?php

use App\Models\User;
use Illuminate\Support\Facades\Broadcast;

/*
|--------------------------------------------------------------------------
| Broadcast Channels
|--------------------------------------------------------------------------
| Per technical-spec.md §4: setiap user punya private channel-nya sendiri,
| dipakai untuk push pesan baru & read receipts.
*/

Broadcast::channel('user.{id}', function (User $user, int $id) {
    return $user->id === $id;
});
