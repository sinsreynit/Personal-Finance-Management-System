<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Budget;
use App\Models\Transaction;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;

class ReportController extends Controller
{

    private function range(Request $request): array
    {
        $request->validate([
            'from' => ['nullable', 'date'],
            'to' => ['nullable', 'date', 'after_or_equal:from'],
        ]);

        $from = $request->filled('from')
            ? Carbon::parse($request->from)->startOfDay()
            : Carbon::now()->startOfMonth();

        $to = $request->filled('to')
            ? Carbon::parse($request->to)->endOfDay()
            : Carbon::now()->endOfMonth();

        return [$from, $to];
    }

    private function baseQuery(Request $request, array $range, ?string $type = null)
    {
        return Transaction::with('category')
            ->where('user_id', $request->user()->id)
            ->whereBetween('transaction_date', $range)
            ->when($type, fn ($q) => $q->where('type', $type));
    }

    public function financial(Request $request)
    {
        $range = $this->range($request);

        $income = (float) $this->baseQuery($request, $range, 'income')->sum('amount');
        $expense = (float) $this->baseQuery($request, $range, 'expense')->sum('amount');

        return response()->json([
            'from' => $range[0]->toDateString(),
            'to' => $range[1]->toDateString(),
            'total_income' => $income,
            'total_expense' => $expense,
            'balance' => $income - $expense,
            'transaction_count' => $this->baseQuery($request, $range)->count(),
        ]);
    }

    public function income(Request $request)
    {
        return response()->json($this->groupedReport($request, 'income'));
    }

    
    public function expense(Request $request)
    {
        return response()->json($this->groupedReport($request, 'expense'));
    }

    private function groupedReport(Request $request, string $type): array
    {
        $range = $this->range($request);

        $rows = $this->baseQuery($request, $range, $type)
            ->get()
            ->groupBy(fn ($t) => $t->category?->name ?? 'Uncategorized')
            ->map(function ($group, $categoryName) {
                return [
                    'category' => $categoryName,
                    'total' => (float) $group->sum('amount'),
                    'count' => $group->count(),
                ];
            })
            ->values()
            ->sortByDesc('total')
            ->values();

        return [
            'from' => $range[0]->toDateString(),
            'to' => $range[1]->toDateString(),
            'type' => $type,
            'total' => (float) $rows->sum('total'),
            'by_category' => $rows,
        ];
    }

    // US-022 Budget Report — budgets active in the period vs. actual spend
    public function budget(Request $request)
    {
        $range = $this->range($request);

        $budgets = Budget::with('category')
            ->where('user_id', $request->user()->id)
            ->where('start_date', '<=', $range[1])
            ->where('end_date', '>=', $range[0])
            ->get()
            ->map(function (Budget $b) {
                return [
                    'id' => $b->id,
                    'category' => $b->category?->name ?? 'All categories',
                    'period' => $b->period,
                    'start_date' => $b->start_date->toDateString(),
                    'end_date' => $b->end_date->toDateString(),
                    'amount' => (float) $b->amount,
                    'spent' => $b->spentAmount(),
                    'remaining' => max(0, (float) $b->amount - $b->spentAmount()),
                    'percent_used' => $b->percentUsed(),
                    'over_budget' => $b->spentAmount() > $b->amount,
                ];
            });

        return response()->json([
            'from' => $range[0]->toDateString(),
            'to' => $range[1]->toDateString(),
            'budgets' => $budgets,
        ]);
    }

    // US-023 Charts & Graphs — data shaped for the mobile charting widgets:
    // a monthly income-vs-expense trend, and an expense-by-category breakdown.
    public function chartData(Request $request)
    {
        $range = $this->range($request);
        $userId = $request->user()->id;

        $monthly = Transaction::selectRaw("DATE_FORMAT(transaction_date, '%Y-%m') as ym, type, SUM(amount) as total")
            ->where('user_id', $userId)
            ->whereBetween('transaction_date', $range)
            ->groupBy('ym', 'type')
            ->orderBy('ym')
            ->get()
            ->groupBy('ym')
            ->map(function ($rows, $ym) {
                $byType = $rows->keyBy('type');
                return [
                    'month' => $ym,
                    'income' => (float) ($byType['income']->total ?? 0),
                    'expense' => (float) ($byType['expense']->total ?? 0),
                ];
            })
            ->values();

        $expenseByCategory = $this->baseQuery($request, $range, 'expense')
            ->get()
            ->groupBy(fn ($t) => $t->category?->name ?? 'Uncategorized')
            ->map(fn ($group, $name) => [
                'category' => $name,
                'total' => (float) $group->sum('amount'),
            ])
            ->values()
            ->sortByDesc('total')
            ->values();

        return response()->json([
            'from' => $range[0]->toDateString(),
            'to' => $range[1]->toDateString(),
            'monthly_trend' => $monthly,
            'expense_by_category' => $expenseByCategory,
        ]);
    }

    // US-024 Export PDF — renders the financial report as a downloadable PDF
    public function exportPdf(Request $request)
    {
        $range = $this->range($request);
        $user = $request->user();

        $income = (float) $this->baseQuery($request, $range, 'income')->sum('amount');
        $expense = (float) $this->baseQuery($request, $range, 'expense')->sum('amount');

        $incomeByCategory = $this->groupedReport($request, 'income')['by_category'];
        $expenseByCategory = $this->groupedReport($request, 'expense')['by_category'];

        $pdf = \Barryvdh\DomPDF\Facade\Pdf::loadView('reports.financial-pdf', [
            'user' => $user,
            'from' => $range[0]->toFormattedDateString(),
            'to' => $range[1]->toFormattedDateString(),
            'income' => $income,
            'expense' => $expense,
            'balance' => $income - $expense,
            'incomeByCategory' => $incomeByCategory,
            'expenseByCategory' => $expenseByCategory,
        ]);

        $filename = 'financial-report-'.$range[0]->format('Ymd').'-'.$range[1]->format('Ymd').'.pdf';

        return $pdf->download($filename);
    }
}
