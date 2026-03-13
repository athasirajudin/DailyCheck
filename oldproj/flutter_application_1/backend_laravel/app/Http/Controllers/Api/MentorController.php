<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Support\LegacyApiResponse;
use App\Support\LegacyRequest;
use Carbon\CarbonImmutable;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpFoundation\StreamedResponse;

class MentorController extends Controller
{
    private const APP_TIMEZONE = 'Asia/Jakarta';
    private const ALLOWED_OVERRIDE_STATUS = ['HADIR', 'TERLAMBAT', 'ALPA', 'IZIN', 'SAKIT'];

    public function interns(Request $request): JsonResponse
    {
        $user = $this->authUser($request);
        if ($user instanceof JsonResponse) {
            return $user;
        }
        $schoolName = trim((string) $request->query('schoolName', ''));

        if ($user['role'] === 'ADMIN') {
            $query = DB::table('interns as i')
                ->join('users as u', 'u.id', '=', 'i.user_id')
                ->join('units as un', 'un.id', '=', 'i.unit_id')
                ->select([
                    'i.user_id',
                    'u.full_name',
                    'u.email',
                    'un.name as unit_name',
                    'i.active',
                    'i.school_name',
                    'i.school_address',
                    'i.internship_start',
                    'i.internship_end',
                ])
                ->orderBy('u.full_name');
            if ($schoolName !== '') {
                $query->where('i.school_name', $schoolName);
            }
            $rows = $query->get();
        } else {
            $query = DB::table('interns as i')
                ->join('users as u', 'u.id', '=', 'i.user_id')
                ->join('units as un', 'un.id', '=', 'i.unit_id')
                ->select([
                    'i.user_id',
                    'u.full_name',
                    'u.email',
                    'un.name as unit_name',
                    'i.active',
                    'i.school_name',
                    'i.school_address',
                    'i.internship_start',
                    'i.internship_end',
                ])
                ->where('i.mentor_user_id', (int) $user['user_id'])
                ->orderBy('u.full_name');
            if ($schoolName !== '') {
                $query->where('i.school_name', $schoolName);
            }
            $rows = $query->get();
        }

        $out = $rows->map(fn (object $row): array => [
            'userId' => (int) $row->user_id,
            'fullName' => $row->full_name,
            'email' => $row->email,
            'unitName' => $row->unit_name,
            'active' => (int) $row->active === 1,
            'schoolName' => $row->school_name,
            'schoolAddress' => $row->school_address,
            'internshipStart' => $row->internship_start,
            'internshipEnd' => $row->internship_end,
        ])->all();

        return LegacyApiResponse::ok($out);
    }

    public function units(Request $request): JsonResponse
    {
        $user = $this->authUser($request);
        if ($user instanceof JsonResponse) {
            return $user;
        }

        $rows = DB::table('interns as i')
            ->join('units as un', 'un.id', '=', 'i.unit_id')
            ->select(['un.id', 'un.name'])
            ->where('i.mentor_user_id', (int) $user['user_id'])
            ->distinct()
            ->orderBy('un.name')
            ->get();

        $out = $rows->map(fn (object $row): array => [
            'id' => (int) $row->id,
            'name' => $row->name,
        ])->all();

        return LegacyApiResponse::ok($out);
    }

