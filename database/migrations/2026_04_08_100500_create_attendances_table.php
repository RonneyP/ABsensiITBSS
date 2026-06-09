<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('absensis', function (Blueprint $table) {
            $table->id();
            $table->foreignId('sesi_absensi_id')->constrained('sesi_absensis')->cascadeOnDelete();
            $table->foreignId('mahasiswa_id')->constrained('mahasiswas')->cascadeOnDelete();
            $table->string('status_absensi')->default('hadir');
            $table->dateTime('waktu_scan')->nullable();
            $table->decimal('lat_mahasiswa', 10, 8)->nullable();
            $table->decimal('long_mahasiswa', 11, 8)->nullable();
            $table->unsignedInteger('jarak_meter')->nullable();
            $table->string('sumber')->default('qr');
            $table->foreignId('diubah_oleh')->nullable()->constrained('users')->nullOnDelete();
            $table->text('alasan_ubah')->nullable();
            $table->timestamps();

            $table->unique(['sesi_absensi_id', 'mahasiswa_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('absensis');
    }
};
