<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

/**
 * Seeder dummy untuk testing auth + contact list di tahap awal.
 * Password sama untuk semua user agar mudah di-test: `password123`.
 */
class UserSeeder extends Seeder
{
    use WithoutModelEvents;

    public function run(): void
    {
        $password = Hash::make('password123');

        $users = [
            ['name' => 'Andi Pratama', 'email' => 'andi@mangansage.test'],
            ['name' => 'Budi Santoso', 'email' => 'budi@mangansage.test'],
            ['name' => 'Citra Dewi',   'email' => 'citra@mangansage.test'],
        ];

        foreach ($users as $u) {
            User::updateOrCreate(
                ['email' => $u['email']],
                [
                    'name' => $u['name'],
                    'password' => $password,
                    'email_verified_at' => now(),
                    'is_online' => false,
                ]
            );
        }
    }
}
