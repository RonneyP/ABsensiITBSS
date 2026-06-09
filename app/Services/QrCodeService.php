<?php

namespace App\Services;

use App\Models\SesiAbsensi;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Crypt;
use Illuminate\Support\Str;

class QrCodeService
{
    /**
     * Generate token dinamis + simpan nonce & waktu kedaluwarsa pada SesiAbsensi.
     */
    public function generateDynamicCode(SesiAbsensi $session, int $validSeconds = 60): array
    {
        $nonce = Str::random(40);
        $expiresAt = now()->addSeconds($validSeconds);
        $encryptedToken = $this->buildToken($session->id, $nonce, $expiresAt);

        $session->update([
            'qr_nonce' => $nonce,
            'qr_expires_at' => $expiresAt,
            'qr_token' => $encryptedToken,
            'expired_time' => $expiresAt,
        ]);

        return [
            'token' => $encryptedToken,
            'expires_at' => $expiresAt,
        ];
    }

    /**
     * Parse & validasi struktur token (belum memverifikasi ke DB).
     */
    public function validateToken(string $token): array
    {
        return $this->parseToken($token);
    }

    public function buildToken(int $sessionId, string $nonce, Carbon $expiresAt): string
    {
        return Crypt::encryptString(json_encode([
            'sid' => $sessionId,
            'nonce' => $nonce,
            'exp' => $expiresAt->timestamp,
        ], JSON_THROW_ON_ERROR));
    }

    public function parseToken(string $token): array
    {
        $payload = json_decode(Crypt::decryptString($token), true, 512, JSON_THROW_ON_ERROR);

        return [
            'session_id' => (int) ($payload['sid'] ?? 0),
            'nonce' => (string) ($payload['nonce'] ?? ''),
            'exp' => (int) ($payload['exp'] ?? 0),
        ];
    }
}
