<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\SavingsGoal;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class SavingsGoalController extends Controller
{
    public function index(Request $request)
    {
        return response()->json(
            $request->user()
                ->savingsGoals()
                ->latest()
                ->get()
        );
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'target_amount' => ['required', 'numeric', 'min:0.01'],
            'target_date' => ['nullable', 'date'],
        ]);

        $goal = $request->user()
            ->savingsGoals()
            ->create([
                ...$validated,
                'current_amount' => 0,
            ]);

        return response()->json($goal, 201);
    }

    public function update(
        Request $request,
        SavingsGoal $savingsGoal
    ) {
        abort_unless(
            $savingsGoal->user_id === $request->user()->id,
            403
        );

        $validated = $request->validate([
            'name' => ['sometimes', 'string', 'max:255'],
            'target_amount' => ['sometimes', 'numeric', 'min:0.01'],
            'target_date' => ['nullable', 'date'],
        ]);

        $newTarget = array_key_exists(
            'target_amount',
            $validated
        )
            ? (float) $validated['target_amount']
            : (float) $savingsGoal->target_amount;

        if ($newTarget < (float) $savingsGoal->current_amount) {
            return response()->json([
                'message' => sprintf(
                    'Target amount cannot be lower than the current saved amount of $%.2f.',
                    (float) $savingsGoal->current_amount
                ),
            ], 422);
        }

        $savingsGoal->update($validated);

        return response()->json(
            $savingsGoal->fresh()
        );
    }

    public function destroy(
        Request $request,
        SavingsGoal $savingsGoal
    ) {
        abort_unless(
            $savingsGoal->user_id === $request->user()->id,
            403
        );

        $savingsGoal->delete();

        return response()->json([
            'message' => 'Goal deleted.',
        ]);
    }

    public function addProgress(
        Request $request,
        SavingsGoal $savingsGoal
    ) {
        abort_unless(
            $savingsGoal->user_id === $request->user()->id,
            403
        );

        $validated = $request->validate([
            'amount' => ['required', 'numeric', 'gt:0'],
        ]);

        $amount = (float) $validated['amount'];

        return DB::transaction(function () use (
            $request,
            $savingsGoal,
            $amount
        ) {
            $goal = SavingsGoal::whereKey(
                $savingsGoal->id
            )
                ->lockForUpdate()
                ->firstOrFail();

            $remainingToGoal = max(
                0,
                (float) $goal->target_amount -
                    (float) $goal->current_amount
            );

            if ($amount > $remainingToGoal) {
                return response()->json([
                    'message' => sprintf(
                        'You can add at most $%.2f to this savings goal.',
                        $remainingToGoal
                    ),
                ], 422);
            }

            $user = $request->user();

            $income = (float) $user->transactions()
                ->where('type', 'income')
                ->sum('amount');

            $expense = (float) $user->transactions()
                ->where('type', 'expense')
                ->sum('amount');

            $saved = (float) $user->savingsGoals()
                ->sum('current_amount');

            $availableBalance =
                $income -
                $expense -
                $saved;

            if ($amount > $availableBalance) {
                return response()->json([
                    'message' => sprintf(
                        'Not enough available balance. Available: $%.2f.',
                        max(0, $availableBalance)
                    ),
                    'available_balance' => max(
                        0,
                        round($availableBalance, 2)
                    ),
                ], 422);
            }

            $goal->current_amount =
                (float) $goal->current_amount + $amount;

            $goal->save();

            $newAvailableBalance =
                $availableBalance - $amount;

            return response()->json([
                'goal' => $goal->fresh(),
                'percent' => $goal->progressPercent(),
                'available_balance' => round(
                    max(0, $newAvailableBalance),
                    2
                ),
            ]);
        });
    }
}
