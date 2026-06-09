<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Absensi extends Model
{
    protected $table = 'absensis';

    protected $fillable = [
        'sesi_absensi_id',
        'mahasiswa_id',
        'waktu_scan',
        'lat_mahasiswa',
        'long_mahasiswa',
        'jarak_meter',
        'status_absensi',
        'status',
        'checkin_at',
        'checkin_latitude',
        'checkin_longitude',
        'distance_m',
        'source',
        'overridden_by',
        'override_reason',
    ];

    protected function casts(): array
    {
        return [
            'checkin_at' => 'datetime',
            'waktu_scan' => 'datetime',
        ];
    }

    public function sesi(): BelongsTo
    {
        return $this->belongsTo(SesiAbsensi::class, 'sesi_absensi_id');
    }

    public function mahasiswa(): BelongsTo
    {
        return $this->belongsTo(Mahasiswa::class, 'mahasiswa_id');
    }

    public function overrider(): BelongsTo
    {
        return $this->belongsTo(User::class, 'overridden_by');
    }

    public function logs(): HasMany
    {
        return $this->hasMany(AbsensiLog::class, 'absensi_id');
    }
}
