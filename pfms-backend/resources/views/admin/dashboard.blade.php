@extends('admin.layouts.app')

@section('title', 'Dashboard')

@section('content')

    <h1 class="text-2xl font-bold mb-6">
        Dashboard
    </h1>

    <div class="grid grid-cols-2 md:grid-cols-5 gap-4">

        <div class="bg-white p-4 rounded shadow">
            <div class="text-sm text-gray-500">Users</div>
            <div class="text-2xl font-bold">
                {{ $stats['total_users'] }}
            </div>
        </div>

        <div class="bg-white p-4 rounded shadow">
            <div class="text-sm text-gray-500">Categories</div>
            <div class="text-2xl font-bold">
                {{ $stats['total_categories'] }}
            </div>
        </div>

        <div class="bg-white p-4 rounded shadow">
            <div class="text-sm text-gray-500">Transactions</div>
            <div class="text-2xl font-bold">
                {{ $stats['total_transactions'] }}
            </div>
        </div>

        <div class="bg-white p-4 rounded shadow">
            <div class="text-sm text-gray-500">Total Income</div>
            <div class="text-2xl font-bold text-green-600">
                {{ number_format($stats['total_income'], 2) }}
            </div>
        </div>

        <div class="bg-white p-4 rounded shadow">
            <div class="text-sm text-gray-500">Total Expense</div>
            <div class="text-2xl font-bold text-red-600">
                {{ number_format($stats['total_expense'], 2) }}
            </div>
        </div>

    </div>

    {{-- Database Backup --}}

    <div class="mt-8 bg-white p-6 rounded shadow">

        <h2 class="text-lg font-bold mb-2">
            Database Backup
        </h2>

        <p class="text-gray-600 mb-4">
            Create a backup of the PFMS MySQL database.
        </p>

        <form
            method="POST"
            action="{{ route('admin.backup') }}"
            onsubmit="return confirm('Create a database backup now?');"
        >

            @csrf

            <button
                type="submit"
                class="bg-blue-600 text-white px-5 py-2 rounded hover:bg-blue-700"
            >
                💾 Backup Database
            </button>

        </form>

    </div>

@endsection