    public function createIntern(Request $request): JsonResponse
    {
        $user = $this->authUser($request);
        if ($user instanceof JsonResponse) {
            return $user;
        }

        $body = LegacyRequest::jsonBody($request, $invalidJson);
        if ($invalidJson) {
            return LegacyApiResponse::error('BAD_JSON', 'Body JSON tidak valid.', 400);
        }

        $missing = LegacyRequest::missingFields($body, ['email', 'fullName', 'unitId', 'internshipStart', 'internshipEnd']);
        if ($missing !== []) {
            return LegacyApiResponse::error('MISSING_FIELDS', 'Field wajib belum diisi.', 422, ['missing' => $missing]);
        }

        $email = strtolower(trim((string) $body['email']));
        $fullName = trim((string) $body['fullName']);
        $unitId = (int) $body['unitId'];
        $schoolName = trim((string) ($body['schoolName'] ?? ''));
        $schoolAddress = trim((string) ($body['schoolAddress'] ?? ''));
        $start = (string) $body['internshipStart'];
        $end = (string) $body['internshipEnd'];
        $password = trim((string) ($body['password'] ?? ''));
        if ($password === '') {
            $password = 'Temp'.strtoupper(substr(bin2hex(random_bytes(3)), 0, 6)).'!';
        }
        if ($start > $end) {
            return LegacyApiResponse::error('BAD_RANGE', 'internshipStart harus <= internshipEnd.', 422);
        }

        $exists = DB::table('users')->where('email', $email)->exists();
        if ($exists) {
            return LegacyApiResponse::error('EMAIL_USED', 'Email sudah terdaftar.', 409);
        }

        $now = CarbonImmutable::now(self::APP_TIMEZONE)->format('Y-m-d H:i:s');
        $newUserId = DB::table('users')->insertGetId([
            'email' => $email,
            'full_name' => $fullName,
            'role' => 'INTERN',
            'password_hash' => password_hash($password, PASSWORD_DEFAULT),
            'created_at' => $now,
        ]);

        DB::table('interns')->insert([
            'user_id' => (int) $newUserId,
            'unit_id' => $unitId,
            'mentor_user_id' => (int) $user['user_id'],
            'school_name' => $schoolName === '' ? null : $schoolName,
            'school_address' => $schoolAddress === '' ? null : $schoolAddress,
            'internship_start' => $start,
            'internship_end' => $end,
            'active' => 1,
        ]);

        $this->auditLog(
            actorUserId: (int) $user['user_id'],
            action: 'MENTOR_INTERN_CREATE',
            entityType: 'interns',
            entityId: (int) $newUserId,
            before: null,
            after: ['email' => $email, 'userId' => (int) $newUserId],
            reason: 'create'
        );

        return LegacyApiResponse::ok([
            'userId' => (int) $newUserId,
            'tempPassword' => $password,
        ], 201);
    }

    public function toggleIntern(Request $request, int $userId, string $mode): JsonResponse
    {
        $user = $this->authUser($request);
        if ($user instanceof JsonResponse) {
            return $user;
        }

        $own = DB::table('interns')
            ->where('user_id', $userId)
            ->where('mentor_user_id', (int) $user['user_id'])
            ->first();
        if (! $own) {
            return LegacyApiResponse::error('FORBIDDEN', 'Bukan intern bimbingan kamu.', 403);
        }

        $activate = $mode === 'activate';
        $newActive = $activate ? 1 : 0;
        DB::table('interns')
            ->where('user_id', $userId)
            ->update(['active' => $newActive]);

        $this->auditLog(
            actorUserId: (int) $user['user_id'],
            action: $activate ? 'MENTOR_INTERN_ACTIVATE' : 'MENTOR_INTERN_DEACTIVATE',
            entityType: 'interns',
            entityId: $userId,
            before: (array) $own,
            after: ['active' => $newActive],
            reason: 'toggle'
        );

        return LegacyApiResponse::ok(['active' => $activate]);
    }

