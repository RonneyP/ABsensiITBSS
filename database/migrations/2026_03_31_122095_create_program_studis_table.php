<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Harus dijalankan sebelum create_mata_kuliahs (FK prodi_id).
 */
return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('program_studis')) {
            Schema::create('program_studis', function (Blueprint $table) {
                $table->id();
                $table->string('nama_prodi');
                $table->timestamps();
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('program_studis');
    }
};
