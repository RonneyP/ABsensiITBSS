<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('program_studis')) {
            if (! Schema::hasColumn('program_studis', 'nama_prodi')) {
                Schema::table('program_studis', function (Blueprint $table) {
                    $table->string('nama_prodi')->nullable()->after('id');
                });
            }

            if (Schema::hasColumn('program_studis', 'nama') && Schema::hasColumn('program_studis', 'nama_prodi')) {
                DB::table('program_studis')->whereNull('nama_prodi')->update([
                    'nama_prodi' => DB::raw('nama'),
                ]);
            }

            if (Schema::hasColumn('program_studis', 'kode')) {
                Schema::table('program_studis', function (Blueprint $table) {
                    $table->dropColumn('kode');
                });
            }

            if (Schema::hasColumn('program_studis', 'nama')) {
                Schema::table('program_studis', function (Blueprint $table) {
                    $table->dropColumn('nama');
                });
            }
        }

        if (Schema::hasTable('users')) {
            if (Schema::hasColumn('users', 'name') && ! Schema::hasColumn('users', 'nama')) {
                Schema::table('users', function (Blueprint $table) {
                    $table->renameColumn('name', 'nama');
                });
            }

            if (! Schema::hasColumn('users', 'username')) {
                Schema::table('users', function (Blueprint $table) {
                    $table->string('username')->nullable()->unique()->after('id');
                });

                foreach (DB::table('users')->cursor() as $user) {
                    $base = Str::slug(Str::before($user->email, '@'), '') ?: 'user'.$user->id;
                    $username = $base;
                    $i = 0;
                    while (DB::table('users')->where('username', $username)->where('id', '!=', $user->id)->exists()) {
                        $username = $base.++$i;
                    }
                    DB::table('users')->where('id', $user->id)->update(['username' => $username]);
                }
            }
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('users') && Schema::hasColumn('users', 'username')) {
            Schema::table('users', function (Blueprint $table) {
                $table->dropUnique(['username']);
                $table->dropColumn('username');
            });
        }

        if (Schema::hasTable('users') && Schema::hasColumn('users', 'nama')) {
            Schema::table('users', function (Blueprint $table) {
                $table->renameColumn('nama', 'name');
            });
        }

        if (Schema::hasTable('program_studis') && Schema::hasColumn('program_studis', 'nama_prodi')) {
            Schema::table('program_studis', function (Blueprint $table) {
                $table->string('kode')->nullable()->unique();
                $table->string('nama')->nullable();
            });

            DB::table('program_studis')->update([
                'nama' => DB::raw('nama_prodi'),
                'kode' => DB::raw("'PS' || id"),
            ]);

            Schema::table('program_studis', function (Blueprint $table) {
                $table->dropColumn('nama_prodi');
            });
        }
    }
};
