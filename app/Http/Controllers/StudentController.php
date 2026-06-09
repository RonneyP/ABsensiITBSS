<?php

namespace App\Http\Controllers;

use App\Models\Absensi;
use App\Models\AbsensiLog;
use App\Models\KelasMahasiswa;
use App\Models\SesiAbsensi;
use App\Services\GeoDistanceService;
use App\Services\QrCodeService;
use Illuminate\Http\Request;

class StudentController extends Controller
{
    public function classes(Request $request)
    {
        $mahasiswa = $request->user()->mahasiswa;
        if (! $mahasiswa) {
            return response()->json([]);
        }

        return response()->json(
            $mahasiswa->kelas()->with('mataKuliah')->get()
        );
    }

    public function history(Request $request)
    {
        $mahasiswa = $request->user()->mahasiswa;
        if (! $mahasiswa) {
            return response()->json([]);
        }

        return response()->json(
            Absensi::with(['sesi.kelas.mataKuliah'])
                ->where('mahasiswa_id', $mahasiswa->id)
                ->latest()
                ->get()
        );
    }

    public function checkin(
        Request $request,
        QrCodeService $qrService,
        GeoDistanceService $geoDistanceService
    ) {
        $payload = $request->validate([
            'qr_token' => ['required', 'string'],
            'latitude' => ['required', 'numeric', 'between:-90,90'],
            'longitude' => ['required', 'numeric', 'between:-180,180'],
            'accuracy' => ['nullable', 'numeric', 'min:0', 'max:2000'],
        ]);

        if (($payload['accuracy'] ?? 0) > 100) {
            return response()->json(['message' => 'Akurasi GPS terlalu rendah.'], 422);
        }

        $parsed = $qrService->validateToken($payload['qr_token']);
        if ($parsed['exp'] < now()->timestamp) {
            return response()->json(['message' => 'QR token sudah expired.'], 422);
        }

        $session = SesiAbsensi::query()->find($parsed['session_id']);
        if (! $session) {
            return response()->json(['message' => 'Sesi absensi tidak valid.'], 404);
        }

        $aktif = ($session->status_sa === 'aktif') || ($session->status === 'open');
        if (! $aktif) {
            return response()->json(['message' => 'Sesi absensi tidak valid.'], 404);
        }

        if ($session->qr_nonce !== $parsed['nonce']) {
            return response()->json(['message' => 'QR token tidak cocok.'], 422);
        }

        $expiresAt = $session->expired_time ?? $session->qr_expires_at;
        if ($expiresAt && $expiresAt->isPast()) {
            return response()->json(['message' => 'QR token sudah expired.'], 422);
        }

        $mahasiswa = $request->user()->mahasiswa;
        if (! $mahasiswa) {
            return response()->json(['message' => 'Profil mahasiswa tidak ditemukan.'], 403);
        }

        $isEnrolled = KelasMahasiswa::where('kelas_id', $session->kelas_id)
            ->where('mahasiswa_id', $mahasiswa->id)
            ->exists();
        if (! $isEnrolled) {
            return response()->json(['message' => 'Anda tidak terdaftar di kelas ini.'], 403);
        }

        if (
            Absensi::where('sesi_absensi_id', $session->id)
                ->where('mahasiswa_id', $mahasiswa->id)
                ->exists()
        ) {
            return response()->json(['message' => 'Anda sudah presensi pada sesi ini.'], 409);
        }

        $latKelas = $session->lat_kelas;
        $longKelas = $session->long_kelas;
        $radius = (int) ($session->radius_kelas ?? 30);

        if ($latKelas === null || $longKelas === null) {
            return response()->json(['message' => 'Lokasi titik absensi belum diatur dosen.'], 422);
        }

        $distance = $geoDistanceService->distanceInMeters(
            (float) $latKelas,
            (float) $longKelas,
            (float) $payload['latitude'],
            (float) $payload['longitude']
        );

        if ($distance > $radius) {
            return response()->json([
                'message' => 'Di luar radius GPS yang diizinkan.',
                'jarak_meter' => $distance,
                'radius_kelas' => $radius,
            ], 403);
        }

        $now = now();
        $attendance = Absensi::create([
            'sesi_absensi_id' => $session->id,
            'mahasiswa_id' => $mahasiswa->id,
            'status_absensi' => 'hadir',
            'waktu_scan' => $now,
            'lat_mahasiswa' => $payload['latitude'],
            'long_mahasiswa' => $payload['longitude'],
            'jarak_meter' => $distance,
            'source' => 'qr',
        ]);

        AbsensiLog::create([
            'absensi_id' => $attendance->id,
            'actor_id' => $request->user()->id,
            'action' => 'checkin',
            'meta' => [
                'jarak_meter' => $distance,
                'accuracy' => $payload['accuracy'] ?? null,
                'ip' => $request->ip(),
            ],
        ]);

        return response()->json([
            'message' => 'Presensi berhasil.',
            'attendance' => $attendance,
        ], 201);
    }
}
