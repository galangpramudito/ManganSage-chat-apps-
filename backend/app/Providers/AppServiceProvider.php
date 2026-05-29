<?php

namespace App\Providers;

use App\Events\MessageSent;
use App\Listeners\SendFcmOnMessageSent;
use Illuminate\Support\Facades\Event;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        //
    }

    public function boot(): void
    {
        // FCM dispatch on every new message.
        Event::listen(MessageSent::class, SendFcmOnMessageSent::class);
    }
}
