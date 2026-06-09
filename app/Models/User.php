<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasManyThrough;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, Notifiable;

    /**
     * The attributes that are mass assignable.
     *
     * @var list<string>
     */
    protected $fillable = [
        'nama',
        'username',
        'email',
        'role',
        'password',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var list<string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
        ];
    }

    protected static function booted(): void
    {
        static::created(function (User $user) {
            match ($user->role) {
                'mahasiswa' => Mahasiswa::firstOrCreate(['user_id' => $user->id]),
                'dosen' => Dosen::firstOrCreate(['user_id' => $user->id]),
                'admin' => Admin::firstOrCreate(['user_id' => $user->id]),
                default => null,
            };
        });
    }

    public function mahasiswa(): HasOne
    {
        return $this->hasOne(Mahasiswa::class);
    }

    public function dosen(): HasOne
    {
        return $this->hasOne(Dosen::class);
    }

    public function adminProfile(): HasOne
    {
        return $this->hasOne(Admin::class);
    }

    public function sesiAbsensiDimulai(): HasManyThrough
    {
        return $this->hasManyThrough(
            SesiAbsensi::class,
            Dosen::class,
            'user_id',
            'dosen_id',
            'id',
            'id'
        );
    }
}