    public function deleteIntern(Request $request, int $userId): JsonResponse
    {
        $user = $this->authUser($request);
        if ($user instanceof JsonResponse) {
            return $user;
        }

        $body = LegacyRequest::jsonBody($request, $invalidJson);
        if ($invalidJson) {
            return LegacyApiResponse::error('BAD_JSON', 'Body JSON tidak valid.', 400);
        }
        $confirm = strtoupper(trim((string) ($body['confirm'] ?? '')));
        if ($confirm !== 'HAPUS') {
            return LegacyApiResponse::error('CONFIRM_REQUIRED', 'Ketik "HAPUS" untuk konfirmasi hapus permanen.', 422);
        }

        $intern = DB::table('interns as i')
            ->join('users as u', 'u.id', '=', 'i.user_id')
            ->select(['i.user_id', 'u.email', 'u.full_name'])
            ->where('i.user_id', $userId)
            ->where('i.mentor_user_id', (int) $user['user_id'])
            ->first();
        if (! $intern) {
            return LegacyApiResponse::error('FORBIDDEN', 'Bukan intern bimbingan kamu.', 403);
        }

        $hasAttendance = DB::table('attendance_records')->where('intern_user_id', $userId)->exists();
        $hasLeave = DB::table('leave_requests')->where('intern_user_id', $userId)->exists();
        if ($hasAttendance || $hasLeave) {
            $force = (bool) ($body['force'] ?? false);
            if (! $force) {
                return LegacyApiResponse::error('HAS_HISTORY', 'Intern punya riwayat absensi/izin. Set force=true untuk hapus permanen (akan menghapus riwayat).', 409);
            }
        }

        $this->auditLog(
            actorUserId: (int) $user['user_id'],
            action: 'MENTOR_INTERN_DELETE',
            entityType: 'interns',
            entityId: $userId,
            before: (array) $intern,
            after: ['deleted' => true],
            reason: 'hard delete'
        );

        DB::table('users')->where('id', $userId)->delete();

        return LegacyApiResponse::ok(['deleted' => true]);
    }

    public function createPairing(Request $request): JsonResponse
    {
        $user = $this->authUser($request);
        if ($user instanceof JsonResponse) {
            return $user;
        }

        $body = LegacyRequest::jsonBody($request, $invalidJson);
        if ($invalidJson) {
            return LegacyApiResponse::error('BAD_JSON', 'Body JSON tidak valid.', 400);
        }
        $missing = LegacyRequest::missingFields($body, ['unitId', 'deviceName']);
        if ($missing !== []) {
            return LegacyApiResponse::error('MISSING_FIELDS', 'Field wajib belum diisi.', 422, ['missing' => $missing]);
        }

        $unitId = (int) $body['unitId'];
        $deviceName = trim((string) $body['deviceName']);
        $allowed = DB::table('interns')
            ->where('mentor_user_id', (int) $user['user_id'])
            ->where('unit_id', $unitId)
            ->exists();
        if (! $allowed) {
            return LegacyApiResponse::error('FORBIDDEN', 'Kamu tidak punya intern di unit ini.', 403);
        }

        $code = strtoupper(substr(bin2hex(random_bytes(4)), 0, 8));
        $expiresAt = CarbonImmutable::now(self::APP_TIMEZONE)->addMinutes(10)->format('Y-m-d H:i:s');
        DB::table('pairing_codes')->insert([
            'unit_id' => $unitId,
            'device_name' => $deviceName,
            'code' => $code,
            'expires_at' => $expiresAt,
            'created_by_user_id' => (int) $user['user_id'],
            'created_at' => CarbonImmutable::now(self::APP_TIMEZONE)->format('Y-m-d H:i:s'),
        ]);

        return LegacyApiResponse::ok([
            'pairingCode' => $code,
            'expiresAt' => $expiresAt,
        ]);
    }

    public function leaveList(Request $request): JsonResponse
    {
        $user = $this->authUser($request);
        if ($user instanceof JsonResponse) {
            return $user;
        }
        $schoolName = trim((string) $request->query('schoolName', ''));

        if ($user['role'] === 'ADMIN') {
            $query = DB::table('leave_requests as lr')
                ->join('users as u', 'u.id', '=', 'lr.intern_user_id')
                ->leftJoin('interns as i', 'i.user_id', '=', 'lr.intern_user_id')
                ->select(['lr.*', 'u.full_name', 'i.school_name'])
                ->orderByDesc('lr.id');
            if ($schoolName !== '') {
                $query->where('i.school_name', $schoolName);
            }
            $rows = $query->get();
        } else {
            $query = DB::table('leave_requests as lr')
                ->join('users as u', 'u.id', '=', 'lr.intern_user_id')
                ->join('interns as i', 'i.user_id', '=', 'lr.intern_user_id')
                ->select(['lr.*', 'u.full_name', 'i.school_name'])
                ->where('i.mentor_user_id', (int) $user['user_id'])
                ->orderByDesc('lr.id');
            if ($schoolName !== '') {
                $query->where('i.school_name', $schoolName);
            }
            $rows = $query->get();
        }

        return LegacyApiResponse::ok($rows->map(fn (object $row) => (array) $row)->all());
    }

