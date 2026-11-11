@extends('admin.layouts.app')

@section('title', 'Users')

@section('content')

    <div class="flex justify-between items-center mb-6">

        <h1 class="text-2xl font-bold">
            User Management
        </h1>

        <form method="GET" action="{{ route('admin.users.index') }}">

            <div class="flex gap-2">

                <input
                    type="text"
                    name="search"
                    placeholder="Search name or email..."
                    value="{{ request('search') }}"
                    class="px-3 py-2 border border-gray-300 rounded"
                >

                <button
                    type="submit"
                    class="bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700"
                >
                    Search
                </button>

            </div>

        </form>

    </div>


    @if(session('success'))

        <div class="mb-4 p-3 bg-green-100 text-green-800 rounded">
            {{ session('success') }}
        </div>

    @endif


    <div class="bg-white rounded shadow overflow-x-auto">

        <table class="w-full">

            <thead class="bg-gray-100 text-left text-sm">

                <tr>

                    <th class="p-3">
                        ID
                    </th>

                    <th class="p-3">
                        Name
                    </th>

                    <th class="p-3">
                        Email
                    </th>

                    <th class="p-3">
                        Role
                    </th>

                    <th class="p-3">
                        Created
                    </th>

                    <th class="p-3">
                        Actions
                    </th>

                </tr>

            </thead>


            <tbody>

                @forelse($users as $user)

                    <tr class="border-t">

                        <td class="p-3">
                            {{ $user->id }}
                        </td>

                        <td class="p-3">
                            {{ $user->name }}
                        </td>

                        <td class="p-3">
                            {{ $user->email }}
                        </td>

                        <td class="p-3">

                            <span class="px-2 py-1 text-sm rounded-full bg-indigo-100 text-indigo-800">

                                {{ $user->role ?? 'user' }}

                            </span>

                        </td>

                        <td class="p-3">
                            {{ $user->created_at?->format('Y-m-d') }}
                        </td>

                        <td class="p-3">

                            <a
                                href="{{ route('admin.users.show', $user) }}"
                                class="bg-blue-600 text-white px-3 py-1 rounded hover:bg-blue-700"
                            >
                                View
                            </a>


                            <form
                                method="POST"
                                action="{{ route('admin.users.destroy', $user) }}"
                                class="inline"
                                onsubmit="return confirm('Are you sure you want to delete this user?');"
                            >

                                @csrf

                                @method('DELETE')

                                <button
                                    type="submit"
                                    class="bg-red-600 text-white px-3 py-1 rounded hover:bg-red-700"
                                >
                                    Delete
                                </button>

                            </form>

                        </td>

                    </tr>

                @empty

                    <tr>

                        <td
                            colspan="6"
                            class="p-4 text-center text-gray-500"
                        >
                            No users found.
                        </td>

                    </tr>

                @endforelse

            </tbody>

        </table>

    </div>


    <div class="mt-5">

        {{ $users->links() }}

    </div>

@endsection