<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class SesiAbsensi extends Model
{
    protected $table = 'sesi_absensis';

    protected $fillable = [
        'kelas_id',
        'dosen_id',
        'admin_id',
        'schedule_id',
        'tanggal',
        'pertemuan_ke',
        'qr_token',
        'qr_nonce',
        'qr_expires_at',
        'lat_kelas',
        'long_kelas',
        'radius_kelas',
        'status_sa',
        'start_at',
        'end_at',
        'closed_at',
        'status',
    ];

    protected function casts(): array
    {
        return [
            'tanggal' => 'date',
            'start_at' => 'datetime',
            'end_at' => 'datetime',
            'closed_at' => 'datetime',
            'qr_expires_at' => 'datetime',
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

    public function admin(): BelongsTo
    {
        return $this->belongsTo(User::class, 'admin_id');
    }

    public function schedule(): BelongsTo
    {
        return $this->belongsTo(Schedule::class, 'schedule_id');
    }

    public function absensis(): HasMany
    {
        return $this->hasMany(Absensi::class, 'sesi_absensi_id');
    }
}