    public function leaveDecide(Request $request, int $leaveId, string $decision): JsonResponse
    {
        $user = $this->authUser($request);
        if ($user instanceof JsonResponse) {
            return $user;
        }

        $body = LegacyRequest::jsonBody($request, $invalidJson);
        if ($invalidJson) {
            return LegacyApiResponse::error('BAD_JSON', 'Body JSON tidak valid.', 400);
        }
        $reason = trim((string) ($body['reason'] ?? ''));

        $leave = DB::table('leave_requests')->where('id', $leaveId)->first();
        if (! $leave) {
            return LegacyApiResponse::error('NOT_FOUND', 'Leave request tidak ditemukan.', 404);
        }
        if ($user['role'] === 'PEMBIMBING') {
            $own = DB::table('interns')
                ->where('user_id', (int) $leave->intern_user_id)
                ->where('mentor_user_id', (int) $user['user_id'])
                ->exists();
            if (! $own) {
                return LegacyApiResponse::error('FORBIDDEN', 'Bukan intern bimbingan kamu.', 403);
            }
        }
        if ($leave->status !== 'PENDING') {
            return LegacyApiResponse::error('INVALID_STATE', 'Request sudah diputus.', 409);
        }

        $newStatus = $decision === 'approve' ? 'APPROVED' : 'REJECTED';
        DB::table('leave_requests')
            ->where('id', $leaveId)
            ->update([
                'status' => $newStatus,
                'decided_by_user_id' => (int) $user['user_id'],
                'decided_at' => CarbonImmutable::now(self::APP_TIMEZONE)->format('Y-m-d H:i:s'),
            ]);

        $this->auditLog(
            actorUserId: (int) $user['user_id'],
            action: 'LEAVE_DECIDE',
            entityType: 'leave_requests',
            entityId: $leaveId,
            before: (array) $leave,
            after: ['status' => $newStatus],
            reason: $reason
        );

        $updated = DB::table('leave_requests')->where('id', $leaveId)->first();

        return LegacyApiResponse::ok((array) $updated);
    }

    public function attendanceOverride(Request $request, int $attendanceId): JsonResponse
    {
        $user = $this->authUser($request);
        if ($user instanceof JsonResponse) {
            return $user;
        }

        $body = LegacyRequest::jsonBody($request, $invalidJson);
        if ($invalidJson) {
            return LegacyApiResponse::error('BAD_JSON', 'Body JSON tidak valid.', 400);
        }
        $missing = LegacyRequest::missingFields($body, ['status', 'reason']);
        if ($missing !== []) {
            return LegacyApiResponse::error('MISSING_FIELDS', 'Field wajib belum diisi.', 422, ['missing' => $missing]);
        }

        $status = strtoupper(trim((string) $body['status']));
        $reason = trim((string) $body['reason']);
        if (! in_array($status, self::ALLOWED_OVERRIDE_STATUS, true)) {
            return LegacyApiResponse::error('BAD_STATUS', 'Status tidak valid.', 422);
        }

        $rec = DB::table('attendance_records')->where('id', $attendanceId)->first();
        if (! $rec) {
            return LegacyApiResponse::error('NOT_FOUND', 'AttendanceRecord tidak ditemukan.', 404);
        }
        if ($user['role'] === 'PEMBIMBING') {
            $own = DB::table('interns')
                ->where('user_id', (int) $rec->intern_user_id)
                ->where('mentor_user_id', (int) $user['user_id'])
                ->exists();
            if (! $own) {
                return LegacyApiResponse::error('FORBIDDEN', 'Bukan intern bimbingan kamu.', 403);
            }
        }

        $markedBy = $user['role'] === 'ADMIN' ? 'ADMIN' : 'PEMBIMBING';
        DB::table('attendance_records')
            ->where('id', $attendanceId)
            ->update([
                'status' => $status,
                'status_marked_by' => $markedBy,
                'updated_at' => CarbonImmutable::now(self::APP_TIMEZONE)->format('Y-m-d H:i:s'),
            ]);

        $this->auditLog(
            actorUserId: (int) $user['user_id'],
            action: 'ATTENDANCE_OVERRIDE',
            entityType: 'attendance_records',
            entityId: $attendanceId,
            before: (array) $rec,
            after: ['status' => $status, 'status_marked_by' => $markedBy],
            reason: $reason
        );

        $updated = DB::table('attendance_records')->where('id', $attendanceId)->first();

        return LegacyApiResponse::ok($this->attendanceToDto($updated));
    }

