@extends('admin.layouts.app')
@section('title', 'Categories')
@section('content')
    <div class="flex justify-between items-center mb-6">
        <h1 class="text-2xl font-bold">Default Categories</h1>
        <a href="{{ route('admin.categories.create') }}" class="bg-slate-900 text-white px-4 py-2 rounded">+ New Category</a>
    </div>
    <table class="w-full bg-white rounded shadow">
        <thead class="bg-gray-100 text-left text-sm">
            <tr>
                <th class="p-3">Name</th>
                <th class="p-3">Type</th>
                <th class="p-3">Color</th>
                <th class="p-3">Actions</th>
            </tr>
        </thead>
        <tbody>
            @foreach ($categories as $category)
                <tr class="border-t">
                    <td class="p-3">{{ $category->name }}</td>
                    <td class="p-3 capitalize">{{ $category->type }}</td>
                    <td class="p-3"><span class="inline-block w-4 h-4 rounded" style="background:{{ $category->color }}"></span></td>
                    <td class="p-3 space-x-2">
                        <a href="{{ route('admin.categories.edit', $category) }}" class="text-blue-600">Edit</a>
                        <form action="{{ route('admin.categories.destroy', $category) }}" method="POST" class="inline" onsubmit="return confirm('Delete this category?')">
                            @csrf @method('DELETE')
                            <button class="text-red-600">Delete</button>
                        </form>
                    </td>
                </tr>
            @endforeach
        </tbody>
    </table>
@endsection
