<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Transaction;
use Illuminate\Http\Request;

class TransactionController extends Controller
{
    
    public function index(Request $request)
    {
        $transactions = Transaction::with(['user', 'category'])
            ->when($request->type, fn ($q) => $q->where('type', $request->type))
            ->when($request->q, fn ($q) => $q->where('note', 'like', "%{$request->q}%"))
            ->orderByDesc('transaction_date')
            ->paginate(25);

        return view('admin.transactions.index', compact('transactions'));
    }
}
