<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CategoryController;
use App\Http\Controllers\Api\ProfileController;
use App\Http\Controllers\Api\TransactionController;
use App\Http\Controllers\Api\BudgetController;
use App\Http\Controllers\Api\SavingsGoalController;
use App\Http\Controllers\Api\DashboardController;
use App\Http\Controllers\Api\ReportController;
use Illuminate\Support\Facades\Route;

Route::middleware('throttle:10,1')->group(function () {
    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/login', [AuthController::class, 'login']);
});

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    
    Route::get('/profile', [ProfileController::class, 'show']);
    Route::put('/profile', [ProfileController::class, 'update']);
    Route::put('/profile/password', [ProfileController::class, 'changePassword']);
    
    Route::apiResource('categories', CategoryController::class)->except(['show']);
    
    Route::get('/transactions/search', [TransactionController::class, 'search']);
    Route::apiResource('transactions', TransactionController::class)->except(['show']);

    Route::apiResource('budgets', BudgetController::class)->except(['show']);
    Route::get('/budgets/{budget}/monitor', [BudgetController::class, 'monitor']);

    Route::apiResource('savings-goals', SavingsGoalController::class)->except(['show']  );
    Route::post('/savings-goals/{savingsGoal}/progress', [SavingsGoalController::class, 'addProgress']);

    Route::get('/dashboard/summary', [DashboardController::class, 'summary']);

    Route::get('/reports/financial', [ReportController::class, 'financial']);
    Route::get('/reports/income', [ReportController::class, 'income']);
    Route::get('/reports/expense', [ReportController::class, 'expense']);
    Route::get('/reports/budget', [ReportController::class, 'budget']);
    Route::get('/reports/chart-data', [ReportController::class, 'chartData']);
    Route::get('/reports/export/pdf', [ReportController::class, 'exportPdf']);
});
