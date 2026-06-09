<?php

namespace App\Http\Controllers;

use App\Models\Absensi;
use App\Models\Dosen;
use App\Models\Kelas;
use App\Models\KelasMahasiswa;
use App\Models\MataKuliah;
use App\Models\ProgramStudi;
use App\Models\Schedule;
use App\Models\SesiAbsensi;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class AdminController extends Controller
{
    public function createUser(Request $request)
    {
        $payload = $request->validate([
            'nama' => ['required', 'string', 'max:255'],
            'username' => ['required', 'string', 'max:50', 'alpha_dash', 'unique:users,username'],
            'email' => ['required', 'email', 'unique:users,email'],
            'password' => ['required', 'string', 'min:8'],
            'role' => ['required', Rule::in(['admin', 'dosen', 'mahasiswa'])],
        ]);

        return response()->json(User::create($payload), 201);
    }

    public function createProgramStudi(Request $request)
    {
        $payload = $request->validate([
            'nama_prodi' => ['required', 'string', 'max:255'],
        ]);

        return response()->json(ProgramStudi::create($payload), 201);
    }

    public function createMataKuliah(Request $request)
    {
        $payload = $request->validate([
            'kode_mk' => ['required', 'string', 'max:20', 'unique:mata_kuliahs,kode_mk'],
            'nama_mk' => ['required', 'string', 'max:255'],
            'sks' => ['required', 'integer', 'min:1', 'max:24'],
            'prodi_id' => ['required', 'exists:program_studis,id'],
        ]);

        return response()->json(MataKuliah::create($payload), 201);
    }

    public function createKelas(Request $request)
    {
        $payload = $request->validate([
            'mk_id' => ['required', 'exists:mata_kuliahs,id'],
            'dosen_id' => ['required', 'exists:users,id'],
            'kode_kelas' => ['required', 'string', 'max:50'],
            'nama_kelas' => ['required', 'string', 'max:150'],
            'hari' => ['required', 'integer', 'between:1,7'],
            'jam_mulai' => ['required', 'date_format:H:i'],
            'jam_selesai' => ['required', 'date_format:H:i', 'after:jam_mulai'],
        ]);

        $userDosen = User::findOrFail($payload['dosen_id']);
        if ($userDosen->role !== 'dosen') {
            return response()->json(['message' => 'User bukan dosen.'], 422);
        }

        $dosen = $userDosen->dosen;
        if (! $dosen instanceof Dosen) {
            return response()->json(['message' => 'Profil dosen tidak ditemukan.'], 422);
        }

        $data = [
            'mk_id' => $payload['mk_id'],
            'dosen_id' => $dosen->id,
            'kode_kelas' => $payload['kode_kelas'],
            'nama_kelas' => $payload['nama_kelas'],
            'hari' => $payload['hari'],
            'jam_mulai' => $payload['jam_mulai'],
            'jam_selesai' => $payload['jam_selesai'],
        ];

        // Check for schedule conflicts with existing classes
        $existingSchedule = Schedule::where('lecturer_id', $userDosen->id)
            ->where('day_of_week', $payload['hari'])
            ->where(function($query) use ($payload) {
                $query->where('start_time', '<', $payload['jam_selesai'])
                      ->where('end_time', '>', $payload['jam_mulai']);
            })
            ->first();

        if ($existingSchedule) {
            $conflictingClass = Kelas::find($existingSchedule->kelas_id);
            return response()->json([
                'message' => 'Jadwal bentrok dengan kelas yang sudah ada',
                'conflict' => [
                    'existing_kelas' => [
                        'kode_kelas' => $conflictingClass->kode_kelas,
                        'nama_kelas' => $conflictingClass->nama_kelas,
                        'hari' => $existingSchedule->day_of_week,
                        'jam_mulai' => $existingSchedule->start_time,
                        'jam_selesai' => $existingSchedule->end_time
                    ],
                    'requested_time' => [
                        'hari' => $payload['hari'],
                        'jam_mulai' => $payload['jam_mulai'],
                        'jam_selesai' => $payload['jam_selesai']
                    ]
                ]
            ], 422);
        }

        $kelas = Kelas::create($data);

        // Create 1 weekly schedule pattern for this class
        $schedule = Schedule::create([
            'kelas_id' => $kelas->id,
            'lecturer_id' => $userDosen->id,
            'day_of_week' => $payload['hari'],
            'start_time' => $payload['jam_mulai'],
            'end_time' => $payload['jam_selesai'],
        ]);

        return response()->json([
            'kelas' => $kelas,
            'schedule' => $schedule,
            'total_pertemuan' => 16,
            'pattern' => 'weekly',
            'message' => 'Kelas berhasil dibuat dengan jadwal mingguan (16 pertemuan per semester)'
        ], 201);
    }

    public function enrollMahasiswa(Request $request)
    {
        $payload = $request->validate([
            'kelas_id' => ['required', 'exists:kelas,id'],
            'student_id' => ['required', 'exists:users,id'],
        ]);

        $student = User::findOrFail($payload['student_id']);
        if ($student->role !== 'mahasiswa') {
            return response()->json(['message' => 'User bukan mahasiswa.'], 422);
        }

        $mahasiswa = $student->mahasiswa;
        if (! $mahasiswa) {
            return response()->json(['message' => 'Profil mahasiswa tidak ditemukan.'], 422);
        }

        $enrollment = KelasMahasiswa::firstOrCreate([
            'kelas_id' => $payload['kelas_id'],
            'mahasiswa_id' => $mahasiswa->id,
        ]);

        return response()->json($enrollment, 201);
    }

    public function createSchedule(Request $request)
    {
        $payload = $request->validate([
            'kelas_id' => ['required', 'exists:kelas,id'],
            'lecturer_id' => ['required', 'exists:users,id'],
            'day_of_week' => ['required', 'integer', 'between:1,7'],
            'start_time' => ['required', 'date_format:H:i'],
            'end_time' => ['required', 'date_format:H:i', 'after:start_time'],
        ]);

        $kelas = Kelas::findOrFail($payload['kelas_id']);
        $dosen = User::findOrFail($payload['lecturer_id'])->dosen;
        if (! $dosen instanceof Dosen || (int) $kelas->dosen_id !== (int) $dosen->id) {
            return response()->json(['message' => 'Dosen tidak mengajar kelas ini.'], 422);
        }

        return response()->json(Schedule::create($payload), 201);
    }

    public function sessions()
    {
        return response()->json(
            SesiAbsensi::with(['kelas.mataKuliah', 'dosen.user'])->latest()->get()
        );
    }

    public function attendanceRecords()
    {
        return response()->json(
            Absensi::with(['sesi.kelas', 'mahasiswa.user', 'overrider'])->latest()->get()
        );
    }
}
