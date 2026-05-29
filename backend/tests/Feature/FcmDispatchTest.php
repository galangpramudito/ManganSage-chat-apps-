<?php

namespace Tests\Feature;

use App\Events\MessageSent;
use App\Listeners\SendFcmOnMessageSent;
use App\Models\Conversation;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Kreait\Firebase\Contract\Messaging;
use Kreait\Firebase\Exception\Messaging\NotFound;
use Kreait\Firebase\Messaging\CloudMessage;
use Mockery;
use Mockery\Adapter\Phpunit\MockeryPHPUnitIntegration;
use Mockery\MockInterface;
use Tests\TestCase;

class FcmDispatchTest extends TestCase
{
    use MockeryPHPUnitIntegration;
    use RefreshDatabase;

    /** @return array{0:User,1:User,2:Conversation} */
    private function pair(?string $recipientToken = 'token-budi'): array
    {
        [$me]    = User::factory()->count(1)->create(['fcm_token' => null]);
        [$other] = User::factory()->count(1)->create(['fcm_token' => $recipientToken]);
        $c = Conversation::create();
        $c->users()->attach([$me->id, $other->id]);
        return [$me, $other, $c];
    }

    private function bindMockMessaging(): MockInterface
    {
        $mock = Mockery::mock(Messaging::class);
        $this->app->instance(Messaging::class, $mock);
        return $mock;
    }

    public function test_listener_sends_fcm_to_recipient_with_token(): void
    {
        [$me, $other, $conv] = $this->pair();
        $msg = $conv->messages()->create(['sender_id' => $me->id, 'body' => 'Hai']);
        $conv->loadMissing('users');

        $messaging = $this->bindMockMessaging();
        $messaging->shouldReceive('send')
            ->once()
            ->with(Mockery::on(function (CloudMessage $cm) use ($other) {
                $payload = $cm->jsonSerialize();
                return $payload['token'] === $other->fcm_token
                    && $payload['notification']['body'] === 'Hai'
                    && $payload['data']['type'] === 'new_message';
            }));

        (new SendFcmOnMessageSent())->handle(new MessageSent($msg, $conv));
    }

    public function test_listener_skips_recipients_without_token(): void
    {
        [$me, , $conv] = $this->pair(recipientToken: null);
        $msg = $conv->messages()->create(['sender_id' => $me->id, 'body' => 'Hai']);
        $conv->loadMissing('users');

        $messaging = $this->bindMockMessaging();
        $messaging->shouldNotReceive('send');

        (new SendFcmOnMessageSent())->handle(new MessageSent($msg, $conv));
    }

    public function test_listener_clears_stale_token_on_not_found(): void
    {
        [$me, $other, $conv] = $this->pair();
        $msg = $conv->messages()->create(['sender_id' => $me->id, 'body' => 'Hai']);
        $conv->loadMissing('users');

        $messaging = $this->bindMockMessaging();
        $messaging->shouldReceive('send')
            ->once()
            ->andThrow(new NotFound('token not registered'));

        (new SendFcmOnMessageSent())->handle(new MessageSent($msg, $conv));

        $this->assertNull($other->fresh()->fcm_token);
    }

    public function test_listener_is_noop_when_messaging_not_configured(): void
    {
        [$me, , $conv] = $this->pair();
        $msg = $conv->messages()->create(['sender_id' => $me->id, 'body' => 'Hai']);
        $conv->loadMissing('users');

        // Sengaja TIDAK bind mock → simulasi Firebase belum configured.
        // Listener harus no-op tanpa exception.
        (new SendFcmOnMessageSent())->handle(new MessageSent($msg, $conv));

        $this->expectNotToPerformAssertions();
    }
}
