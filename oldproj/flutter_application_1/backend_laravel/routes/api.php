<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\AdminController;
use App\Http\Controllers\Api\AttendanceController;
use App\Http\Controllers\Api\DeviceController;
use App\Http\Controllers\Api\LegacyFallbackController;
use App\Http\Controllers\Api\MentorController;
use App\Http\Controllers\Api\RegistrationController;
use App\Http\Controllers\Api\SchoolController;
use App\Http\Controllers\Api\UnitController;
use App\Http\Controllers\Api\UserController;
use Illuminate\Support\Facades\Route;

Route::post('/auth/login', [AuthController::class, 'login']);
Route::post('/register/request', [RegistrationController::class, 'store']);
Route::get('/public/units', [UnitController::class, 'publicIndex']);
Route::get('/public/schools', [SchoolController::class, 'publicIndex']);
Route::post('/device/pair', [DeviceController::class, 'pair']);
Route::post('/device/heartbeat', [DeviceController::class, 'heartbeat']);
Route::post('/device/qr-token', [DeviceController::class, 'qrToken']);
Route::middleware('legacy.auth:INTERN')->group(function (): void {
    Route::get('/intern/today', [AttendanceController::class, 'internToday']);
    Route::post('/attendance/check', [AttendanceController::class, 'check']);
    Route::post('/leave/request', [AttendanceController::class, 'leaveRequest']);
});
Route::middleware('legacy.auth:PEMBIMBING,ADMIN')->group(function (): void {
    Route::get('/mentor/interns', [MentorController::class, 'interns']);
    Route::get('/mentor/leave', [MentorController::class, 'leaveList']);
    Route::post('/mentor/leave/{leaveId}/{decision}', [MentorController::class, 'leaveDecide'])
        ->whereIn('decision', ['approve', 'reject']);
    Route::post('/mentor/attendance/{attendanceId}/override', [MentorController::class, 'attendanceOverride']);
});
Route::middleware('legacy.auth:PEMBIMBING')->group(function (): void {
    Route::get('/mentor/units', [MentorController::class, 'units']);
    Route::post('/mentor/interns', [MentorController::class, 'createIntern']);
    Route::post('/mentor/interns/{userId}/{mode}', [MentorController::class, 'toggleIntern'])
        ->whereIn('mode', ['activate', 'deactivate']);
    Route::match(['POST', 'DELETE'], '/mentor/interns/{userId}', [MentorController::class, 'deleteIntern']);
    Route::post('/mentor/pairing/create', [MentorController::class, 'createPairing']);
    Route::get('/mentor/recap', [MentorController::class, 'recap']);
    Route::get('/mentor/recap/export', [MentorController::class, 'recapExport']);
});
Route::middleware('legacy.auth:ADMIN')->group(function (): void {
    Route::get('/settings', [AdminController::class, 'settings']);
    Route::post('/settings', [AdminController::class, 'saveSettings']);
    Route::post('/admin/pairing/create', [AdminController::class, 'createPairing']);
    Route::get('/admin/registration-requests', [AdminController::class, 'registrationRequests']);
    Route::post('/admin/registration-requests/{requestId}/{decision}', [AdminController::class, 'registrationDecide'])
        ->whereIn('decision', ['approve', 'reject']);
    Route::get('/admin/interns', [AdminController::class, 'interns']);
    Route::post('/admin/interns', [AdminController::class, 'createIntern']);
    Route::put('/admin/interns/{userId}', [AdminController::class, 'updateIntern']);
    Route::post('/admin/interns/{userId}/{mode}', [AdminController::class, 'toggleIntern'])
        ->whereIn('mode', ['activate', 'deactivate']);
    Route::match(['POST', 'DELETE'], '/admin/interns/{userId}', [AdminController::class, 'deleteIntern']);
    Route::get('/admin/mentors', [AdminController::class, 'mentors']);
    Route::match(['PUT', 'POST'], '/admin/units/{unitId}', [AdminController::class, 'updateUnit']);
    Route::get('/admin/devices', [AdminController::class, 'devices']);
    Route::get('/admin/recap', [AdminController::class, 'recap']);
    Route::get('/admin/recap/export', [AdminController::class, 'recapExport']);
    Route::post('/system/finalize-day', [AdminController::class, 'finalizeDay']);
});

Route::middleware('legacy.auth')->group(function (): void {
    Route::get('/me', [UserController::class, 'me']);
});

Route::middleware('legacy.auth:ADMIN,PEMBIMBING,INTERN')->group(function (): void {
    Route::get('/units', [UnitController::class, 'index']);
});

Route::any('/{legacyPath}', LegacyFallbackController::class)->where('legacyPath', '.*');
