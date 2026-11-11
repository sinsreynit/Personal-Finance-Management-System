<?php

use App\Http\Controllers\Admin\DashboardController;
use App\Http\Controllers\Admin\AuthController as AdminAuthController;
use App\Http\Controllers\Admin\CategoryController as AdminCategoryController;
use App\Http\Controllers\Admin\TransactionController as AdminTransactionController;
use App\Http\Controllers\Admin\ProfileController;
use App\Http\Controllers\Admin\UserController as AdminUserController;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Route;

Route::get('/admin/login', [AdminAuthController::class, 'showLogin'])
    ->name('admin.login');

Route::post('/admin/login', [AdminAuthController::class, 'login'])
    ->name('admin.login.submit');

Route::post('/admin/logout', [AdminAuthController::class, 'logout'])
    ->name('admin.logout');

Route::middleware(['auth', 'admin'])->group(function () {

    Route::get('/admin', [DashboardController::class, 'index'])
        ->name('admin.dashboard');

    Route::resource('categories', AdminCategoryController::class)
        ->except(['show'])
        ->names('admin.categories');

    Route::get('/transactions', [AdminTransactionController::class, 'index'])
        ->name('admin.transactions.index');

    Route::get('/profile', [ProfileController::class, 'edit'])
        ->name('profile.edit');

    Route::put('/profile', [ProfileController::class, 'update'])
        ->name('profile.update');

    Route::put('/profile/password', [ProfileController::class, 'changePassword'])
        ->name('profile.password');

    Route::resource('admin/users', AdminUserController::class)
        ->only(['index', 'show', 'destroy'])
        ->names('admin.users');

    Route::put('/admin/users/{user}/role', [AdminUserController::class, 'updateRole'])
        ->name('admin.users.updateRole');

    Route::post('/admin/backup', function () {

        try {

            $exitCode = Artisan::call('db:backup');

            if ($exitCode !== 0) {
                throw new \RuntimeException('Backup command returned a failure status.');
            }

            return redirect()
                ->route('admin.dashboard')
                ->with('status', 'Database backup created successfully.');

        } catch (\Throwable $e) {

            return redirect()
                ->route('admin.dashboard')
                ->with('error', 'Database backup failed.');

        }

    })->name('admin.backup');
});

Route::get('/', function () {
    return redirect('/admin');
});