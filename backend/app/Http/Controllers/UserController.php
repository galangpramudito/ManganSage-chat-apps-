<?php

namespace App\Http\Controllers;

use App\Http\Resources\UserResource;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

/**
 * GET /api/users — Global Contact List.
 * Mengikuti technical-spec.md §2.2.
 */
class UserController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        $users = User::query()
            ->where('id', '!=', $request->user()->id)
            ->orderBy('name')
            ->get();

        return UserResource::collection($users);
    }
}
