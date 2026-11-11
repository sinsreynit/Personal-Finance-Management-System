<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('categories', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->nullable()->constrained()->cascadeOnDelete();
            // user_id null = system/default category available to everyone
            $table->string('name');
            $table->enum('type', ['income', 'expense']);
            $table->string('icon')->nullable();
            $table->string('color', 7)->default('#6C5CE7');
            $table->timestamps();

            $table->unique(['user_id', 'name', 'type']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('categories');
    }
};
