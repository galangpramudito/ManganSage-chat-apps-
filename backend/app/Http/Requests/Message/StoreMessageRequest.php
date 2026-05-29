<?php

namespace App\Http\Requests\Message;

use App\Models\Conversation;
use Illuminate\Foundation\Http\FormRequest;

/**
 * Validation untuk POST /api/conversations/{conversation}/messages.
 * `authorize()` memastikan user adalah participant.
 */
class StoreMessageRequest extends FormRequest
{
    public function authorize(): bool
    {
        $conversation = $this->route('conversation');
        if (! $conversation instanceof Conversation) {
            return false;
        }

        return $conversation->users()
            ->where('users.id', $this->user()?->id)
            ->exists();
    }

    public function rules(): array
    {
        return [
            'body' => ['required', 'string', 'max:4000'],
        ];
    }
}
