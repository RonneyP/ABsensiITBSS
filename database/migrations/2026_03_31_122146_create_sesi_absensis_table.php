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
        Schema::create('sesi_absensis', function (Blueprint $table) {
            $table->id();
            $table->foreignId('mata_kuliah_id')->constrained()->onDelete('cascade');
            $table->string('qr_token')->nullable();
            $table->decimal('latitude_kelas', 10, 8)->nullable();
            $table->decimal('longitude_kelas', 11, 8)->nullable();
            $table->dateTime('waktu_mulai');
            $table->dateTime('waktu_expired');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('sesi_absensis');
    }
};
