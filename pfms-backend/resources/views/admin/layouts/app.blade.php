<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PFMS Admin — @yield('title', 'Dashboard')</title>

    <script src="https://cdn.tailwindcss.com"></script>
</head>

<body class="bg-gray-50 text-gray-800">

<div class="flex min-h-screen">

    <aside class="w-56 bg-slate-900 text-white flex flex-col">

        <div class="p-4 text-lg font-bold border-b border-slate-700">
            PFMS Admin
        </div>

        <nav class="flex-1 p-2">

            <a href="{{ route('admin.dashboard') }}"
               class="block px-3 py-2 mb-1 rounded hover:bg-slate-700">
                Dashboard
            </a>

            <a href="{{ route('admin.users.index') }}"
               class="block px-3 py-2 mb-1 rounded hover:bg-slate-700">
                Users
            </a>

            <a href="{{ route('admin.categories.index') }}"
               class="block px-3 py-2 mb-1 rounded hover:bg-slate-700">
                Categories
            </a>

            <a href="{{ route('admin.transactions.index') }}"
               class="block px-3 py-2 mb-1 rounded hover:bg-slate-700">
                Transactions
            </a>

            <a href="{{ route('profile.edit') }}"
               class="block px-3 py-2 mb-1 rounded hover:bg-slate-700">
                Profile
            </a>

        </nav>

        <form method="POST"
              action="{{ route('admin.logout') }}"
              class="p-2 border-t border-slate-700">

            @csrf

            <button type="submit"
                    class="w-full text-left px-3 py-2 rounded hover:bg-slate-700">
                Logout
            </button>

        </form>

    </aside>

    <main class="flex-1 p-6">

        @if (session('status'))
            <div class="mb-4 p-3 bg-green-100 text-green-800 rounded">
                {{ session('status') }}
            </div>
        @endif

        @if (session('error'))
            <div class="mb-4 p-3 bg-red-100 text-red-800 rounded">
                {{ session('error') }}
            </div>
        @endif

        @yield('content')

    </main>

</div>

</body>
</html>