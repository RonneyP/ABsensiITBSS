<?php

use Carbon\Carbon;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('sesi_absensis')) {
            if (! Schema::hasColumn('sesi_absensis', 'tanggal')) {
                Schema::table('sesi_absensis', function (Blueprint $table) {
                    $table->date('tanggal')->nullable()->after('kelas_id');
                });
            }

            if (Schema::hasColumn('sesi_absensis', 'session_date')) {
                foreach (DB::table('sesi_absensis')->whereNull('tanggal')->cursor() as $row) {
                    if ($row->session_date) {
                        DB::table('sesi_absensis')->where('id', $row->id)->update([
                            'tanggal' => Carbon::parse($row->session_date)->toDateString(),
                        ]);
                    }
                }
            }

            if (! Schema::hasColumn('sesi_absensis', 'pertemuan_ke')) {
                Schema::table('sesi_absensis', function (Blueprint $table) {
                    $table->unsignedInteger('pertemuan_ke')->default(1)->after('tanggal');
                });
            }

            if (! Schema::hasColumn('sesi_absensis', 'qr_token')) {
                Schema::table('sesi_absensis', function (Blueprint $table) {
                    $table->text('qr_token')->nullable()->after('pertemuan_ke');
                });
            }

            if (Schema::hasColumn('sesi_absensis', 'qr_nonce') && Schema::hasColumn('sesi_absensis', 'qr_token')) {
                foreach (DB::table('sesi_absensis')->whereNull('qr_token')->cursor() as $row) {
                    if ($row->qr_nonce !== null) {
                        DB::table('sesi_absensis')->where('id', $row->id)->update(['qr_token' => $row->qr_nonce]);
                    }
                }
            }

            if (! Schema::hasColumn('sesi_absensis', 'expired_time')) {
                Schema::table('sesi_absensis', function (Blueprint $table) {
                    $table->dateTime('expired_time')->nullable()->after('qr_token');
                });
            }

            if (Schema::hasColumn('sesi_absensis', 'qr_expires_at')) {
                foreach (DB::table('sesi_absensis')->whereNull('expired_time')->cursor() as $row) {
                    if ($row->qr_expires_at) {
                        DB::table('sesi_absensis')->where('id', $row->id)->update([
                            'expired_time' => $row->qr_expires_at,
                        ]);
                    }
                }
            }

            if (! Schema::hasColumn('sesi_absensis', 'lat_kelas')) {
                Schema::table('sesi_absensis', function (Blueprint $table) {
                    $table->decimal('lat_kelas', 10, 8)->nullable()->after('expired_time');
                    $table->decimal('long_kelas', 11, 8)->nullable()->after('lat_kelas');
                    $table->unsignedInteger('radius_kelas')->default(30)->after('long_kelas');
                });
            }

            if (Schema::hasTable('kelas') && Schema::hasColumn('kelas', 'latitude')) {
                foreach (DB::table('sesi_absensis')->cursor() as $sesi) {
                    $kelas = DB::table('kelas')->where('id', $sesi->kelas_id)->first();
                    if ($kelas && $kelas->latitude !== null && $kelas->longitude !== null) {
                        DB::table('sesi_absensis')->where('id', $sesi->id)->update([
                            'lat_kelas' => $kelas->latitude,
                            'long_kelas' => $kelas->longitude,
                            'radius_kelas' => $kelas->allowed_radius_m ?? 30,
                        ]);
                    }
                }
            }

            if (! Schema::hasColumn('sesi_absensis', 'status_sa')) {
                Schema::table('sesi_absensis', function (Blueprint $table) {
                    $table->enum('status_sa', ['aktif', 'ditutup'])->default('aktif')->after('radius_kelas');
                });
            }

            if (Schema::hasColumn('sesi_absensis', 'status')) {
                DB::table('sesi_absensis')->where('status', 'open')->update(['status_sa' => 'aktif']);
                DB::table('sesi_absensis')->where('status', 'closed')->update(['status_sa' => 'ditutup']);
            }
        }

        if (Schema::hasTable('kelas') && Schema::hasColumn('kelas', 'latitude')) {
            Schema::table('kelas', function (Blueprint $table) {
                $table->dropColumn(['latitude', 'longitude', 'allowed_radius_m']);
            });
        }

        if (Schema::hasTable('absensis')) {
            if (! Schema::hasColumn('absensis', 'waktu_scan')) {
                Schema::table('absensis', function (Blueprint $table) {
                    $table->dateTime('waktu_scan')->nullable()->after('mahasiswa_id');
                });
            }

            if (Schema::hasColumn('absensis', 'checkin_at')) {
                foreach (DB::table('absensis')->whereNull('waktu_scan')->cursor() as $row) {
                    if ($row->checkin_at) {
                        DB::table('absensis')->where('id', $row->id)->update(['waktu_scan' => $row->checkin_at]);
                    }
                }
            }

            if (! Schema::hasColumn('absensis', 'lat_mahasiswa')) {
                Schema::table('absensis', function (Blueprint $table) {
                    $table->decimal('lat_mahasiswa', 10, 8)->nullable()->after('waktu_scan');
                    $table->decimal('long_mahasiswa', 11, 8)->nullable()->after('lat_mahasiswa');
                });
            }

            if (Schema::hasColumn('absensis', 'checkin_latitude')) {
                foreach (DB::table('absensis')->whereNull('lat_mahasiswa')->cursor() as $row) {
                    DB::table('absensis')->where('id', $row->id)->update([
                        'lat_mahasiswa' => $row->checkin_latitude,
                        'long_mahasiswa' => $row->checkin_longitude,
                    ]);
                }
            }

            if (! Schema::hasColumn('absensis', 'jarak_meter')) {
                Schema::table('absensis', function (Blueprint $table) {
                    $table->unsignedInteger('jarak_meter')->nullable()->after('long_mahasiswa');
                });
            }

            if (Schema::hasColumn('absensis', 'distance_m')) {
                foreach (DB::table('absensis')->whereNull('jarak_meter')->cursor() as $row) {
                    if ($row->distance_m !== null) {
                        DB::table('absensis')->where('id', $row->id)->update(['jarak_meter' => $row->distance_m]);
                    }
                }
            }

            if (! Schema::hasColumn('absensis', 'status_absensi')) {
                Schema::table('absensis', function (Blueprint $table) {
                    $table->enum('status_absensi', ['hadir', 'alpha', 'sakit_izin'])->default('hadir')->after('jarak_meter');
                });
            }

            if (Schema::hasColumn('absensis', 'status')) {
                DB::table('absensis')->where('status', 'present')->update(['status_absensi' => 'hadir']);
                DB::table('absensis')->where('status', 'absent')->update(['status_absensi' => 'alpha']);
                DB::table('absensis')->whereIn('status', ['excused', 'late', 'overridden'])->update(['status_absensi' => 'sakit_izin']);
            }
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('kelas') && ! Schema::hasColumn('kelas', 'latitude')) {
            Schema::table('kelas', function (Blueprint $table) {
                $table->decimal('latitude', 10, 8)->nullable();
                $table->decimal('longitude', 11, 8)->nullable();
                $table->unsignedInteger('allowed_radius_m')->default(30);
            });
        }

        if (Schema::hasTable('absensis')) {
            Schema::table('absensis', function (Blueprint $table) {
                $cols = array_filter(
                    ['waktu_scan', 'lat_mahasiswa', 'long_mahasiswa', 'jarak_meter', 'status_absensi'],
                    fn (string $c) => Schema::hasColumn('absensis', $c)
                );
                if ($cols !== []) {
                    $table->dropColumn($cols);
                }
            });
        }

        if (Schema::hasTable('sesi_absensis')) {
            Schema::table('sesi_absensis', function (Blueprint $table) {
                $cols = array_filter(
                    ['tanggal', 'pertemuan_ke', 'qr_token', 'expired_time', 'lat_kelas', 'long_kelas', 'radius_kelas', 'status_sa'],
                    fn (string $c) => Schema::hasColumn('sesi_absensis', $c)
                );
                if ($cols !== []) {
                    $table->dropColumn($cols);
                }
            });
        }
    }
};