    public function recap(Request $request): JsonResponse
    {
        $user = $this->authUser($request);
        if ($user instanceof JsonResponse) {
            return $user;
        }

        $dateFrom = (string) $request->query('dateFrom', CarbonImmutable::now(self::APP_TIMEZONE)->format('Y-m-d'));
        $dateTo = (string) $request->query('dateTo', CarbonImmutable::now(self::APP_TIMEZONE)->format('Y-m-d'));
        $schoolName = trim((string) $request->query('schoolName', ''));
        if ($dateFrom > $dateTo) {
            return LegacyApiResponse::error('BAD_RANGE', 'dateFrom harus <= dateTo.', 422);
        }

        $internUserId = $request->query('internUserId');
        $query = DB::table('attendance_records as ar')
            ->join('users as u', 'u.id', '=', 'ar.intern_user_id')
            ->join('units as un', 'un.id', '=', 'ar.unit_id')
            ->join('interns as i', 'i.user_id', '=', 'ar.intern_user_id')
            ->select([
                'ar.*',
                'u.full_name',
                'un.name as unit_name',
                'i.school_name',
            ])
            ->whereBetween('ar.date', [$dateFrom, $dateTo])
            ->where('i.mentor_user_id', (int) $user['user_id']);
        if ($internUserId !== null && (int) $internUserId > 0) {
            $query->where('ar.intern_user_id', (int) $internUserId);
        }
        if ($schoolName !== '') {
            $query->where('i.school_name', $schoolName);
        }
        $rows = $query
            ->orderByDesc('ar.date')
            ->orderBy('u.full_name')
            ->get();

        $summary = [
            'HADIR' => 0,
            'TERLAMBAT' => 0,
            'IZIN' => 0,
            'SAKIT' => 0,
            'ALPA' => 0,
            'CHECKOUT_MISSING' => 0,
        ];
        foreach ($rows as $row) {
            $status = (string) $row->status;
            if (array_key_exists($status, $summary)) {
                $summary[$status]++;
            }
            if ((int) $row->checkout_missing === 1) {
                $summary['CHECKOUT_MISSING']++;
            }
        }

        $items = $rows->map(fn (object $row): array => [
            'id' => (int) $row->id,
            'date' => $row->date,
            'internUserId' => (int) $row->intern_user_id,
            'internName' => $row->full_name,
            'schoolName' => $row->school_name,
            'unitName' => $row->unit_name,
            'status' => $row->status,
            'markedBy' => $row->status_marked_by,
            'checkInAt' => $row->check_in_at,
            'checkOutAt' => $row->check_out_at,
            'checkoutMissing' => (int) $row->checkout_missing === 1,
        ])->all();

        return LegacyApiResponse::ok([
            'summary' => $summary,
            'items' => $items,
        ]);
    }

