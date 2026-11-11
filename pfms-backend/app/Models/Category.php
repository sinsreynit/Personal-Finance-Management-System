<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Builder;
class Category extends Model
{
    use HasFactory;

    protected $fillable = ['user_id', 'name', 'type', 'icon', 'color'];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function transactions()
    {
        return $this->hasMany(Transaction::class);
    }

    public function scopeVisibleTo(Builder $query, int $userId): Builder
    {
        return $query->where(function (Builder $q) use ($userId) {
        $q->whereNull('user_id')->orWhere('user_id', $userId);
        });
    }
}
