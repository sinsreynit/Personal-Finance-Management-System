@extends('admin.layouts.app')
@section('title', 'Transactions')
@section('content')
    <h1 class="text-2xl font-bold mb-6">All Transactions</h1>
    <form method="GET" class="mb-4 flex gap-2">
        <input type="text" name="q" value="{{ request('q') }}" placeholder="Search note..." class="border rounded px-3 py-2">
        <select name="type" class="border rounded px-3 py-2">
            <option value="">All types</option>
            <option value="income" @selected(request('type')==='income')>Income</option>
            <option value="expense" @selected(request('type')==='expense')>Expense</option>
        </select>
        <button class="bg-slate-900 text-white px-4 py-2 rounded">Filter</button>
    </form>
    <table class="w-full bg-white rounded shadow">
        <thead class="bg-gray-100 text-left text-sm">
            <tr>
                <th class="p-3">Date</th>
                <th class="p-3">User</th>
                <th class="p-3">Category</th>
                <th class="p-3">Type</th>
                <th class="p-3">Amount</th>
                <th class="p-3">Note</th>
            </tr>
        </thead>
        <tbody>
            @foreach ($transactions as $t)
                <tr class="border-t">
                    <td class="p-3">{{ $t->transaction_date->format('Y-m-d') }}</td>
                    <td class="p-3">{{ $t->user->name }}</td>
                    <td class="p-3">{{ $t->category->name }}</td>
                    <td class="p-3 capitalize">{{ $t->type }}</td>
                    <td class="p-3 {{ $t->type === 'income' ? 'text-green-600' : 'text-red-600' }}">{{ number_format($t->amount, 2) }}</td>
                    <td class="p-3">{{ $t->note }}</td>
                </tr>
            @endforeach
        </tbody>
    </table>
    <div class="mt-4">{{ $transactions->links() }}</div>
@endsection
