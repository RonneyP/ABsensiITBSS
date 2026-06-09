<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Kelas extends Model
{
    protected $table = 'kelas';

    protected $fillable = [
        'mk_id',
        'dosen_id',
        'kode_kelas',
        'nama_kelas',
        'hari',
        'jam_mulai',
        'jam_selesai',
    ];

    public function mataKuliah(): BelongsTo
    {
        return $this->belongsTo(MataKuliah::class, 'mk_id');
    }

    public function dosen(): BelongsTo
    {
        return $this->belongsTo(Dosen::class, 'dosen_id');
    }

    public function schedules(): HasMany
    {
        return $this->hasMany(Jadwal::class, 'kelas_id');
    }

    public function sesiAbsensis(): HasMany
    {
        return $this->hasMany(SesiAbsensi::class, 'kelas_id');
    }

    public function mahasiswas(): BelongsToMany
    {
        return $this->belongsToMany(Mahasiswa::class, 'kelas_mahasiswa', 'kelas_id', 'mahasiswa_id')
            ->withTimestamps();
    }

    public function kelasMahasiswa(): HasMany
    {
        return $this->hasMany(KelasMahasiswa::class, 'kelas_id');
    }
}
