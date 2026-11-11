<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\CategoryRequest;
use App\Models\Category;
use Illuminate\Http\Request;

class CategoryController extends Controller
{
    public function index(Request $request)
    {
        $categories = Category::visibleTo($request->user()->id)
            ->when($request->type, fn ($q) => $q->where('type', $request->type))
            ->orderBy('name')
            ->get();

        return response()->json($categories);
    }

    public function store(CategoryRequest $request)
    {
        $category = Category::create([
            ...$request->validated(),
            'user_id' => $request->user()->id,
        ]);

        return response()->json($category, 201);
    }

    public function update(CategoryRequest $request, Category $category)
    {
        abort_if($category->user_id !== $request->user()->id, 403, 'You can only edit your own categories.');

        $category->update($request->validated());

        return response()->json($category);
    }

    public function destroy(Request $request, Category $category)
    {
        abort_if($category->user_id !== $request->user()->id, 403, 'You can only delete your own categories.');
        abort_if($category->transactions()->exists(), 422, 'Cannot delete a category with existing transactions.');

        $category->delete();

        return response()->json(['message' => 'Category deleted.']);
    }
}
