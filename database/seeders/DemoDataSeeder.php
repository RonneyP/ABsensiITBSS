<?php

namespace Database\Seeders;

use App\Models\Kelas;
use App\Models\KelasMahasiswa;
use App\Models\MataKuliah;
use App\Models\ProgramStudi;
use App\Models\Schedule;
use App\Models\SesiAbsensi;
use App\Models\User;
use App\Services\QrCodeService;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DemoDataSeeder extends Seeder
{
    public function run(): void
    {
        $prodi = ProgramStudi::firstOrCreate(['nama_prodi' => 'Teknik Informatika']);

        User::updateOrCreate(
            ['email' => 'admin@kampus.test'],
            [
                'nama' => 'Admin Kampus',
                'username' => 'admin_kampus',
                'password' => Hash::make('password123'),
                'role' => 'admin',
            ]
        );

        $dosenUser = User::updateOrCreate(
            ['email' => 'dosen@kampus.test'],
            [
                'nama' => 'Dosen Satu',
                'username' => 'dosen_satu',
                'password' => Hash::make('password123'),
                'role' => 'dosen',
            ]
        );

        $mahasiswaUser = User::updateOrCreate(
            ['email' => 'mahasiswa@kampus.test'],
            [
                'nama' => 'Mahasiswa Satu',
                'username' => 'mhs_satu',
                'password' => Hash::make('password123'),
                'role' => 'mahasiswa',
            ]
        );

        $dosenProfile = $dosenUser->dosen;
        if ($dosenProfile) {
            $dosenProfile->update([
                'nidn' => '0123456789',
                'prodi_id' => $prodi->id,
            ]);
        }

        $mahasiswaProfile = $mahasiswaUser->mahasiswa;
        if ($mahasiswaProfile) {
            $mahasiswaProfile->update([
                'nim' => '2021001',
                'angkatan' => 2021,
                'prodi_id' => $prodi->id,
            ]);
        }

        $mk = MataKuliah::updateOrCreate(
            ['kode_mk' => 'IF401'],
            [
                'nama_mk' => 'Pemrograman Aplikasi Lanjut',
                'sks' => 4,
                'prodi_id' => $prodi->id,
            ]
        );

        $dosenPk = $dosenUser->dosen?->id;
        if (! $dosenPk) {
            $this->command?->error('Profil dosen gagal dibuat.');

            return;
        }

        $kelas = Kelas::updateOrCreate(
            ['mk_id' => $mk->id, 'kode_kelas' => 'IF401-A'],
            [
                'dosen_id' => $dosenPk,
                'nama_kelas' => 'Pemrograman Aplikasi Lanjut - Kelas A',
                'hari' => 3,
                'jam_mulai' => '09:00:00',
                'jam_selesai' => '10:40:00',
            ]
        );

        if ($mahasiswaProfile) {
            KelasMahasiswa::updateOrCreate([
                'kelas_id' => $kelas->id,
                'mahasiswa_id' => $mahasiswaProfile->id,
            ]);
        }

        $schedule = Schedule::updateOrCreate(
            [
                'kelas_id' => $kelas->id,
                'lecturer_id' => $dosenUser->id,
                'day_of_week' => 3,
            ],
            [
                'start_time' => '09:00',
                'end_time' => '10:40',
            ]
        );

        $tanggal = now()->toDateString();
        $session = SesiAbsensi::updateOrCreate(
            [
                'kelas_id' => $kelas->id,
                'dosen_id' => $dosenPk,
                'session_date' => $tanggal,
            ],
            [
                'schedule_id' => $schedule->id,
                'tanggal' => $tanggal,
                'pertemuan_ke' => 1,
                'start_at' => now()->subMinutes(10),
                'end_at' => now()->addMinutes(50),
                'lat_kelas' => -6.20000000,
                'long_kelas' => 106.81666600,
                'radius_kelas' => 80,
                'status' => 'open',
                'status_sa' => 'aktif',
            ]
        );

        app(QrCodeService::class)->generateDynamicCode($session, 600);

        $this->command?->info('Demo data siap dipakai.');
        $this->command?->info('Admin     : admin@kampus.test / password123');
        $this->command?->info('Dosen     : dosen@kampus.test / password123');
        $this->command?->info('Mahasiswa : mahasiswa@kampus.test / password123');
    }
}
