<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::disableForeignKeyConstraints();

        Schema::dropIfExists('detail_sesi_absensis');
        Schema::dropIfExists('sesi_absensis');

        if (! Schema::hasTable('program_studis')) {
            Schema::create('program_studis', function (Blueprint $table) {
                $table->id();
                $table->string('nama_prodi');
                $table->timestamps();
            });
        }

        if (! Schema::hasTable('mahasiswas')) {
            Schema::create('mahasiswas', function (Blueprint $table) {
                $table->id();
                $table->foreignId('user_id')->unique()->constrained()->cascadeOnDelete();
                $table->foreignId('prodi_id')->nullable()->constrained('program_studis')->nullOnDelete();
                $table->string('nim')->nullable();
                $table->timestamps();
            });
        }

        if (! Schema::hasTable('dosens')) {
            Schema::create('dosens', function (Blueprint $table) {
                $table->id();
                $table->foreignId('user_id')->unique()->constrained()->cascadeOnDelete();
                $table->string('nip')->nullable();
                $table->timestamps();
            });
        }

        if (! Schema::hasTable('admins')) {
            Schema::create('admins', function (Blueprint $table) {
                $table->id();
                $table->foreignId('user_id')->unique()->constrained()->cascadeOnDelete();
                $table->timestamps();
            });
        }

        if (! Schema::hasColumn('mata_kuliahs', 'prodi_id') && ! Schema::hasColumn('mata_kuliahs', 'program_studi_id')) {
            Schema::table('mata_kuliahs', function (Blueprint $table) {
                $table->foreignId('prodi_id')->nullable()->after('nama_mk')->constrained('program_studis')->nullOnDelete();
            });
        }

        if (Schema::hasTable('classrooms') && ! Schema::hasColumn('classrooms', 'dosen_id')) {
            Schema::table('classrooms', function (Blueprint $table) {
                $table->foreignId('dosen_id')->nullable()->after('mata_kuliah_id')->constrained('users')->nullOnDelete();
            });
        }

        if (Schema::hasTable('teaching_assignments')) {
            $seen = [];
            foreach (DB::table('teaching_assignments')->orderBy('id')->get() as $ta) {
                if (isset($seen[$ta->classroom_id])) {
                    continue;
                }
                $seen[$ta->classroom_id] = true;
                DB::table('classrooms')
                    ->where('id', $ta->classroom_id)
                    ->whereNull('dosen_id')
                    ->update(['dosen_id' => $ta->lecturer_id]);
            }
            Schema::dropIfExists('teaching_assignments');
        }

        $now = now();
        foreach (DB::table('users')->where('role', 'mahasiswa')->cursor() as $u) {
            if (! DB::table('mahasiswas')->where('user_id', $u->id)->exists()) {
                DB::table('mahasiswas')->insert([
                    'user_id' => $u->id,
                    'prodi_id' => null,
                    'nim' => null,
                    'created_at' => $now,
                    'updated_at' => $now,
                ]);
            }
        }
        foreach (DB::table('users')->where('role', 'dosen')->cursor() as $u) {
            if (! DB::table('dosens')->where('user_id', $u->id)->exists()) {
                DB::table('dosens')->insert([
                    'user_id' => $u->id,
                    'nip' => null,
                    'created_at' => $now,
                    'updated_at' => $now,
                ]);
            }
        }
        foreach (DB::table('users')->where('role', 'admin')->cursor() as $u) {
            if (! DB::table('admins')->where('user_id', $u->id)->exists()) {
                DB::table('admins')->insert([
                    'user_id' => $u->id,
                    'created_at' => $now,
                    'updated_at' => $now,
                ]);
            }
        }

        if (Schema::hasTable('enrollments') && Schema::hasColumn('enrollments', 'student_id')) {
            if (! Schema::hasColumn('enrollments', 'mahasiswa_id')) {
                Schema::table('enrollments', function (Blueprint $table) {
                    $table->unsignedBigInteger('mahasiswa_id')->nullable()->after('classroom_id');
                });
            }

            foreach (DB::table('enrollments')->cursor() as $row) {
                $mid = DB::table('mahasiswas')->where('user_id', $row->student_id)->value('id');
                DB::table('enrollments')->where('id', $row->id)->update(['mahasiswa_id' => $mid]);
            }

            Schema::table('enrollments', function (Blueprint $table) {
                $table->dropForeign(['student_id']);
                $table->dropUnique(['classroom_id', 'student_id']);
                $table->dropColumn('student_id');
            });

            Schema::table('enrollments', function (Blueprint $table) {
                $table->foreign('mahasiswa_id')->references('id')->on('mahasiswas')->cascadeOnDelete();
                $table->unique(['classroom_id', 'mahasiswa_id']);
            });
        }

        if (Schema::hasTable('enrollments') && Schema::hasColumn('enrollments', 'classroom_id')) {
            Schema::table('enrollments', function (Blueprint $table) {
                $table->renameColumn('classroom_id', 'kelas_id');
            });
        }

        if (Schema::hasTable('schedules') && Schema::hasColumn('schedules', 'classroom_id')) {
            Schema::table('schedules', function (Blueprint $table) {
                $table->renameColumn('classroom_id', 'kelas_id');
            });
        }

        if (Schema::hasTable('attendance_sessions')) {
            if (! Schema::hasColumn('attendance_sessions', 'admin_id')) {
                Schema::table('attendance_sessions', function (Blueprint $table) {
                    $table->foreignId('admin_id')->nullable()->after('lecturer_id')->constrained('users')->nullOnDelete();
                });
            }
            Schema::table('attendance_sessions', function (Blueprint $table) {
                $table->renameColumn('classroom_id', 'kelas_id');
                $table->renameColumn('lecturer_id', 'dosen_id');
            });
        }

        if (Schema::hasTable('classrooms')) {
            Schema::rename('classrooms', 'kelas');
        }

        if (Schema::hasTable('enrollments')) {
            Schema::rename('enrollments', 'kelas_mahasiswa');
        }

        if (Schema::hasTable('attendance_sessions')) {
            Schema::rename('attendance_sessions', 'sesi_absensis');
        }

        if (Schema::hasTable('attendances')) {
            if (! Schema::hasColumn('attendances', 'mahasiswa_id')) {
                Schema::table('attendances', function (Blueprint $table) {
                    $table->unsignedBigInteger('mahasiswa_id')->nullable()->after('attendance_session_id');
                });
            }

            foreach (DB::table('attendances')->cursor() as $row) {
                $mid = DB::table('mahasiswas')->where('user_id', $row->student_id)->value('id');
                DB::table('attendances')->where('id', $row->id)->update(['mahasiswa_id' => $mid]);
            }

            Schema::table('attendances', function (Blueprint $table) {
                $table->dropForeign(['student_id']);
                $table->dropUnique(['attendance_session_id', 'student_id']);
                $table->dropColumn('student_id');
            });

            Schema::table('attendances', function (Blueprint $table) {
                $table->foreign('mahasiswa_id')->references('id')->on('mahasiswas')->cascadeOnDelete();
                $table->unique(['attendance_session_id', 'mahasiswa_id']);
            });

            Schema::table('attendances', function (Blueprint $table) {
                $table->renameColumn('attendance_session_id', 'sesi_absensi_id');
            });

            if (Schema::hasTable('attendance_logs')) {
                Schema::table('attendance_logs', function (Blueprint $table) {
                    $table->dropForeign(['attendance_id']);
                });
            }

            Schema::rename('attendances', 'absensis');
        }

        if (Schema::hasTable('attendance_logs')) {
            Schema::table('attendance_logs', function (Blueprint $table) {
                $table->renameColumn('attendance_id', 'absensi_id');
            });
            Schema::rename('attendance_logs', 'absensi_logs');
            Schema::table('absensi_logs', function (Blueprint $table) {
                $table->foreign('absensi_id')->references('id')->on('absensis')->cascadeOnDelete();
            });
        }

        Schema::enableForeignKeyConstraints();
    }

    public function down(): void
    {
        Schema::disableForeignKeyConstraints();

        if (Schema::hasTable('absensi_logs')) {
            Schema::rename('absensi_logs', 'attendance_logs');
            Schema::table('attendance_logs', function (Blueprint $table) {
                $table->renameColumn('absensi_id', 'attendance_id');
            });
        }

        if (Schema::hasTable('absensis')) {
            Schema::table('absensis', function (Blueprint $table) {
                $table->renameColumn('sesi_absensi_id', 'attendance_session_id');
            });
            Schema::rename('absensis', 'attendances');

            Schema::table('attendances', function (Blueprint $table) {
                $table->dropForeign(['mahasiswa_id']);
                $table->dropUnique(['attendance_session_id', 'mahasiswa_id']);
            });

            Schema::table('attendances', function (Blueprint $table) {
                $table->foreignId('student_id')->nullable()->after('attendance_session_id')->constrained('users')->cascadeOnDelete();
            });

            foreach (DB::table('attendances')->cursor() as $row) {
                $uid = DB::table('mahasiswas')->where('id', $row->mahasiswa_id)->value('user_id');
                DB::table('attendances')->where('id', $row->id)->update(['student_id' => $uid]);
            }

            Schema::table('attendances', function (Blueprint $table) {
                $table->dropForeign(['mahasiswa_id']);
                $table->dropColumn('mahasiswa_id');
                $table->unique(['attendance_session_id', 'student_id']);
            });
        }

        if (Schema::hasTable('sesi_absensis')) {
            Schema::rename('sesi_absensis', 'attendance_sessions');
            Schema::table('attendance_sessions', function (Blueprint $table) {
                $table->renameColumn('kelas_id', 'classroom_id');
                $table->renameColumn('dosen_id', 'lecturer_id');
            });
            if (Schema::hasColumn('attendance_sessions', 'admin_id')) {
                Schema::table('attendance_sessions', function (Blueprint $table) {
                    $table->dropForeign(['admin_id']);
                    $table->dropColumn('admin_id');
                });
            }
        }

        if (Schema::hasTable('schedules') && Schema::hasColumn('schedules', 'kelas_id')) {
            Schema::table('schedules', function (Blueprint $table) {
                $table->renameColumn('kelas_id', 'classroom_id');
            });
        }

        if (Schema::hasTable('kelas_mahasiswa')) {
            Schema::rename('kelas_mahasiswa', 'enrollments');
            Schema::table('enrollments', function (Blueprint $table) {
                $table->renameColumn('kelas_id', 'classroom_id');
            });

            Schema::table('enrollments', function (Blueprint $table) {
                $table->dropForeign(['mahasiswa_id']);
                $table->dropUnique(['classroom_id', 'mahasiswa_id']);
            });

            Schema::table('enrollments', function (Blueprint $table) {
                $table->foreignId('student_id')->nullable()->after('classroom_id')->constrained('users')->cascadeOnDelete();
            });

            foreach (DB::table('enrollments')->cursor() as $row) {
                $uid = DB::table('mahasiswas')->where('id', $row->mahasiswa_id)->value('user_id');
                DB::table('enrollments')->where('id', $row->id)->update(['student_id' => $uid]);
            }

            Schema::table('enrollments', function (Blueprint $table) {
                $table->dropForeign(['mahasiswa_id']);
                $table->dropColumn('mahasiswa_id');
                $table->unique(['classroom_id', 'student_id']);
            });
        }

        if (Schema::hasTable('kelas')) {
            Schema::rename('kelas', 'classrooms');
        }

        if (Schema::hasTable('classrooms') && Schema::hasColumn('classrooms', 'dosen_id')) {
            Schema::table('classrooms', function (Blueprint $table) {
                $table->dropForeign(['dosen_id']);
                $table->dropColumn('dosen_id');
            });
        }

        if (! Schema::hasTable('teaching_assignments') && Schema::hasTable('classrooms')) {
            Schema::create('teaching_assignments', function (Blueprint $table) {
                $table->id();
                $table->foreignId('classroom_id')->constrained('classrooms')->cascadeOnDelete();
                $table->foreignId('lecturer_id')->constrained('users')->cascadeOnDelete();
                $table->timestamps();
                $table->unique(['classroom_id', 'lecturer_id']);
            });
        }

        if (Schema::hasColumn('mata_kuliahs', 'prodi_id')) {
            Schema::table('mata_kuliahs', function (Blueprint $table) {
                $table->dropForeign(['prodi_id']);
                $table->dropColumn('prodi_id');
            });
        }

        if (Schema::hasColumn('mata_kuliahs', 'program_studi_id')) {
            Schema::table('mata_kuliahs', function (Blueprint $table) {
                $table->dropForeign(['program_studi_id']);
                $table->dropColumn('program_studi_id');
            });
        }

        Schema::dropIfExists('admins');
        Schema::dropIfExists('dosens');
        Schema::dropIfExists('mahasiswas');
        Schema::dropIfExists('program_studis');

        Schema::enableForeignKeyConstraints();
    }
};
