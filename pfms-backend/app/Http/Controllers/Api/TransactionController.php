<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\TransactionRequest;
use App\Models\Budget;
use App\Models\Category;
use App\Models\SavingsGoal;
use App\Models\Transaction;
use Illuminate\Http\Request;

class TransactionController extends Controller
{
    public function index(Request $request)
    {
        $perPage = min(max((int) $request->input('per_page', 20), 1), 100);

        $transactions = Transaction::with('category')
            ->where('user_id', $request->user()->id)
            ->when(
                $request->type,
                fn ($q) => $q->where('type', $request->type)
            )
            ->when(
                $request->from,
                fn ($q) => $q->whereDate(
                    'transaction_date',
                    '>=',
                    $request->from
                )
            )
            ->when(
                $request->to,
                fn ($q) => $q->whereDate(
                    'transaction_date',
                    '<=',
                    $request->to
                )
            )
            ->orderByDesc('transaction_date')
            ->paginate($perPage);

        return response()->json($transactions);
    }

    public function store(TransactionRequest $request)
    {
        $data = $request->validated();

        $category = Category::visibleTo(
            $request->user()->id
        )->findOrFail($data['category_id']);

        abort_if(
            $category->type !== $data['type'],
            422,
            'Category type does not match transaction type.'
        );

        if ($data['type'] === 'expense') {
            $this->checkBudgetLimit(
                userId: $request->user()->id,
                categoryId: $data['category_id'],
                transactionDate: $data['transaction_date'],
                newAmount: (float) $data['amount']
            );

            $this->checkAvailableBalance(
                userId: $request->user()->id,
                newExpenseAmount: (float) $data['amount']
            );
        }

        $transaction = Transaction::create([
            ...$data,
            'user_id' => $request->user()->id,
        ]);

        return response()->json(
            $transaction->load('category'),
            201
        );
    }

    public function update(
        TransactionRequest $request,
        Transaction $transaction
    ) {
        abort_if(
            $transaction->user_id !== $request->user()->id,
            403
        );

        $data = $request->validated();

        $category = Category::visibleTo(
            $request->user()->id
        )->findOrFail($data['category_id']);

        abort_if(
            $category->type !== $data['type'],
            422,
            'Category type does not match transaction type.'
        );

        if ($data['type'] === 'expense') {
            $this->checkBudgetLimit(
                userId: $request->user()->id,
                categoryId: $data['category_id'],
                transactionDate: $data['transaction_date'],
                newAmount: (float) $data['amount'],
                ignoreTransactionId: $transaction->id
            );

            $this->checkAvailableBalance(
                userId: $request->user()->id,
                newExpenseAmount: (float) $data['amount'],
                ignoreTransaction: $transaction
            );
        }

        $transaction->update($data);

        return response()->json(
            $transaction->load('category')
        );
    }

    public function destroy(
        Request $request,
        Transaction $transaction
    ) {
        abort_if(
            $transaction->user_id !== $request->user()->id,
            403
        );

        $transaction->delete();

        return response()->json([
            'message' => 'Transaction deleted.',
        ]);
    }

    // US-012 Search Transactions
    public function search(Request $request)
    {
        $request->validate([
            'q' => 'nullable|string',
        ]);

        $perPage = min(max((int) $request->input('per_page', 20), 1), 100);

        $transactions = Transaction::with('category')
            ->where('user_id', $request->user()->id)
            ->when($request->q, function ($q) use ($request) {
                $q->where(function ($sub) use ($request) {
                    $sub->where(
                        'note',
                        'like',
                        "%{$request->q}%"
                    )->orWhereHas(
                        'category',
                        fn ($c) => $c->where(
                            'name',
                            'like',
                            "%{$request->q}%"
                        )
                    );
                });
            })
            ->when(
                $request->type,
                fn ($q) => $q->where(
                    'type',
                    $request->type
                )
            )
            ->when(
                $request->category_id,
                fn ($q) => $q->where(
                    'category_id',
                    $request->category_id
                )
            )
            ->when(
                $request->min_amount,
                fn ($q) => $q->where(
                    'amount',
                    '>=',
                    $request->min_amount
                )
            )
            ->when(
                $request->max_amount,
                fn ($q) => $q->where(
                    'amount',
                    '<=',
                    $request->max_amount
                )
            )
            ->when(
                $request->from,
                fn ($q) => $q->whereDate(
                    'transaction_date',
                    '>=',
                    $request->from
                )
            )
            ->when(
                $request->to,
                fn ($q) => $q->whereDate(
                    'transaction_date',
                    '<=',
                    $request->to
                )
            )
            ->orderByDesc('transaction_date')
            ->paginate($perPage);

        return response()->json($transactions);
    }

    private function checkBudgetLimit(
        int $userId,
        int $categoryId,
        string $transactionDate,
        float $newAmount,
        ?int $ignoreTransactionId = null
    ): void {
        $budgets = Budget::where('user_id', $userId)
            ->where('category_id', $categoryId)
            ->whereDate('start_date', '<=', $transactionDate)
            ->whereDate('end_date', '>=', $transactionDate)
            ->get();

        foreach ($budgets as $budget) {
            $spentQuery = Transaction::where(
                'user_id',
                $userId
            )
                ->where(
                    'category_id',
                    $categoryId
                )
                ->where(
                    'type',
                    'expense'
                )
                ->whereBetween(
                    'transaction_date',
                    [
                        $budget->start_date,
                        $budget->end_date,
                    ]
                );

            if ($ignoreTransactionId !== null) {
                $spentQuery->where(
                    'id',
                    '!=',
                    $ignoreTransactionId
                );
            }

            $alreadySpent = (float) $spentQuery->sum('amount');
            $newTotal = $alreadySpent + $newAmount;

            if ($newTotal > (float) $budget->amount) {
                $remaining = max(
                    0,
                    (float) $budget->amount - $alreadySpent
                );

                abort(
                    422,
                    sprintf(
                        'Budget limit exceeded. Budget: $%.2f, Already spent: $%.2f, Remaining: $%.2f.',
                        (float) $budget->amount,
                        $alreadySpent,
                        $remaining
                    )
                );
            }
        }
    }

    private function checkAvailableBalance(
        int $userId,
        float $newExpenseAmount,
        ?Transaction $ignoreTransaction = null
    ): void {
        $incomeQuery = Transaction::where(
            'user_id',
            $userId
        )->where(
            'type',
            'income'
        );

        $expenseQuery = Transaction::where(
            'user_id',
            $userId
        )->where(
            'type',
            'expense'
        );

        if ($ignoreTransaction !== null) {
            if ($ignoreTransaction->type === 'income') {
                $incomeQuery->where(
                    'id',
                    '!=',
                    $ignoreTransaction->id
                );
            }

            if ($ignoreTransaction->type === 'expense') {
                $expenseQuery->where(
                    'id',
                    '!=',
                    $ignoreTransaction->id
                );
            }
        }

        $income = (float) $incomeQuery->sum('amount');
        $expense = (float) $expenseQuery->sum('amount');
        $saved = (float) SavingsGoal::where(
            'user_id',
            $userId
        )->sum('current_amount');

        $available = $income - $expense - $saved;

        if ($newExpenseAmount > $available) {
            abort(
                422,
                sprintf(
                    'Not enough available balance. Available: $%.2f.',
                    max(0, $available)
                )
            );
        }
    }
}
