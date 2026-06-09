<?php

use App\Http\Controllers\AdminController;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\LecturerController;
use App\Http\Controllers\StudentController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/me', [AuthController::class, 'me']);
    Route::post('/logout', [AuthController::class, 'logout']);

    Route::prefix('admin')->middleware('role:admin')->group(function () {
        Route::post('/users', [AdminController::class, 'createUser']);
        Route::post('/program-studi', [AdminController::class, 'createProgramStudi']);
        Route::post('/mata-kuliah', [AdminController::class, 'createMataKuliah']);
        Route::post('/kelas', [AdminController::class, 'createKelas']);
        Route::post('/enroll-mahasiswa', [AdminController::class, 'enrollMahasiswa']);
        Route::post('/schedules', [AdminController::class, 'createSchedule']);
        Route::get('/attendance-sessions', [AdminController::class, 'sessions']);
        Route::get('/attendance-records', [AdminController::class, 'attendanceRecords']);
    });

    Route::prefix('lecturer')->middleware('role:dosen')->group(function () {
        Route::get('/schedules', [LecturerController::class, 'schedules']);
        Route::post('/sessions', [LecturerController::class, 'createSession']);
        Route::post('/sessions/{sesi_absensi}/refresh-qr', [LecturerController::class, 'refreshQr']);
        Route::patch('/sessions/{sesi_absensi}/close', [LecturerController::class, 'closeSession']);
        Route::get('/sessions/{sesi_absensi}/attendances', [LecturerController::class, 'sessionAttendances']);
        Route::post('/attendances/{absensi}/override', [LecturerController::class, 'overrideAttendance']);
    });

    Route::prefix('student')->middleware('role:mahasiswa')->group(function () {
        Route::get('/classes', [StudentController::class, 'classes']);
        Route::get('/histories', [StudentController::class, 'history']);
        Route::post('/checkin', [StudentController::class, 'checkin']);
    });
});
