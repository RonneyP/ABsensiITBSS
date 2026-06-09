<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return redirect('/test-ui');
});

Route::view('/test-ui', 'test-ui');
