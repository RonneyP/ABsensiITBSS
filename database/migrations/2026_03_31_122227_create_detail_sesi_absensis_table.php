<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('detail_sesi_absensis', function (Blueprint $table) {
            $table->id();
            $table->foreignId('sesi_absensi_id')->constrained()->onDelete('cascade');
            $table->foreignId('user_id')->constrained();
            $table->decimal('latitude_mhs', 10, 8);
            $table->decimal('longitude_mhs', 11, 8);
            $table->string('status')->default('Hadir');
            $table->timestamp('waktu_presensi')->useCurrent();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('detail_sesi_absensis');
    }
};
