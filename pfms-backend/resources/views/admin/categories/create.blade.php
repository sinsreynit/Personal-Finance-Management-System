@extends('admin.layouts.app')
@section('title', 'New Category')
@section('content')
    <h1 class="text-2xl font-bold mb-6">New Category</h1>
    <form method="POST" action="{{ route('admin.categories.store') }}" class="bg-white p-6 rounded shadow max-w-md space-y-4">
        @csrf
        <div>
            <label class="block text-sm mb-1">Name</label>
            <input type="text" name="name" value="{{ old('name') }}" class="w-full border rounded px-3 py-2" required>
        </div>
        <div>
            <label class="block text-sm mb-1">Type</label>
            <select name="type" class="w-full border rounded px-3 py-2" required>
                <option value="income">Income</option>
                <option value="expense">Expense</option>
            </select>
        </div>
        <div>
            <label class="block text-sm mb-1">Color</label>
            <input type="color" name="color" value="#6C5CE7" class="w-16 h-10">
        </div>
        <button class="bg-slate-900 text-white px-4 py-2 rounded">Save</button>
    </form>
@endsection
