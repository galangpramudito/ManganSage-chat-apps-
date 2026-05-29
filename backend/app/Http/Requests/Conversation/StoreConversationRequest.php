<?php

namespace App\Http\Requests\Conversation;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * Validation untuk POST /api/conversations.
 * Mengikuti technical-spec.md §2.3.
 */
class StoreConversationRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'user_id' => [
                'required',
                'integer',
                'exists:users,id',
                // Tidak boleh chat dengan diri sendiri.
                Rule::notIn([$this->user()?->id]),
            ],
        ];
    }

    public function messages(): array
    {
        return [
            'user_id.not_in' => 'Tidak bisa membuat percakapan dengan diri sendiri.',
        ];
    }
}
