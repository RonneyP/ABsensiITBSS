# Mobile App Absensi (Flutter)

Frontend Flutter untuk backend Laravel Absensi (Sanctum token) pada repo yang sama.

## Fitur Yang Sudah Dibuat

- Login ke `/api/login`
- Simpan token + user di local storage
- Routing dashboard berdasarkan `role` (`admin`, `dosen`, `mahasiswa`)
- Mahasiswa:
  - Lihat kelas (`GET /api/student/classes`)
  - Lihat histori (`GET /api/student/histories`)
  - Check-in via scan QR + geolocation (`POST /api/student/checkin`)
- Dosen/Admin:
  - Viewer cepat untuk endpoint utama (JSON raw)

## Menjalankan Aplikasi

1. Jalankan backend Laravel:
   - `php artisan serve`
2. Jalankan Flutter:
   - `cd mobile_app`
   - `flutter pub get`
   - `flutter run`

## Catatan Base URL

Input `Base URL Laravel` di halaman login:

- Flutter Web (Chrome/Edge): `http://127.0.0.1:8000`
- Android Emulator: `http://10.0.2.2:8000`
- iOS Simulator: `http://127.0.0.1:8000`
- Device fisik: `http://<ip-lokal-pc-anda>:8000`

## Permission

Sudah ditambahkan:
- Android: Camera + Location (`AndroidManifest.xml`)
- iOS: Camera + Location (`Info.plist`)