    public function recapExport(Request $request): StreamedResponse|JsonResponse
    {
        $user = $this->authUser($request);
        if ($user instanceof JsonResponse) {
            return $user;
        }

        $format = strtolower((string) $request->query('format', 'csv'));
        if ($format !== 'csv') {
            return LegacyApiResponse::error('BAD_FORMAT', 'Saat ini hanya mendukung format=csv.', 422);
        }

        $dateFrom = (string) $request->query('dateFrom', CarbonImmutable::now(self::APP_TIMEZONE)->format('Y-m-d'));
        $dateTo = (string) $request->query('dateTo', CarbonImmutable::now(self::APP_TIMEZONE)->format('Y-m-d'));
        $schoolName = trim((string) $request->query('schoolName', ''));
        if ($dateFrom > $dateTo) {
            return LegacyApiResponse::error('BAD_RANGE', 'dateFrom harus <= dateTo.', 422);
        }

        $rows = DB::table('attendance_records as ar')
            ->join('users as u', 'u.id', '=', 'ar.intern_user_id')
            ->join('units as un', 'un.id', '=', 'ar.unit_id')
            ->join('interns as i', 'i.user_id', '=', 'ar.intern_user_id')
            ->select([
                'ar.date',
                'u.full_name',
                'u.email',
                'i.school_name',
                'un.name as unit_name',
                'ar.status',
                'ar.status_marked_by',
                'ar.check_in_at',
                'ar.check_out_at',
                'ar.checkout_missing',
            ])
            ->whereBetween('ar.date', [$dateFrom, $dateTo])
            ->where('i.mentor_user_id', (int) $user['user_id'])
            ->orderByDesc('ar.date')
            ->orderBy('u.full_name')
            ->get();
        if ($schoolName !== '') {
            $rows = $rows->filter(fn (object $row): bool => (string) ($row->school_name ?? '') === $schoolName)->values();
        }

        $filename = "rekap_mentor_{$dateFrom}_{$dateTo}.csv";

        return response()->streamDownload(function () use ($rows): void {
            $out = fopen('php://output', 'w');
            fputcsv($out, ['date', 'intern_name', 'email', 'school', 'unit', 'status', 'marked_by', 'check_in_at', 'check_out_at', 'checkout_missing']);
            foreach ($rows as $row) {
                fputcsv($out, [
                    $row->date,
                    $row->full_name,
                    $row->email,
                    $row->school_name,
                    $row->unit_name,
                    $row->status,
                    $row->status_marked_by,
                    $row->check_in_at,
                    $row->check_out_at,
                    $row->checkout_missing,
                ]);
            }
            fclose($out);
        }, $filename, [
            'Content-Type' => 'text/csv; charset=utf-8',
        ]);
    }

    private function authUser(Request $request): array|JsonResponse
    {
        $user = $request->attributes->get('auth_user');
        if (! is_array($user)) {
            return LegacyApiResponse::error('UNAUTHENTICATED', 'Butuh login.', 401);
        }

        return $user;
    }

    private function attendanceToDto(object $row): array
    {
        return [
            'id' => (int) $row->id,
            'date' => $row->date,
            'status' => $row->status,
            'markedBy' => $row->status_marked_by,
            'checkInAt' => $row->check_in_at,
            'checkOutAt' => $row->check_out_at,
            'checkoutMissing' => (int) $row->checkout_missing === 1,
        ];
    }

    private function auditLog(
        int $actorUserId,
        string $action,
        string $entityType,
        int $entityId,
        mixed $before,
        mixed $after,
        string $reason = ''
    ): void {
        DB::table('audit_logs')->insert([
            'actor_user_id' => $actorUserId,
            'action' => $action,
            'entity_type' => $entityType,
            'entity_id' => $entityId,
            'before_json' => json_encode($before, JSON_UNESCAPED_UNICODE),
            'after_json' => json_encode($after, JSON_UNESCAPED_UNICODE),
            'reason' => $reason,
            'created_at' => CarbonImmutable::now(self::APP_TIMEZONE)->format('Y-m-d H:i:s'),
        ]);
    }
}
