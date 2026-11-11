<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Budget;
use App\Models\Category;
use Illuminate\Http\Request;

class BudgetController extends Controller
{
    public function index(Request $request)
    {
        $budgets = $request->user()
            ->budgets()
            ->with('category')
            ->latest()
            ->get();

        return response()->json($budgets);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'category_id' => ['required', 'exists:categories,id'],
            'amount' => ['required', 'numeric', 'min:0.01'],
            'period' => ['required', 'in:weekly,monthly,yearly'],
            'start_date' => ['required', 'date'],
            'end_date' => ['required', 'date', 'after_or_equal:start_date'],
        ]);

        $category = Category::visibleTo(
            $request->user()->id
        )->findOrFail($validated['category_id']);

        abort_if(
            $category->type !== 'expense',
            422,
            'A budget can only use an expense category.'
        );

        $this->ensureAmountCoversExistingSpending(
            $request->user()->id,
            (int) $validated['category_id'],
            $validated['start_date'],
            $validated['end_date'],
            (float) $validated['amount']
        );

        $budget = $request->user()
            ->budgets()
            ->create($validated);

        return response()->json(
            $budget->load('category'),
            201
        );
    }

    public function update(
        Request $request,
        Budget $budget
    ) {
        abort_unless(
            $budget->user_id === $request->user()->id,
            403
        );

        $validated = $request->validate([
            'category_id' => ['sometimes', 'required', 'exists:categories,id'],
            'amount' => ['sometimes', 'numeric', 'min:0.01'],
            'period' => ['sometimes', 'in:weekly,monthly,yearly'],
            'start_date' => ['sometimes', 'date'],
            'end_date' => ['sometimes', 'date'],
        ]);

        $categoryId = (int) (
            $validated['category_id']
            ?? $budget->category_id
        );

        $startDate = $validated['start_date']
            ?? $budget->start_date->format('Y-m-d');

        $endDate = $validated['end_date']
            ?? $budget->end_date->format('Y-m-d');

        if ($endDate < $startDate) {
            return response()->json([
                'message' =>
                    'End date must be on or after start date.',
            ], 422);
        }

        $category = Category::visibleTo(
            $request->user()->id
        )->findOrFail($categoryId);

        abort_if(
            $category->type !== 'expense',
            422,
            'A budget can only use an expense category.'
        );

        $amount = (float) (
            $validated['amount']
            ?? $budget->amount
        );

        $this->ensureAmountCoversExistingSpending(
            $request->user()->id,
            $categoryId,
            $startDate,
            $endDate,
            $amount
        );

        $budget->update([
            ...$validated,
            'category_id' => $categoryId,
            'amount' => $amount,
            'start_date' => $startDate,
            'end_date' => $endDate,
        ]);

        return response()->json(
            $budget->fresh('category')
        );
    }

    public function destroy(
        Request $request,
        Budget $budget
    ) {
        abort_unless(
            $budget->user_id === $request->user()->id,
            403
        );

        $budget->delete();

        return response()->json([
            'message' => 'Budget deleted.',
        ]);
    }

    public function monitor(
        Request $request,
        Budget $budget
    ) {
        abort_unless(
            $budget->user_id === $request->user()->id,
            403
        );

        $spent = $budget->spentAmount();

        return response()->json([
            'budget_id' => $budget->id,
            'amount' => (float) $budget->amount,
            'spent' => $spent,
            'remaining' => max(
                0,
                (float) $budget->amount - $spent
            ),
            'percent_used' => $budget->percentUsed(),
            'over_budget' => $spent > (float) $budget->amount,
        ]);
    }

    private function ensureAmountCoversExistingSpending(
        int $userId,
        int $categoryId,
        string $startDate,
        string $endDate,
        float $amount
    ): void {
        $spent = (float) \App\Models\Transaction::where(
            'user_id',
            $userId
        )
            ->where('category_id', $categoryId)
            ->where('type', 'expense')
            ->whereBetween(
                'transaction_date',
                [$startDate, $endDate]
            )
            ->sum('amount');

        if ($spent > $amount) {
            abort(
                422,
                sprintf(
                    'Budget amount cannot be lower than existing spending. Spent: $%.2f.',
                    $spent
                )
            );
        }
    }
}
