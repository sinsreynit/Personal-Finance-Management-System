@extends('admin.layouts.app')
@section('title', 'Edit Category')
@section('content')
    <h1 class="text-2xl font-bold mb-6">Edit Category</h1>
    <form method="POST" action="{{ route('admin.categories.update', $category) }}" class="bg-white p-6 rounded shadow max-w-md space-y-4">
        @csrf @method('PUT')
        <div>
            <label class="block text-sm mb-1">Name</label>
            <input type="text" name="name" value="{{ old('name', $category->name) }}" class="w-full border rounded px-3 py-2" required>
        </div>
        <div>
            <label class="block text-sm mb-1">Type</label>
            <select name="type" class="w-full border rounded px-3 py-2" required>
                <option value="income" @selected($category->type === 'income')>Income</option>
                <option value="expense" @selected($category->type === 'expense')>Expense</option>
            </select>
        </div>
        <div>
            <label class="block text-sm mb-1">Color</label>
            <input type="color" name="color" value="{{ $category->color }}" class="w-16 h-10">
        </div>
        <button class="bg-slate-900 text-white px-4 py-2 rounded">Update</button>
    </form>
@endsection
