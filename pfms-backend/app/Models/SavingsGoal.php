<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SavingsGoal extends Model
{
    protected $fillable = ['user_id', 'name', 'target_amount', 'current_amount', 'target_date'];

    protected $casts = [
        'target_date' => 'date',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function progressPercent(): float
    {
        if ($this->target_amount <= 0) {
            return 0;
        }

        return round(min(100, ($this->current_amount / $this->target_amount) * 100), 1);
    }
}