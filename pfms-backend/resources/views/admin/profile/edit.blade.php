@extends('admin.layouts.app')

@section('title', 'Profile')

@section('content')

    <h1 class="text-2xl font-bold mb-6">Profile</h1>

    @if(session('status'))
        <div class="mb-4 p-3 bg-green-100 text-green-800 rounded">
            {{ session('status') }}
        </div>
    @endif

    @if($errors->any())
        <div class="mb-4 p-3 bg-red-100 text-red-800 rounded">
            <ul>
                @foreach($errors->all() as $error)
                    <li>{{ $error }}</li>
                @endforeach
            </ul>
        </div>
    @endif

    <form method="POST" action="{{ route('profile.update') }}">

        @csrf
        @method('PUT')

        <div class="mb-4">

            <label class="block mb-1 font-medium">
                Name
            </label>

            <input
                type="text"
                name="name"
                value="{{ old('name', $user->name) }}"
                class="w-full border rounded px-3 py-2"
                required
            >

        </div>

        <div class="mb-4">

            <label class="block mb-1 font-medium">
                Email
            </label>

            <input
                type="email"
                name="email"
                value="{{ old('email', $user->email) }}"
                class="w-full border rounded px-3 py-2"
                required
            >

        </div>

        <button
            type="submit"
            class="px-4 py-2 bg-blue-600 text-white rounded"
        >
            Save Changes
        </button>

    </form>

@endsection