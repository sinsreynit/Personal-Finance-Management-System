<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;

class UserController extends Controller
{
    public function index(Request $request)
    {
        $query = User::query();

        if ($request->filled('search')) {
            $search = $request->search;

            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%");
            });
        }

        $users = $query
            ->latest()
            ->paginate(10)
            ->withQueryString();

        return view('admin.users.index', compact('users'));
    }

    public function show(User $user)
    {
        return view('admin.users.show', compact('user'));
    }

    public function updateRole(Request $request, User $user)
    {
        $request->validate([
            'role' => 'required|in:user,admin',
        ]);

        if ($request->user()->is($user) && $request->role !== 'admin') {
            return redirect()->back()->with('error', 'You cannot remove your own administrator role.');
        }

        $user->update([
            'role' => $request->role,
        ]);

        return redirect()
            ->back()
            ->with('success', 'User role updated successfully.');
    }

    public function destroy(Request $request, User $user)
    {
        if ($request->user()->is($user)) {
            return redirect()->route('admin.users.index')->with('error', 'You cannot delete your own account while signed in.');
        }

        $user->delete();

        return redirect()
            ->route('admin.users.index')
            ->with('success', 'User deleted successfully.');
    }
}