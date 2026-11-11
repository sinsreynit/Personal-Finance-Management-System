<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    public function summary(Request $request)
    {
        $user = $request->user();

        $income = (float) $user->transactions()
            ->where('type', 'income')
            ->sum('amount');

        $expense = (float) $user->transactions()
            ->where('type', 'expense')
            ->sum('amount');

        $saved = (float) $user->savingsGoals()
            ->sum('current_amount');

        $balance = $income - $expense - $saved;

        $budgets = $user->budgets()
            ->with('category')
            ->get()
            ->map(fn ($b) => [
                'id' => $b->id,
                'category_id' => $b->category_id,
                'category_name' => $b->category?->name,
                'category' => $b->category?->name,
                'amount' => (float) $b->amount,
                'period' => $b->period,
                'start_date' => $b->start_date?->format('Y-m-d'),
                'end_date' => $b->end_date?->format('Y-m-d'),
                'spent' => $b->spentAmount(),
                'percent_used' => $b->percentUsed(),
            ])
            ->values();

        $goals = $user->savingsGoals()
            ->latest()
            ->get()
            ->map(fn ($g) => [
                'id' => $g->id,
                'name' => $g->name,
                'target_amount' => (float) $g->target_amount,
                'current_amount' => (float) $g->current_amount,
                'target_date' => $g->target_date?->format('Y-m-d'),
                'percent' => $g->progressPercent(),
            ])
            ->values();

        return response()->json([
            'total_income' => round($income, 2),
            'total_expense' => round($expense, 2),
            'total_saved' => round($saved, 2),
            'balance' => round($balance, 2),
            'budgets' => $budgets,
            'savings_goals' => $goals,
        ]);
    }
}
