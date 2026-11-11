<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\Transaction;
use App\Models\User;

class DashboardController extends Controller
{
    public function index()
    {
        $stats = [
            'total_users' => User::count(),
            'total_categories' => Category::count(),
            'total_transactions' => Transaction::count(),
            'total_income' => Transaction::ofType('income')->sum('amount'),
            'total_expense' => Transaction::ofType('expense')->sum('amount'),
        ];

        return view('admin.dashboard', compact('stats'));
    }
}
