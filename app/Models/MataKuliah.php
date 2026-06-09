<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class MataKuliah extends Model
{
    protected $fillable = [
        'kode_mk',
        'nama_mk',
        'sks',
        'prodi_id',
    ];

    public function programStudi(): BelongsTo
    {
        return $this->belongsTo(ProgramStudi::class, 'prodi_id');
    }

    public function kelas(): HasMany
    {
        return $this->hasMany(Kelas::class, 'mk_id');
    }
}
