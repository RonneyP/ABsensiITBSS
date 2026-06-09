<p align="center"><a href="https://laravel.com" target="_blank"><img src="https://raw.githubusercontent.com/laravel/art/master/logo-lockup/5%20SVG/2%20CMYK/1%20Full%20Color/laravel-logolockup-cmyk-red.svg" width="400" alt="Laravel Logo"></a></p>

<p align="center">
<a href="https://github.com/laravel/framework/actions"><img src="https://github.com/laravel/framework/workflows/tests/badge.svg" alt="Build Status"></a>
<a href="https://packagist.org/packages/laravel/framework"><img src="https://img.shields.io/packagist/dt/laravel/framework" alt="Total Downloads"></a>
<a href="https://packagist.org/packages/laravel/framework"><img src="https://img.shields.io/packagist/v/laravel/framework" alt="Latest Stable Version"></a>
<a href="https://packagist.org/packages/laravel/framework"><img src="https://img.shields.io/packagist/l/laravel/framework" alt="License"></a>
</p>

## Backend Absensi QR + Geolocation

Project ini berisi backend Laravel untuk sistem absensi dengan 3 aktor:

- `admin`: kelola master data dan relasi (kecuali membuat sesi absensi)
- `dosen`: buat sesi absensi, generate/refresh QR, tutup sesi, override absensi, lihat jadwal
- `mahasiswa`: lihat kelas, lihat histori, check-in pakai QR + validasi geolocation

## Setup

1. `cp .env.example .env`
2. Atur kredensial database di `.env`
3. `php artisan key:generate`
4. `php artisan migrate`
5. `php artisan db:seed`
6. `php artisan serve`

## Akun Seeder (testing)

- `admin@kampus.test / password123`
- `dosen@kampus.test / password123`
- `mahasiswa@kampus.test / password123`

Seeder juga membuat data contoh: mata kuliah, kelas, assignment dosen, enrollment mahasiswa, jadwal, dan 1 sesi absensi terbuka.

## Autentikasi

Menggunakan Laravel Sanctum (Bearer Token).

Public:
- `POST /api/register`
- `POST /api/login`

Protected:
- `GET /api/me`
- `POST /api/logout`

## Endpoint Utama

### Admin (`role:admin`)
- `POST /api/admin/users`
- `POST /api/admin/mata-kuliah`
- `POST /api/admin/classrooms`
- `POST /api/admin/assign-dosen`
- `POST /api/admin/enroll-mahasiswa`
- `POST /api/admin/schedules`
- `GET /api/admin/attendance-sessions`
- `GET /api/admin/attendance-records`

### Dosen (`role:dosen`)
- `GET /api/lecturer/schedules`
- `POST /api/lecturer/sessions`
- `POST /api/lecturer/sessions/{session}/refresh-qr`
- `PATCH /api/lecturer/sessions/{session}/close`
- `GET /api/lecturer/sessions/{session}/attendances`
- `POST /api/lecturer/attendances/{attendance}/override`

### Mahasiswa (`role:mahasiswa`)
- `GET /api/student/classes`
- `GET /api/student/histories`
- `POST /api/student/checkin`

## Catatan Validasi QR + Lokasi

- QR disimpan sebagai token terenkripsi berisi `session_id`, `nonce`, dan `exp`.
- Token diverifikasi dengan nilai `qr_nonce` dan `qr_expires_at` pada sesi.
- Lokasi mahasiswa diverifikasi menggunakan Haversine distance terhadap titik kelas.
- Check-in ditolak jika di luar `allowed_radius_m`, token expired, atau mahasiswa sudah presensi.

## Frontend Testing Sementara (`/test-ui`)

Halaman uji manual API: login (token di `localStorage`), panel **Admin / Dosen / Mahasiswa** sesuai role, form singkat untuk program studi, MK, kelas, enroll, jadwal, buat sesi + QR, refresh/tutup sesi, presensi mahasiswa, dan preset GPS dekat/jauh. Bukan untuk production.

Yang aman dihapus nanti: `resources/views/test-ui.blade.php` dan route `/test-ui` di `routes/web.php` (serta redirect `/` jika tidak diperlukan).
