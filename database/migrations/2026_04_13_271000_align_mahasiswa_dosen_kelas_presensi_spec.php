<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('mahasiswas')) {
            if (Schema::hasColumn('mahasiswas', 'program_studi_id') && ! Schema::hasColumn('mahasiswas', 'prodi_id')) {
                Schema::table('mahasiswas', function (Blueprint $table) {
                    $table->renameColumn('program_studi_id', 'prodi_id');
                });
            }

            if (! Schema::hasColumn('mahasiswas', 'angkatan')) {
                Schema::table('mahasiswas', function (Blueprint $table) {
                    $table->unsignedSmallInteger('angkatan')->nullable()->after('nim');
                });
            }
        }

        if (Schema::hasTable('dosens')) {
            if (Schema::hasColumn('dosens', 'nip') && ! Schema::hasColumn('dosens', 'nidn')) {
                Schema::table('dosens', function (Blueprint $table) {
                    $table->renameColumn('nip', 'nidn');
                });
            }

            if (! Schema::hasColumn('dosens', 'prodi_id')) {
                Schema::table('dosens', function (Blueprint $table) {
                    $table->foreignId('prodi_id')->nullable()->after('user_id')->constrained('program_studis')->nullOnDelete();
                });
            }
        }

        if (Schema::hasTable('kelas')) {
            if (Schema::hasColumn('kelas', 'mata_kuliah_id') && ! Schema::hasColumn('kelas', 'mk_id')) {
                Schema::table('kelas', function (Blueprint $table) {
                    $table->renameColumn('mata_kuliah_id', 'mk_id');
                });
            }

            if (Schema::hasColumn('kelas', 'name') && ! Schema::hasColumn('kelas', 'nama_kelas')) {
                Schema::table('kelas', function (Blueprint $table) {
                    $table->renameColumn('name', 'nama_kelas');
                });
            }

            if (! Schema::hasColumn('kelas', 'hari')) {
                Schema::table('kelas', function (Blueprint $table) {
                    $table->unsignedTinyInteger('hari')->nullable()->comment('1=Senin ... 7=Minggu');
                });
            }

            if (! Schema::hasColumn('kelas', 'jam_mulai')) {
                Schema::table('kelas', function (Blueprint $table) {
                    $table->time('jam_mulai')->nullable();
                    $table->time('jam_selesai')->nullable();
                });
            }

            $this->remapDosenIdFromUserToDosenTable('kelas');

            if (Schema::hasColumn('kelas', 'room_name')) {
                Schema::table('kelas', function (Blueprint $table) {
                    $table->dropColumn('room_name');
                });
            }
        }

        if (Schema::hasTable('sesi_absensis')) {
            $this->remapDosenIdFromUserToDosenTable('sesi_absensis');
        }
    }

    private function remapDosenIdFromUserToDosenTable(string $table): void
    {
        if (! Schema::hasTable($table) || ! Schema::hasColumn($table, 'dosen_id')) {
            return;
        }

        foreach (DB::table($table)->whereNotNull('dosen_id')->cursor() as $row) {
            if (! DB::table('users')->where('id', $row->dosen_id)->exists()) {
                continue;
            }

            $dosenPk = DB::table('dosens')->where('user_id', $row->dosen_id)->value('id');
            if ($dosenPk) {
                DB::table($table)->where('id', $row->id)->update(['dosen_id' => $dosenPk]);
            }
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('kelas') && Schema::hasColumn('kelas', 'mk_id')) {
            Schema::table('kelas', function (Blueprint $table) {
                $table->renameColumn('mk_id', 'mata_kuliah_id');
            });
        }

        if (Schema::hasTable('kelas') && Schema::hasColumn('kelas', 'nama_kelas')) {
            Schema::table('kelas', function (Blueprint $table) {
                $table->renameColumn('nama_kelas', 'name');
            });
        }

        if (Schema::hasTable('dosens') && Schema::hasColumn('dosens', 'prodi_id')) {
            Schema::table('dosens', function (Blueprint $table) {
                $table->dropForeign(['prodi_id']);
                $table->dropColumn('prodi_id');
            });
        }

        if (Schema::hasTable('dosens') && Schema::hasColumn('dosens', 'nidn')) {
            Schema::table('dosens', function (Blueprint $table) {
                $table->renameColumn('nidn', 'nip');
            });
        }

        if (Schema::hasTable('mahasiswas') && Schema::hasColumn('mahasiswas', 'angkatan')) {
            Schema::table('mahasiswas', function (Blueprint $table) {
                $table->dropColumn('angkatan');
            });
        }

        if (Schema::hasTable('mahasiswas') && Schema::hasColumn('mahasiswas', 'prodi_id')) {
            Schema::table('mahasiswas', function (Blueprint $table) {
                $table->renameColumn('prodi_id', 'program_studi_id');
            });
        }
    }
};
