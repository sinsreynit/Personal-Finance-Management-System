<form method="POST" action="{{ route('admin.logout') }}" class="p-2 border-t border-slate-700">
    @csrf
    <button class="w-full text-left px-3 py-2 rounded hover:bg-slate-700">Logout</button>
</form>