<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <title>User Details - PFMS Admin</title>

    <style>
        body {
            margin: 0;
            font-family: Arial, sans-serif;
            background: #f5f6fa;
        }

        .container {
            padding: 30px;
            max-width: 900px;
            margin: auto;
        }

        h1 {
            margin-bottom: 25px;
        }

        .card {
            background: white;
            padding: 25px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.08);
        }

        .row {
            display: flex;
            padding: 15px 0;
            border-bottom: 1px solid #eee;
        }

        .label {
            width: 180px;
            font-weight: bold;
            color: #555;
        }

        .value {
            flex: 1;
            color: #222;
        }

        .actions {
            margin-top: 25px;
            display: flex;
            gap: 10px;
        }

        .btn {
            display: inline-block;
            padding: 10px 18px;
            border-radius: 5px;
            text-decoration: none;
            border: none;
            cursor: pointer;
            font-size: 14px;
        }

        .btn-back {
            background: #6c757d;
            color: white;
        }

        .btn-delete {
            background: #dc3545;
            color: white;
        }

        .btn-update {
            background: #2563eb;
            color: white;
        }

        .btn-update:hover {
            background: #1d4ed8;
        }

        .role-select {
            padding: 8px 12px;
            border: 1px solid #ccc;
            border-radius: 5px;
            font-size: 14px;
            margin-right: 10px;
        }

        .role {
            display: inline-block;
            padding: 5px 12px;
            border-radius: 15px;
            background: #e8eaf6;
            color: #3949ab;
            font-size: 13px;
            margin-right: 15px;
        }

        .success {
            background: #d1fae5;
            color: #065f46;
            padding: 12px 15px;
            border-radius: 5px;
            margin-bottom: 20px;
        }

        .error {
            background: #fee2e2;
            color: #991b1b;
            padding: 12px 15px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
    </style>
</head>

<body>

<div class="container">

    <h1>User Details</h1>

    {{-- Success message --}}
    @if(session('success'))
        <div class="success">
            {{ session('success') }}
        </div>
    @endif

    {{-- Error message --}}
    @if(session('error'))
        <div class="error">
            {{ session('error') }}
        </div>
    @endif

    <div class="card">

        <div class="row">
            <div class="label">ID</div>
            <div class="value">
                {{ $user->id }}
            </div>
        </div>

        <div class="row">
            <div class="label">Name</div>
            <div class="value">
                {{ $user->name }}
            </div>
        </div>

        <div class="row">
            <div class="label">Email</div>
            <div class="value">
                {{ $user->email }}
            </div>
        </div>

        {{-- Role Management --}}
        <div class="row">
            <div class="label">Role</div>

            <div class="value">

                <span class="role">
                    {{ $user->role ?? 'user' }}
                </span>

                <form
                    method="POST"
                    action="{{ route('admin.users.updateRole', $user) }}"
                    style="display: inline;"
                >

                    @csrf
                    @method('PUT')

                    <select
                        name="role"
                        class="role-select"
                    >
                        <option value="user"
                            {{ ($user->role ?? 'user') === 'user' ? 'selected' : '' }}>
                            User
                        </option>

                        <option value="admin"
                            {{ ($user->role ?? 'user') === 'admin' ? 'selected' : '' }}>
                            Admin
                        </option>
                    </select>

                    <button
                        type="submit"
                        class="btn btn-update"
                    >
                        Update Role
                    </button>

                </form>

            </div>
        </div>

        <div class="row">
            <div class="label">Currency</div>

            <div class="value">
                {{ $user->currency ?? 'Not set' }}
            </div>
        </div>

        <div class="row">
            <div class="label">Phone</div>

            <div class="value">
                {{ $user->phone ?? 'Not set' }}
            </div>
        </div>

        <div class="row">
            <div class="label">Created</div>

            <div class="value">
                {{ $user->created_at?->format('Y-m-d H:i') }}
            </div>
        </div>

        <div class="actions">

            <a
                href="{{ route('admin.users.index') }}"
                class="btn btn-back"
            >
                ← Back to Users
            </a>

            <form
                method="POST"
                action="{{ route('admin.users.destroy', $user) }}"
                onsubmit="return confirm('Are you sure you want to delete this user?');"
            >

                @csrf
                @method('DELETE')

                <button
                    type="submit"
                    class="btn btn-delete"
                >
                    Delete User
                </button>

            </form>

        </div>

    </div>

</div>

</body>
</html>