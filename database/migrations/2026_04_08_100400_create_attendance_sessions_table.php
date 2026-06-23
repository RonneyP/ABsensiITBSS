<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('attendance_sessions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('classroom_id')->constrained('classrooms')->cascadeOnDelete();
            $table->foreignId('lecturer_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('schedule_id')->nullable()->constrained('jadwals')->nullOnDelete();
            $table->date('session_date');
            $table->dateTime('start_at');
            $table->dateTime('end_at')->nullable();
            $table->dateTime('closed_at')->nullable();
            $table->string('status')->default('open');
            $table->string('qr_nonce')->nullable();
            $table->dateTime('qr_expires_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('attendance_sessions');
    }
};
