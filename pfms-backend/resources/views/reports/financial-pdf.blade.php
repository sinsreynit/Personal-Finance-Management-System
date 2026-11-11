<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <style>
        body { font-family: sans-serif; font-size: 12px; color: #222; }
        h1 { font-size: 18px; margin-bottom: 0; }
        .subtitle { color: #666; margin-top: 4px; margin-bottom: 20px; }
        .summary { width: 100%; margin-bottom: 24px; }
        .summary td { padding: 8px 12px; border: 1px solid #ddd; }
        .summary .label { color: #666; }
        .income { color: #1a7f37; font-weight: bold; }
        .expense { color: #cf222e; font-weight: bold; }
        table.detail { width: 100%; border-collapse: collapse; margin-bottom: 20px; }
        table.detail th, table.detail td { border: 1px solid #ddd; padding: 6px 10px; text-align: left; }
        table.detail th { background: #f5f5f5; }
        h2 { font-size: 14px; margin-top: 24px; margin-bottom: 8px; }
    </style>
</head>
<body>
    <h1>Financial Report</h1>
    <div class="subtitle">{{ $user->name }} &middot; {{ $from }} &ndash; {{ $to }}</div>

    <table class="summary">
        <tr>
            <td class="label">Total Income</td>
            <td class="income">{{ number_format($income, 2) }}</td>
            <td class="label">Total Expense</td>
            <td class="expense">{{ number_format($expense, 2) }}</td>
            <td class="label">Balance</td>
            <td>{{ number_format($balance, 2) }}</td>
        </tr>
    </table>

    <h2>Income by Category</h2>
    <table class="detail">
        <tr><th>Category</th><th>Transactions</th><th>Total</th></tr>
        @forelse($incomeByCategory as $row)
        <tr>
            <td>{{ $row['category'] }}</td>
            <td>{{ $row['count'] }}</td>
            <td>{{ number_format($row['total'], 2) }}</td>
        </tr>
        @empty
        <tr><td colspan="3">No income recorded for this period.</td></tr>
        @endforelse
    </table>

    <h2>Expense by Category</h2>
    <table class="detail">
        <tr><th>Category</th><th>Transactions</th><th>Total</th></tr>
        @forelse($expenseByCategory as $row)
        <tr>
            <td>{{ $row['category'] }}</td>
            <td>{{ $row['count'] }}</td>
            <td>{{ number_format($row['total'], 2) }}</td>
        </tr>
        @empty
        <tr><td colspan="3">No expenses recorded for this period.</td></tr>
        @endforelse
    </table>
</body>
</html>
