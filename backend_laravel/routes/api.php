<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\AdminController;
use App\Http\Controllers\Api\AbsensiExportController;
use App\Http\Controllers\Api\AttendanceController;
use App\Http\Controllers\Api\LegacyFallbackController;
use App\Http\Controllers\Api\MentorController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\SchoolController;
use App\Http\Controllers\Api\UnitController;
use App\Http\Controllers\Api\UserController;
use Illuminate\Support\Facades\Route;

Route::post('/auth/login', [AuthController::class, 'login']);
Route::post('/auth/admin-access/verify-pin', [AuthController::class, 'verifyAdminPin']);
Route::get('/public/units', [UnitController::class, 'publicIndex']);
Route::get('/public/schools', [SchoolController::class, 'publicIndex']);
Route::middleware('legacy.auth:INTERN')->group(function (): void {
    Route::get('/intern/today', [AttendanceController::class, 'internToday']);
    Route::post('/attendance/check', [AttendanceController::class, 'check']);
    Route::post('/leave/request', [AttendanceController::class, 'leaveRequest']);
});
Route::middleware('legacy.auth:PEMBIMBING,ADMIN')->group(function (): void {
    Route::get('/mentor/interns', [MentorController::class, 'interns']);
    Route::get('/mentor/leave', [MentorController::class, 'leaveList']);
    Route::get('/mentor/leave/{leaveId}/attachment', [MentorController::class, 'leaveAttachment']);
    Route::post('/mentor/leave/{leaveId}/{decision}', [MentorController::class, 'leaveDecide'])
        ->whereIn('decision', ['approve', 'reject']);
    Route::post('/mentor/attendance/{attendanceId}/override', [MentorController::class, 'attendanceOverride']);
});
Route::middleware('legacy.auth:PEMBIMBING')->group(function (): void {
    Route::get('/mentor/units', [MentorController::class, 'units']);
    Route::match(['PUT', 'POST'], '/mentor/interns/{userId}', [MentorController::class, 'updateIntern']);
    Route::post('/mentor/interns/{userId}/{mode}', [MentorController::class, 'toggleIntern'])
        ->whereIn('mode', ['activate', 'deactivate']);
    Route::delete('/mentor/interns/{userId}', [MentorController::class, 'deleteIntern']);
    Route::get('/mentor/recap', [MentorController::class, 'recap']);
    Route::get('/mentor/recap/export', [MentorController::class, 'recapExport']);
});
Route::middleware('legacy.auth:ADMIN')->group(function (): void {
    Route::get('/settings', [AdminController::class, 'settings']);
    Route::post('/settings', [AdminController::class, 'saveSettings']);
    Route::get('/admin/registration-requests', [AdminController::class, 'registrationRequests']);
    Route::post('/admin/registration-requests/{requestId}/{decision}', [AdminController::class, 'registrationDecide'])
        ->whereIn('decision', ['approve', 'reject']);
    Route::get('/admin/interns', [AdminController::class, 'interns']);
    Route::post('/admin/interns', [AdminController::class, 'createIntern']);
    Route::match(['PUT', 'POST'], '/admin/interns/{userId}', [AdminController::class, 'updateIntern']);
    Route::post('/admin/interns/{userId}/{mode}', [AdminController::class, 'toggleIntern'])
        ->whereIn('mode', ['activate', 'deactivate']);
    Route::delete('/admin/interns/{userId}', [AdminController::class, 'deleteIntern']);
    Route::get('/admin/mentors', [AdminController::class, 'mentors']);
    Route::get('/admin/user-stats', [AdminController::class, 'userStats']);
    Route::post('/admin/mentors', [AdminController::class, 'createMentor']);
    Route::match(['PUT', 'POST'], '/admin/mentors/{mentorId}', [AdminController::class, 'updateMentor']);
    Route::delete('/admin/mentors/{mentorId}', [AdminController::class, 'deleteMentor']);
    Route::post('/admin/units', [AdminController::class, 'createUnit']);
    Route::match(['PUT', 'POST'], '/admin/units/{unitId}', [AdminController::class, 'updateUnit']);
    Route::delete('/admin/units/{unitId}', [AdminController::class, 'deleteUnit']);
    Route::get('/admin/recap', [AdminController::class, 'recap']);
    Route::get('/admin/recap/export', [AdminController::class, 'recapExport']);
    Route::post('/system/finalize-day', [AdminController::class, 'finalizeDay']);
});

Route::middleware('legacy.auth:ADMIN,PEMBIMBING')->group(function (): void {
    Route::post('/absensi/export', [AbsensiExportController::class, 'export']);
});

Route::middleware('legacy.auth')->group(function (): void {
    Route::post('/notifications/device-token', [NotificationController::class, 'registerDeviceToken']);
    Route::get('/me', [UserController::class, 'me']);
});

Route::middleware('legacy.auth:ADMIN,PEMBIMBING,INTERN')->group(function (): void {
    Route::get('/units', [UnitController::class, 'index']);
});

Route::any('/{legacyPath}', LegacyFallbackController::class)->where('legacyPath', '.*');
