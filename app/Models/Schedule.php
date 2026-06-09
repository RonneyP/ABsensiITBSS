<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Schedule extends Model
{
    protected $table = 'jadwals';

    protected $fillable = [
        'kelas_id',
        'dosen_id',
        'hari',
        'jam_mulai',
        'jam_selesai',
    ];

    protected function casts(): array
    {
        return [
            'jam_mulai' => 'datetime',
            'jam_selesai' => 'datetime',
        ];
    }

    public function kelas(): BelongsTo
    {
        return $this->belongsTo(Kelas::class, 'kelas_id');
    }

    public function dosen(): BelongsTo
    {
        return $this->belongsTo(Dosen::class, 'dosen_id');
    }

    public function sesiAbsensis(): HasMany
    {
        return $this->hasMany(SesiAbsensi::class, 'schedule_id');
    }
}
