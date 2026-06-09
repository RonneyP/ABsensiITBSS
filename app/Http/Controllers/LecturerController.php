<?php

namespace App\Http\Controllers;

use App\Models\Absensi;
use App\Models\AbsensiLog;
use App\Models\Dosen;
use App\Models\Kelas;
use App\Models\Schedule;
use App\Models\SesiAbsensi;
use App\Services\QrCodeService;
use Illuminate\Http\Request;

class LecturerController extends Controller
{
    public function schedules(Request $request)
    {
        $userId = $request->user()->id;
        
        $dayFilter = $request->query('day');
        
        $baseQuery = Schedule::where('lecturer_id', $userId);
        
        if ($dayFilter && is_numeric($dayFilter) && $dayFilter >= 1 && $dayFilter <= 7) {
            $baseQuery->where('day_of_week', $dayFilter);
        }
        
        $uniquePatterns = $baseQuery->select('kelas_id', 'day_of_week', 'start_time', 'end_time')
            ->distinct()
            ->orderBy('day_of_week')
            ->orderBy('start_time')
            ->get();
        
        // Load relationships for each unique pattern
        $schedules = collect();
        foreach ($uniquePatterns as $pattern) {
            $schedule = Schedule::with(['kelas.mataKuliah'])
                ->where('lecturer_id', $userId)
                ->where('kelas_id', $pattern->kelas_id)
                ->where('day_of_week', $pattern->day_of_week)
                ->where('start_time', $pattern->start_time)
                ->where('end_time', $pattern->end_time)
                ->first();
            
            if ($schedule) {
                $schedules->push($schedule);
            }
        }

        return response()->json([
            'schedules' => $schedules,
            'semester_info' => [
                'total_pertemuan' => 16,
                'pattern' => 'weekly',
                'description' => 'Jadwal mingguan berulang selama 16 pertemuan per semester'
            ]
        ]);
    }

    public function createSession(Request $request, QrCodeService $qrService)
    {
        $dosen = $request->user()->dosen;
        if (! $dosen instanceof Dosen) {
            return response()->json(['message' => 'Profil dosen tidak ditemukan.'], 403);
        }

        $payload = $request->validate([
            'kelas_id' => ['required', 'exists:kelas,id'],
            'schedule_id' => ['nullable', 'exists:schedules,id'],
            'tanggal' => ['nullable', 'date'],
            'pertemuan_ke' => ['nullable', 'integer', 'min:1'],
            'start_at' => ['required', 'date'],
            'end_at' => ['nullable', 'date', 'after:start_at'],
            'lat_kelas' => ['required', 'numeric', 'between:-90,90'],
            'long_kelas' => ['required', 'numeric', 'between:-180,180'],
            'radius_kelas' => ['nullable', 'integer', 'min:5', 'max:500'],
            'qr_valid_seconds' => ['nullable', 'integer', 'min:10', 'max:300'],
        ]);

        $kelasOk = Kelas::where('id', $payload['kelas_id'])
            ->where('dosen_id', $dosen->id)
            ->exists();

        if (! $kelasOk) {
            return response()->json(['message' => 'Anda tidak mengajar kelas ini.'], 403);
        }

        $tanggal = isset($payload['tanggal'])
            ? \Carbon\Carbon::parse($payload['tanggal'])->toDateString()
            : now()->toDateString();

        $session = SesiAbsensi::create([
            'kelas_id' => $payload['kelas_id'],
            'dosen_id' => $dosen->id,
            'schedule_id' => $payload['schedule_id'] ?? null,
            'session_date' => $tanggal,
            'tanggal' => $tanggal,
            'pertemuan_ke' => $payload['pertemuan_ke'] ?? 1,
            'start_at' => $payload['start_at'],
            'end_at' => $payload['end_at'] ?? null,
            'lat_kelas' => $payload['lat_kelas'],
            'long_kelas' => $payload['long_kelas'],
            'radius_kelas' => $payload['radius_kelas'] ?? 30,
            'status' => 'open',
            'status_sa' => 'aktif',
        ]);

        $qr = $qrService->generateDynamicCode($session, $payload['qr_valid_seconds'] ?? 60);

        return response()->json([
            'session' => $session->fresh(),
            'qr_token' => $qr['token'],
            'qr_expires_at' => $qr['expires_at'],
        ], 201);
    }

    public function refreshQr(Request $request, SesiAbsensi $sesi_absensi, QrCodeService $qrService)
    {
        $dosen = $request->user()->dosen;
        if (! $dosen instanceof Dosen || (int) $sesi_absensi->dosen_id !== (int) $dosen->id) {
            return response()->json(['message' => 'Sesi bukan milik Anda.'], 403);
        }

        if ($sesi_absensi->status_sa === 'ditutup' || $sesi_absensi->status === 'closed') {
            return response()->json(['message' => 'Sesi sudah ditutup.'], 422);
        }

        $payload = $request->validate([
            'qr_valid_seconds' => ['nullable', 'integer', 'min:10', 'max:300'],
        ]);

        $qr = $qrService->generateDynamicCode($sesi_absensi, $payload['qr_valid_seconds'] ?? 60);

        return response()->json([
            'qr_token' => $qr['token'],
            'qr_expires_at' => $qr['expires_at'],
        ]);
    }

    public function closeSession(Request $request, SesiAbsensi $sesi_absensi)
    {
        $dosen = $request->user()->dosen;
        if (! $dosen instanceof Dosen || (int) $sesi_absensi->dosen_id !== (int) $dosen->id) {
            return response()->json(['message' => 'Sesi bukan milik Anda.'], 403);
        }

        $sesi_absensi->update([
            'status' => 'closed',
            'status_sa' => 'ditutup',
            'closed_at' => now(),
        ]);

        return response()->json(['message' => 'Sesi absensi ditutup.']);
    }

    public function sessionAttendances(Request $request, SesiAbsensi $sesi_absensi)
    {
        $dosen = $request->user()->dosen;
        if (! $dosen instanceof Dosen || (int) $sesi_absensi->dosen_id !== (int) $dosen->id) {
            return response()->json(['message' => 'Sesi bukan milik Anda.'], 403);
        }

        return response()->json(
            $sesi_absensi->absensis()->with('mahasiswa.user')->latest()->get()
        );
    }

    public function overrideAttendance(Request $request, Absensi $absensi)
    {
        $dosen = $request->user()->dosen;
        $session = $absensi->sesi;
        if (! $dosen instanceof Dosen || (int) $session->dosen_id !== (int) $dosen->id) {
            return response()->json(['message' => 'Sesi bukan milik Anda.'], 403);
        }

        $payload = $request->validate([
            'status' => ['required', 'in:present,late,excused,absent,overridden'],
            'reason' => ['required', 'string', 'min:5', 'max:500'],
        ]);

        $statusAbsensi = match ($payload['status']) {
            'present' => 'hadir',
            'absent' => 'alpha',
            default => 'sakit_izin',
        };

        $absensi->update([
            'status' => $payload['status'],
            'status_absensi' => $statusAbsensi,
            'source' => 'manual_override',
            'overridden_by' => $request->user()->id,
            'override_reason' => $payload['reason'],
        ]);

        AbsensiLog::create([
            'absensi_id' => $absensi->id,
            'actor_id' => $request->user()->id,
            'action' => 'override',
            'meta' => ['status' => $payload['status'], 'reason' => $payload['reason']],
        ]);

        return response()->json(['message' => 'Absensi berhasil dioverride.']);
    }
}
