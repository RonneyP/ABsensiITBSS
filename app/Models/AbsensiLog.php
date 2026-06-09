<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AbsensiLog extends Model
{
    protected $table = 'absensi_logs';

    protected $fillable = [
        'absensi_id',
        'actor_id',
        'action',
        'meta',
    ];

    protected function casts(): array
    {
        return [
            'meta' => 'array',
        ];
    }

    public function absensi(): BelongsTo
    {
        return $this->belongsTo(Absensi::class, 'absensi_id');
    }

    public function actor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'actor_id');
    }
}
