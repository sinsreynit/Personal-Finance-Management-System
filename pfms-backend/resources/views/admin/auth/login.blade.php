<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>PFMS Admin Login</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 flex items-center justify-center min-h-screen">
    <div class="bg-white shadow-md rounded-lg p-8 w-full max-w-sm">
        <h1 class="text-xl font-bold mb-6">PFMS Admin Login</h1>

        @if ($errors->any())
        <div class="bg-red-100 text-red-700 p-3 rounded mb-4">
            {{ $errors->first() }}
        </div>
    @endif

    <form method="POST" action="{{ route('admin.login') }}">
        @csrf

        <label class="block mb-1">Email</label>
        <input type="email" name="email" value="{{ old('email') }}"
               class="w-full border rounded p-2 mb-4" required autofocus>

        <label class="block mb-1">Password</label>
        <input type="password" name="password"
               class="w-full border rounded p-2 mb-4" required>

        <label class="flex items-center mb-4">
            <input type="checkbox" name="remember" class="mr-2">
            Remember me
        </label>

        <button type="submit" class="w-full bg-gray-900 text-white rounded p-2">
            Sign in
        </button>
    </form>
</div>
</body>
</html>
