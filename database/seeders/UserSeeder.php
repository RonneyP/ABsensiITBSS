<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class UserSeeder extends Seeder
{
    public function run(): void
    {
        User::updateOrCreate(
            ['email' => 'dosen@example.com'],
            [
                'nama' => 'Anton',
                'username' => 'dosen_anton',
                'password' => Hash::make('password123'),
                'role' => 'dosen',
            ]
        );

        User::updateOrCreate(
            ['email' => 'mahasiswa@example.com'],
            [
                'nama' => 'Budi',
                'username' => 'mhs_budi',
                'password' => Hash::make('password123'),
                'role' => 'mahasiswa',
            ]
        );
    }
}
