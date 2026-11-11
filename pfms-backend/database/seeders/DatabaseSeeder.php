<?php

namespace Database\Seeders;

use App\Models\Category;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        User::create([
            'name' => 'Admin',
            'email' => 'admin@pfms.test',
            'password' => Hash::make('password'),
            'role' => 'admin',
        ]);

        $defaults = [
            ['name' => 'Salary', 'type' => 'income', 'color' => '#22C55E'],
            ['name' => 'Freelance', 'type' => 'income', 'color' => '#16A34A'],
            ['name' => 'Gift', 'type' => 'income', 'color' => '#4ADE80'],
            ['name' => 'Food & Dining', 'type' => 'expense', 'color' => '#EF4444'],
            ['name' => 'Transportation', 'type' => 'expense', 'color' => '#F97316'],
            ['name' => 'Utilities', 'type' => 'expense', 'color' => '#F59E0B'],
            ['name' => 'Shopping', 'type' => 'expense', 'color' => '#EC4899'],
            ['name' => 'Health', 'type' => 'expense', 'color' => '#8B5CF6'],
        ];

        foreach ($defaults as $category) {
            Category::create($category);
        }
    }
}
