<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class ProgramStudi extends Model
{
    protected $fillable = [
        'nama_prodi',
    ];

    public function mahasiswas(): HasMany
    {
        return $this->hasMany(Mahasiswa::class, 'prodi_id');
    }

    public function dosens(): HasMany
    {
        return $this->hasMany(Dosen::class, 'prodi_id');
    }

    public function mataKuliahs(): HasMany
    {
        return $this->hasMany(MataKuliah::class, 'prodi_id');
    }
}
