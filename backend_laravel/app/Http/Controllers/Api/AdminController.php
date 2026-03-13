<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Support\LegacyApiResponse;
use App\Support\LegacyRequest;
use App\Support\RecapExcelExporter;
use Carbon\CarbonImmutable;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use PhpOffice\PhpSpreadsheet\Writer\Xlsx;
use Symfony\Component\HttpFoundation\StreamedResponse;

class AdminController extends Controller
{
    private const APP_TIMEZONE = 'Asia/Jakarta';
    private const DEFAULT_WORK_START_TIME = '09:00:00';
    private const DEFAULT_WORK_END_TIME = '17:00:00';
    private const DEFAULT_TOLERANCE_MINUTES = 15;
    private const DEFAULT_DAY_CUTOFF_TIME = '23:59:59';
    private const DEFAULT_WORKDAYS_JSON = '[1,2,3,4,5]';
    private const DEFAULT_OFFLINE_THRESHOLD_SECONDS = 120;
    private const DEFAULT_QR_TTL_SECONDS = 30;

    public function settings(Request $request): JsonResponse
    {
        $user = $this->authAdmin($request);
        if ($user instanceof JsonResponse) {
            return $user;
        }

        return LegacyApiResponse::ok($this->getSettings());
    }

    public function saveSettings(Request $request): JsonResponse
    {
        $user = $this->authAdmin($request);
        if ($user instanceof JsonResponse) {
            return $user;
        }

        $body = LegacyRequest::jsonBody($request, $invalidJson);
        if ($invalidJson) {
            return LegacyApiResponse::error('BAD_JSON', 'Body JSON tidak valid.', 400);
        }

        $timezone = (string) ($body['timezone'] ?? self::APP_TIMEZONE);
        $workStart = (string) ($body['work_start_time'] ?? self::DEFAULT_WORK_START_TIME);
        $workEnd = (string) ($body['work_end_time'] ?? self::DEFAULT_WORK_END_TIME);
        $tol = (int) ($body['tolerance_minutes'] ?? self::DEFAULT_TOLERANCE_MINUTES);
        $cutoff = (string) ($body['day_cutoff_time'] ?? self::DEFAULT_DAY_CUTOFF_TIME);
        $workdaysJson = json_encode($body['workdays'] ?? [1, 2, 3, 4, 5]);
        $offlineThreshold = (int) ($body['offline_threshold_seconds'] ?? self::DEFAULT_OFFLINE_THRESHOLD_SECONDS);
        $qrTtl = (int) ($body['qr_token_ttl_seconds'] ?? self::DEFAULT_QR_TTL_SECONDS);

        DB::table('settings')->updateOrInsert(
            ['id' => 1],
            [
                'timezone' => $timezone,
                'work_start_time' => $workStart,
                'work_end_time' => $workEnd,
                'tolerance_minutes' => $tol,
                'day_cutoff_time' => $cutoff,
                'workdays_json' => $workdaysJson,
                'offline_threshold_seconds' => $offlineThreshold,
                'qr_token_ttl_seconds' => $qrTtl,
                'updated_at' => CarbonImmutable::now(self::APP_TIMEZONE)->format('Y-m-d H:i:s'),
                'updated_by_user_id' => (int) $user['user_id'],
            ]
        );

        return LegacyApiResponse::ok($this->getSettings());
    }

    public function createPairing(Request $request): JsonResponse
    {
        $user = $this->authAdmin($request);
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
        $unitExists = DB::table('units')->where('id', $unitId)->exists();
        if (! $unitExists) {
            return LegacyApiResponse::error('NOT_FOUND', 'Unit tidak ditemukan.', 404);
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

    public function registrationRequests(Request $request): JsonResponse
    {
        $user = $this->authAdmin($request);
        if ($user instanceof JsonResponse) {
            return $user;
        }

        $status = strtoupper((string) $request->query('status', 'PENDING'));
        if (! in_array($status, ['PENDING', 'APPROVED', 'REJECTED'], true)) {
            $status = 'PENDING';
        }

        $rows = DB::table('registration_requests as rr')
            ->join('units as u', 'u.id', '=', 'rr.unit_id')
            ->leftJoin('users as m', 'm.id', '=', 'rr.mentor_user_id')
            ->select(['rr.*', 'u.name as unit_name', 'm.full_name as mentor_name'])
            ->where('rr.status', $status)
            ->orderByDesc('rr.id')
            ->get();

        return LegacyApiResponse::ok($rows->map(fn (object $row) => (array) $row)->all());
    }

    public function registrationDecide(Request $request, int $requestId, string $decision): JsonResponse
    {
        $user = $this->authAdmin($request);
        if ($user instanceof JsonResponse) {
            return $user;
        }

        $body = LegacyRequest::jsonBody($request, $invalidJson);
        if ($invalidJson) {
            return LegacyApiResponse::error('BAD_JSON', 'Body JSON tidak valid.', 400);
        }
        $reason = trim((string) ($body['reason'] ?? ''));

        $req = DB::table('registration_requests')->where('id', $requestId)->first();
        if (! $req) {
            return LegacyApiResponse::error('NOT_FOUND', 'Request tidak ditemukan.', 404);
        }
        if ($req->status !== 'PENDING') {
            return LegacyApiResponse::error('INVALID_STATE', 'Request sudah diputus.', 409);
        }

        if ($decision === 'reject') {
            DB::table('registration_requests')
                ->where('id', $requestId)
                ->update([
                    'status' => 'REJECTED',
                    'decided_by_user_id' => (int) $user['user_id'],
                    'decided_at' => CarbonImmutable::now(self::APP_TIMEZONE)->format('Y-m-d H:i:s'),
                    'decision_reason' => $reason,
                ]);

            $this->auditLog(
                actorUserId: (int) $user['user_id'],
                action: 'REG_REQUEST_REJECT',
                entityType: 'registration_requests',
                entityId: $requestId,
                before: (array) $req,
                after: ['status' => 'REJECTED'],
                reason: $reason
            );

            $updated = DB::table('registration_requests')->where('id', $requestId)->first();

            return LegacyApiResponse::ok(['request' => (array) $updated]);
        }

        $email = (string) $req->email;
        $exists = DB::table('users')->where('email', $email)->exists();
        if ($exists) {
            return LegacyApiResponse::error('EMAIL_USED', 'Email sudah terdaftar.', 409);
        }

        $mentorUserId = array_key_exists('mentorUserId', $body)
            ? ($body['mentorUserId'] === null ? null : (int) $body['mentorUserId'])
            : ($req->mentor_user_id !== null ? (int) $req->mentor_user_id : null);
        $unitId = array_key_exists('unitId', $body) ? (int) $body['unitId'] : (int) $req->unit_id;
        $start = (string) ($body['internshipStart'] ?? $req->internship_start);
        $end = (string) ($body['internshipEnd'] ?? $req->internship_end);
        $schoolName = trim((string) ($body['schoolName'] ?? ($req->school_name ?? '')));
        $schoolAddress = trim((string) ($body['schoolAddress'] ?? ($req->school_address ?? '')));
        if ($start > $end) {
            return LegacyApiResponse::error('BAD_RANGE', 'internshipStart harus <= internshipEnd.', 422);
        }

        $tempPassword = trim((string) ($body['tempPassword'] ?? ''));
        if ($tempPassword === '') {
            $tempPassword = 'Temp'.strtoupper(substr(bin2hex(random_bytes(3)), 0, 6)).'!';
        }

        $newUserId = null;
        DB::transaction(function () use (
            &$newUserId,
            $email,
            $req,
            $tempPassword,
            $unitId,
            $mentorUserId,
            $schoolName,
            $schoolAddress,
            $start,
            $end,
            $reason,
            $requestId,
            $user
        ): void {
            $newUserId = DB::table('users')->insertGetId([
                'email' => $email,
                'full_name' => (string) $req->full_name,
                'role' => 'INTERN',
                'password_hash' => password_hash($tempPassword, PASSWORD_DEFAULT),
                'created_at' => CarbonImmutable::now(self::APP_TIMEZONE)->format('Y-m-d H:i:s'),
            ]);

            DB::table('interns')->insert([
                'user_id' => (int) $newUserId,
                'unit_id' => $unitId,
                'mentor_user_id' => $mentorUserId,
                'school_name' => $schoolName === '' ? null : $schoolName,
                'school_address' => $schoolAddress === '' ? null : $schoolAddress,
                'internship_start' => $start,
                'internship_end' => $end,
                'active' => 1,
            ]);

            DB::table('registration_requests')
                ->where('id', $requestId)
                ->update([
                    'status' => 'APPROVED',
                    'decided_by_user_id' => (int) $user['user_id'],
                    'decided_at' => CarbonImmutable::now(self::APP_TIMEZONE)->format('Y-m-d H:i:s'),
                    'decision_reason' => $reason,
                    'mentor_user_id' => $mentorUserId,
                    'unit_id' => $unitId,
                    'school_name' => $schoolName === '' ? null : $schoolName,
                    'school_address' => $schoolAddress === '' ? null : $schoolAddress,
                    'internship_start' => $start,
                    'internship_end' => $end,
                ]);
        });

        $this->auditLog(
            actorUserId: (int) $user['user_id'],
            action: 'REG_REQUEST_APPROVE',
            entityType: 'registration_requests',
            entityId: $requestId,
            before: (array) $req,
            after: ['status' => 'APPROVED', 'created_user_id' => (int) $newUserId],
            reason: $reason
        );

        return LegacyApiResponse::ok([
            'createdUserId' => (int) $newUserId,
            'tempPassword' => $tempPassword,
        ]);
    }

    public function mentors(Request $request): JsonResponse
    {
        $user = $this->authAdmin($request);
        if ($user instanceof JsonResponse) {
            return $user;
        }

        $rows = DB::table('users')
            ->select(['id', 'email', 'full_name'])
            ->where('role', 'PEMBIMBING')
            ->orderBy('full_name')
            ->get();

        $out = $rows->map(fn (object $row): array => [
            'id' => (int) $row->id,
            'email' => $row->email,
            'fullName' => $row->full_name,
        ])->all();

        return LegacyApiResponse::ok($out);
    }

    public function userStats(Request $request): JsonResponse
    {
        $user = $this->authAdmin($request);
        if ($user instanceof JsonResponse) {
            return $user;
        }

        $totalUsers = (int) DB::table('users')->count();
        $totalInterns = (int) DB::table('interns')->count();
        $activeInterns = (int) DB::table('interns')->where('active', 1)->count();
        $nonActiveUsers = max(0, $totalInterns - $activeInterns);
        $activeUsers = max(0, $totalUsers - $nonActiveUsers);

        return LegacyApiResponse::ok([
            'totalUsers' => $totalUsers,
            'activeUsers' => $activeUsers,
            'nonActiveUsers' => $nonActiveUsers,
        ]);
    }

    public function interns(Request $request): JsonResponse
    {
        $user = $this->authAdmin($request);
        if ($user instanceof JsonResponse) {
            return $user;
        }
        $schoolName = trim((string) $request->query('schoolName', ''));

        $query = DB::table('interns as i')
            ->join('users as u', 'u.id', '=', 'i.user_id')
            ->leftJoin('units as un', 'un.id', '=', 'i.unit_id')
            ->leftJoin('users as m', 'm.id', '=', 'i.mentor_user_id')
            ->select([
                'i.user_id',
                'i.nisn',
                'i.gender',
                'u.full_name',
                'u.email',
                'i.unit_id',
                'un.name as unit_name',
                'i.mentor_user_id',
                'm.full_name as mentor_name',
                'i.school_name',
                'i.school_address',
                'i.internship_start',
                'i.internship_end',
                'i.active',
            ])
            ->orderBy('u.full_name');
        if ($schoolName !== '') {
            $query->where('i.school_name', $schoolName);
        }
        $rows = $query->get();

        return LegacyApiResponse::ok($rows->map(fn (object $row) => (array) $row)->all());
    }

    public function createMentor(Request $request): JsonResponse
    {
        $user = $this->authAdmin($request);
        if ($user instanceof JsonResponse) {
            return $user;
        }

        $body = LegacyRequest::jsonBody($request, $invalidJson);
        if ($invalidJson) {
            return LegacyApiResponse::error('BAD_JSON', 'Body JSON tidak valid.', 400);
        }

        $missing = LegacyRequest::missingFields($body, ['email', 'fullName']);
        if ($missing !== []) {
            return LegacyApiResponse::error('MISSING_FIELDS', 'Field wajib belum diisi.', 422, ['missing' => $missing]);
        }

        $email = strtolower(trim((string) $body['email']));
        $fullName = trim((string) $body['fullName']);
        $password = trim((string) ($body['password'] ?? ''));
        if ($password === '') {
            $password = 'Mentor'.strtoupper(substr(bin2hex(random_bytes(3)), 0, 6)).'!';
        }

        $exists = DB::table('users')->where('email', $email)->exists();
        if ($exists) {
            return LegacyApiResponse::error('EMAIL_USED', 'Email sudah terdaftar.', 409);
        }

        $now = CarbonImmutable::now(self::APP_TIMEZONE)->format('Y-m-d H:i:s');
        $newUserId = DB::table('users')->insertGetId([
            'email' => $email,
            'full_name' => $fullName,
            'role' => 'PEMBIMBING',
            'password_hash' => password_hash($password, PASSWORD_DEFAULT),
            'created_at' => $now,
        ]);

        $this->auditLog(
            actorUserId: (int) $user['user_id'],
            action: 'ADMIN_MENTOR_CREATE',
            entityType: 'users',
            entityId: (int) $newUserId,
            before: null,
            after: ['email' => $email, 'role' => 'PEMBIMBING'],
            reason: 'create mentor'
        );

        return LegacyApiResponse::ok([
            'userId' => (int) $newUserId,
            'tempPassword' => $password,
        ], 201);
    }

    public function updateMentor(Request $request, int $mentorId): JsonResponse
    {
        $user = $this->authAdmin($request);
        if ($user instanceof JsonResponse) {
            return $user;
        }

        $body = LegacyRequest::jsonBody($request, $invalidJson);
        if ($invalidJson) {
            return LegacyApiResponse::error('BAD_JSON', 'Body JSON tidak valid.', 400);
        }

        $mentor = DB::table('users')->where('id', $mentorId)->where('role', 'PEMBIMBING')->first();
        if (! $mentor) {
          return LegacyApiResponse::error('NOT_FOUND', 'Mentor tidak ditemukan.', 404);
        }

        $email = strtolower(trim((string) ($body['email'] ?? $mentor->email)));
        $fullName = trim((string) ($body['fullName'] ?? $mentor->full_name));
        $password = trim((string) ($body['password'] ?? ''));
        if ($fullName === '') {
            return LegacyApiResponse::error('BAD_INPUT', 'Nama wajib diisi.', 422);
        }
        $emailUsed = DB::table('users')
            ->where('email', $email)
            ->where('id', '!=', $mentorId)
            ->exists();
        if ($emailUsed) {
            return LegacyApiResponse::error('EMAIL_USED', 'Email sudah terdaftar.', 409);
        }

        $update = [
            'email' => $email,
            'full_name' => $fullName,
        ];
        if ($password !== '') {
            $update['password_hash'] = password_hash($password, PASSWORD_DEFAULT);
        }

        DB::table('users')->where('id', $mentorId)->update($update);

        $this->auditLog(
            actorUserId: (int) $user['user_id'],
            action: 'ADMIN_MENTOR_UPDATE',
            entityType: 'users',
            entityId: (int) $mentorId,
            before: (array) $mentor,
            after: $update,
            reason: 'update mentor'
        );

        $updated = DB::table('users')->where('id', $mentorId)->first();

        return LegacyApiResponse::ok((array) $updated);
    }

    public function deleteMentor(Request $request, int $mentorId): JsonResponse
    {
        $user = $this->authAdmin($request);
        if ($user instanceof JsonResponse) {
            return $user;
        }

        $mentor = DB::table('users')->where('id', $mentorId)->where('role', 'PEMBIMBING')->first();
        if (! $mentor) {
            return LegacyApiResponse::error('NOT_FOUND', 'Mentor tidak ditemukan.', 404);
        }

        // Lepas keterkaitan mentor pada interns
        DB::table('interns')->where('mentor_user_id', $mentorId)->update(['mentor_user_id' => null]);

        DB::table('users')->where('id', $mentorId)->delete();

        $this->auditLog(
            actorUserId: (int) $user['user_id'],
            action: 'ADMIN_MENTOR_DELETE',
            entityType: 'users',
            entityId: (int) $mentorId,
            before: (array) $mentor,
            after: ['deleted' => true],
            reason: 'delete mentor'
        );

        return LegacyApiResponse::ok(['deleted' => true]);
    }

    public function createIntern(Request $request): JsonResponse
    {
        $user = $this->authAdmin($request);
        if ($user instanceof JsonResponse) {
            return $user;
        }

        $body = LegacyRequest::jsonBody($request, $invalidJson);
        if ($invalidJson) {
            return LegacyApiResponse::error('BAD_JSON', 'Body JSON tidak valid.', 400);
        }
        $missing = LegacyRequest::missingFields($body, ['fullName', 'unitId', 'internshipStart', 'internshipEnd', 'nisn']);
        if ($missing !== []) {
            return LegacyApiResponse::error('MISSING_FIELDS', 'Field wajib belum diisi.', 422, ['missing' => $missing]);
        }

        $emailInput = strtolower(trim((string) ($body['email'] ?? '')));
        $fullName = trim((string) $body['fullName']);
        $nisn = trim((string) $body['nisn']);
        $unitId = (int) $body['unitId'];
        $genderRaw = strtoupper(trim((string) ($body['gender'] ?? '')));
        $gender = $genderRaw === '' ? null : $genderRaw;
        $mentorUserId = array_key_exists('mentorUserId', $body)
            ? ($body['mentorUserId'] === null ? null : (int) $body['mentorUserId'])
            : null;
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
        if ($gender !== null && ! in_array($gender, ['L', 'P'], true)) {
            return LegacyApiResponse::error('BAD_INPUT', 'Gender harus L atau P.', 422);
        }
        $unitExists = DB::table('units')->where('id', $unitId)->exists();
        if (! $unitExists) {
            return LegacyApiResponse::error('NOT_FOUND', 'Unit tidak ditemukan.', 404);
        }
        if ($mentorUserId !== null) {
            $mentorExists = DB::table('users')
                ->where('id', $mentorUserId)
                ->where('role', 'PEMBIMBING')
                ->exists();
            if (! $mentorExists) {
                return LegacyApiResponse::error('NOT_FOUND', 'Pembimbing tidak ditemukan.', 404);
            }
        }
        $email = $emailInput === '' ? $nisn.'@intern.local' : $emailInput;
        $exists = DB::table('users')->where('email', $email)->exists();
        if ($exists) {
            return LegacyApiResponse::error('EMAIL_USED', 'Email sudah terdaftar.', 409);
        }
        $nisnUsed = DB::table('interns')->where('nisn', $nisn)->exists();
        if ($nisnUsed) {
            return LegacyApiResponse::error('NISN_USED', 'NISN sudah dipakai.', 409);
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
            'nisn' => $nisn,
            'gender' => $gender,
            'unit_id' => $unitId,
            'mentor_user_id' => $mentorUserId,
            'school_name' => $schoolName === '' ? null : $schoolName,
            'school_address' => $schoolAddress === '' ? null : $schoolAddress,
            'internship_start' => $start,
            'internship_end' => $end,
            'active' => 1,
        ]);

        $this->auditLog(
            actorUserId: (int) $user['user_id'],
            action: 'ADMIN_INTERN_CREATE',
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

    public function updateIntern(Request $request, int $userId): JsonResponse
    {
        $user = $this->authAdmin($request);
        if ($user instanceof JsonResponse) {
            return $user;
        }

        $body = LegacyRequest::jsonBody($request, $invalidJson);
        if ($invalidJson) {
            return LegacyApiResponse::error('BAD_JSON', 'Body JSON tidak valid.', 400);
        }

        $intern = DB::table('interns')->where('user_id', $userId)->first();
        if (! $intern) {
            return LegacyApiResponse::error('NOT_FOUND', 'Intern tidak ditemukan.', 404);
        }

        $fullName = array_key_exists('fullName', $body) ? trim((string) $body['fullName']) : DB::table('users')->where('id', $userId)->value('full_name');
        $nisn = array_key_exists('nisn', $body) ? trim((string) $body['nisn']) : (string) $intern->nisn;
        $gender = array_key_exists('gender', $body)
            ? strtoupper(trim((string) ($body['gender'] ?? '')))
            : strtoupper(trim((string) ($intern->gender ?? '')));
        $gender = $gender === '' ? null : $gender;
        $unitId = array_key_exists('unitId', $body) ? (int) $body['unitId'] : (int) $intern->unit_id;
        $mentorUserId = array_key_exists('mentorUserId', $body)
            ? ($body['mentorUserId'] === null ? null : (int) $body['mentorUserId'])
            : ($intern->mentor_user_id !== null ? (int) $intern->mentor_user_id : null);
        $schoolName = array_key_exists('schoolName', $body)
            ? trim((string) ($body['schoolName'] ?? ''))
            : (string) ($intern->school_name ?? '');
        $schoolAddress = array_key_exists('schoolAddress', $body)
            ? trim((string) ($body['schoolAddress'] ?? ''))
            : (string) ($intern->school_address ?? '');
        $start = (string) ($body['internshipStart'] ?? $intern->internship_start);
        $end = (string) ($body['internshipEnd'] ?? $intern->internship_end);
        $active = array_key_exists('active', $body) ? ((bool) $body['active'] ? 1 : 0) : (int) $intern->active;
        if ($start > $end) {
            return LegacyApiResponse::error('BAD_RANGE', 'internshipStart harus <= internshipEnd.', 422);
        }
        if ($gender !== null && ! in_array($gender, ['L', 'P'], true)) {
            return LegacyApiResponse::error('BAD_INPUT', 'Gender harus L atau P.', 422);
        }
        $unitExists = DB::table('units')->where('id', $unitId)->exists();
        if (! $unitExists) {
            return LegacyApiResponse::error('NOT_FOUND', 'Unit tidak ditemukan.', 404);
        }
        if ($mentorUserId !== null) {
            $mentorExists = DB::table('users')
                ->where('id', $mentorUserId)
                ->where('role', 'PEMBIMBING')
                ->exists();
            if (! $mentorExists) {
                return LegacyApiResponse::error('NOT_FOUND', 'Pembimbing tidak ditemukan.', 404);
            }
        }

        $nisnUsed = DB::table('interns')
            ->where('nisn', $nisn)
            ->where('user_id', '<>', $userId)
            ->exists();
        if ($nisnUsed) {
            return LegacyApiResponse::error('NISN_USED', 'NISN sudah dipakai.', 409);
        }

        DB::table('users')
            ->where('id', $userId)
            ->update(['full_name' => $fullName]);

        DB::table('interns')
            ->where('user_id', $userId)
            ->update([
                'nisn' => $nisn,
                'gender' => $gender,
                'unit_id' => $unitId,
                'mentor_user_id' => $mentorUserId,
                'school_name' => $schoolName === '' ? null : $schoolName,
                'school_address' => $schoolAddress === '' ? null : $schoolAddress,
                'internship_start' => $start,
                'internship_end' => $end,
                'active' => $active,
            ]);

        $this->auditLog(
            actorUserId: (int) $user['user_id'],
            action: 'ADMIN_INTERN_UPDATE',
            entityType: 'interns',
            entityId: $userId,
            before: (array) $intern,
            after: ['unitId' => $unitId, 'mentorUserId' => $mentorUserId, 'active' => $active],
            reason: 'update'
        );

        return LegacyApiResponse::ok(['ok' => true]);
    }

    public function toggleIntern(Request $request, int $userId, string $mode): JsonResponse
    {
        $user = $this->authAdmin($request);
        if ($user instanceof JsonResponse) {
            return $user;
        }

        $intern = DB::table('interns')->where('user_id', $userId)->first();
        if (! $intern) {
            return LegacyApiResponse::error('NOT_FOUND', 'Intern tidak ditemukan.', 404);
        }

        $activate = $mode === 'activate';
        $newActive = $activate ? 1 : 0;
        DB::table('interns')->where('user_id', $userId)->update(['active' => $newActive]);

        $this->auditLog(
            actorUserId: (int) $user['user_id'],
            action: $activate ? 'ADMIN_INTERN_ACTIVATE' : 'ADMIN_INTERN_DEACTIVATE',
            entityType: 'interns',
            entityId: $userId,
            before: (array) $intern,
            after: ['active' => $newActive],
            reason: 'toggle'
        );

        return LegacyApiResponse::ok(['active' => $activate]);
    }

    public function deleteIntern(Request $request, int $userId): JsonResponse
    {
        $user = $this->authAdmin($request);
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
            ->first();
        if (! $intern) {
            return LegacyApiResponse::error('NOT_FOUND', 'Intern tidak ditemukan.', 404);
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
            action: 'ADMIN_INTERN_DELETE',
            entityType: 'interns',
            entityId: $userId,
            before: (array) $intern,
            after: ['deleted' => true],
            reason: 'hard delete'
        );

        DB::table('users')->where('id', $userId)->delete();

        return LegacyApiResponse::ok(['deleted' => true]);
    }

    public function updateUnit(Request $request, int $unitId): JsonResponse
    {
        $user = $this->authAdmin($request);
        if ($user instanceof JsonResponse) {
            return $user;
        }

        $body = LegacyRequest::jsonBody($request, $invalidJson);
        if ($invalidJson) {
            return LegacyApiResponse::error('BAD_JSON', 'Body JSON tidak valid.', 400);
        }
        $missing = LegacyRequest::missingFields($body, ['name', 'geofenceLat', 'geofenceLon', 'geofenceRadiusM']);
        if ($missing !== []) {
            return LegacyApiResponse::error('MISSING_FIELDS', 'Field wajib belum diisi.', 422, ['missing' => $missing]);
        }

        $unit = DB::table('units')->where('id', $unitId)->first();
        if (! $unit) {
            return LegacyApiResponse::error('NOT_FOUND', 'Unit tidak ditemukan.', 404);
        }

        $name = trim((string) $body['name']);
        $lat = (float) $body['geofenceLat'];
        $lon = (float) $body['geofenceLon'];
        $radius = (int) $body['geofenceRadiusM'];
        if ($name === '') {
            return LegacyApiResponse::error('BAD_INPUT', 'Nama unit wajib diisi.', 422);
        }
        if ($lat < -90 || $lat > 90 || $lon < -180 || $lon > 180) {
            return LegacyApiResponse::error('BAD_INPUT', 'Koordinat lat/lon tidak valid.', 422);
        }
        if ($radius < 10 || $radius > 5000) {
            return LegacyApiResponse::error('BAD_INPUT', 'Radius harus 10..5000 meter.', 422);
        }

        DB::table('units')
            ->where('id', $unitId)
            ->update([
                'name' => $name,
                'geofence_lat' => $lat,
                'geofence_lon' => $lon,
                'geofence_radius_m' => $radius,
            ]);

        $this->auditLog(
            actorUserId: (int) $user['user_id'],
            action: 'ADMIN_UNIT_UPDATE',
            entityType: 'units',
            entityId: $unitId,
            before: (array) $unit,
            after: ['name' => $name, 'geofenceLat' => $lat, 'geofenceLon' => $lon, 'geofenceRadiusM' => $radius],
            reason: 'update geofence'
        );

        $updated = DB::table('units')->where('id', $unitId)->first();

        return LegacyApiResponse::ok((array) $updated);
    }

    public function createUnit(Request $request): JsonResponse
    {
        $user = $this->authAdmin($request);
        if ($user instanceof JsonResponse) {
            return $user;
        }

        $body = LegacyRequest::jsonBody($request, $invalidJson);
        if ($invalidJson) {
            return LegacyApiResponse::error('BAD_JSON', 'Body JSON tidak valid.', 400);
        }
        $missing = LegacyRequest::missingFields($body, ['name', 'geofenceLat', 'geofenceLon', 'geofenceRadiusM']);
        if ($missing !== []) {
            return LegacyApiResponse::error('MISSING_FIELDS', 'Field wajib belum diisi.', 422, ['missing' => $missing]);
        }

        $name = trim((string) $body['name']);
        $lat = (float) $body['geofenceLat'];
        $lon = (float) $body['geofenceLon'];
        $radius = (int) $body['geofenceRadiusM'];
        if ($name === '') {
            return LegacyApiResponse::error('BAD_INPUT', 'Nama unit wajib diisi.', 422);
        }
        if ($lat < -90 || $lat > 90 || $lon < -180 || $lon > 180) {
            return LegacyApiResponse::error('BAD_INPUT', 'Koordinat lat/lon tidak valid.', 422);
        }
        if ($radius < 10 || $radius > 5000) {
            return LegacyApiResponse::error('BAD_INPUT', 'Radius harus 10..5000 meter.', 422);
        }

        $id = DB::table('units')->insertGetId([
            'name' => $name,
            'geofence_lat' => $lat,
            'geofence_lon' => $lon,
            'geofence_radius_m' => $radius,
        ]);

        $this->auditLog(
            actorUserId: (int) $user['user_id'],
            action: 'ADMIN_UNIT_CREATE',
            entityType: 'units',
            entityId: $id,
            before: [],
            after: ['name' => $name, 'geofenceLat' => $lat, 'geofenceLon' => $lon, 'geofenceRadiusM' => $radius],
            reason: 'create unit'
        );

        $created = DB::table('units')->where('id', $id)->first();

        return LegacyApiResponse::ok((array) $created, 201);
    }

    public function deleteUnit(Request $request, int $unitId): JsonResponse
    {
        $user = $this->authAdmin($request);
        if ($user instanceof JsonResponse) {
            return $user;
        }

        $unit = DB::table('units')->where('id', $unitId)->first();
        if (! $unit) {
            return LegacyApiResponse::error('NOT_FOUND', 'Unit tidak ditemukan.', 404);
        }

        // Cegah hapus jika masih dipakai oleh attendance/intern/device
        $hasAttendance = DB::table('attendance_records')->where('unit_id', $unitId)->exists();
        $hasInterns = DB::table('interns')->where('unit_id', $unitId)->exists();
        $hasDevices = Schema::hasTable('devices')
            ? DB::table('devices')->where('unit_id', $unitId)->exists()
            : false;
        if ($hasAttendance || $hasInterns || $hasDevices) {
            return LegacyApiResponse::error(
                'UNIT_IN_USE',
                'Unit tidak bisa dihapus karena masih dipakai oleh data absensi/intern/perangkat.',
                409
            );
        }

        $deleted = DB::table('units')->where('id', $unitId)->delete();
        if (! $deleted) {
            return LegacyApiResponse::error('DELETE_FAILED', 'Unit gagal dihapus.', 500);
        }

        $this->auditLog(
            actorUserId: (int) $user['user_id'],
            action: 'ADMIN_UNIT_DELETE',
            entityType: 'units',
            entityId: $unitId,
            before: (array) $unit,
            after: ['deleted' => true],
            reason: 'delete unit'
        );

        return LegacyApiResponse::ok(['deleted' => true]);
    }

    public function devices(Request $request): JsonResponse
    {
        $user = $this->authAdmin($request);
        if ($user instanceof JsonResponse) {
            return $user;
        }

        $settings = $this->getSettings();
        $offline = (int) ($settings['offline_threshold_seconds'] ?? self::DEFAULT_OFFLINE_THRESHOLD_SECONDS);
        $now = CarbonImmutable::now(self::APP_TIMEZONE);

        $rows = DB::table('devices as d')
            ->join('units as u', 'u.id', '=', 'd.unit_id')
            ->select(['d.id', 'd.unit_id', 'u.name as unit_name', 'd.name', 'd.last_seen_at'])
            ->orderByDesc('d.id')
            ->get();

        $out = $rows->map(function (object $row) use ($offline, $now): array {
            $last = $row->last_seen_at ? CarbonImmutable::parse($row->last_seen_at, self::APP_TIMEZONE) : null;
            $online = $last ? ($now->getTimestamp() - $last->getTimestamp()) <= $offline : false;

            return [
                'id' => (int) $row->id,
                'unitId' => (int) $row->unit_id,
                'unitName' => $row->unit_name,
                'name' => $row->name,
                'lastSeenAt' => $row->last_seen_at,
                'online' => $online,
            ];
        })->all();

        return LegacyApiResponse::ok($out);
    }

    public function recap(Request $request): JsonResponse
    {
        $user = $this->authAdmin($request);
        if ($user instanceof JsonResponse) {
            return $user;
        }

        $dateFrom = (string) $request->query('dateFrom', CarbonImmutable::now(self::APP_TIMEZONE)->format('Y-m-d'));
        $dateTo = (string) $request->query('dateTo', CarbonImmutable::now(self::APP_TIMEZONE)->format('Y-m-d'));
        $schoolName = trim((string) $request->query('schoolName', ''));
        $internUserId = $request->query('internUserId');
        if ($dateFrom > $dateTo) {
            return LegacyApiResponse::error('BAD_RANGE', 'dateFrom harus <= dateTo.', 422);
        }
        $internUserId = $request->query('internUserId');

        $query = DB::table('attendance_records as ar')
            ->join('users as u', 'u.id', '=', 'ar.intern_user_id')
            ->leftJoin('units as un', 'un.id', '=', 'ar.unit_id')
            ->join('interns as i', 'i.user_id', '=', 'ar.intern_user_id')
            ->select([
                'ar.*',
                'u.full_name',
                'un.name as unit_name',
                'i.school_name',
                'i.gender',
            ])
            ->whereBetween('ar.date', [$dateFrom, $dateTo]);
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
            'unitName' => $row->unit_name ?? '-',
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
        $user = $this->authAdmin($request);
        if ($user instanceof JsonResponse) {
            return $user;
        }

        $format = strtolower((string) $request->query('format', 'csv'));
        if (! in_array($format, ['csv', 'xlsx'], true)) {
            return LegacyApiResponse::error('BAD_FORMAT', 'Format export harus csv atau xlsx.', 422);
        }
        $dateFrom = (string) $request->query('dateFrom', CarbonImmutable::now(self::APP_TIMEZONE)->format('Y-m-d'));
        $dateTo = (string) $request->query('dateTo', CarbonImmutable::now(self::APP_TIMEZONE)->format('Y-m-d'));
        $schoolName = trim((string) $request->query('schoolName', ''));
        $internUserId = $request->query('internUserId');
        if ($dateFrom > $dateTo) {
            return LegacyApiResponse::error('BAD_RANGE', 'dateFrom harus <= dateTo.', 422);
        }
        $exportDateFrom = $dateFrom;
        $exportDateTo = $dateTo;
        if ($format === 'xlsx') {
            [$exportDateFrom, $exportDateTo] = RecapExcelExporter::normalizeMonthlyRange(
                dateFrom: $dateFrom,
                dateTo: $dateTo,
                timezone: self::APP_TIMEZONE
            );
        }

        $query = DB::table('interns as i')
            ->join('users as u', 'u.id', '=', 'i.user_id')
            ->leftJoin('units as un', 'un.id', '=', 'i.unit_id')
            ->leftJoin('attendance_records as ar', function ($join) use ($exportDateFrom, $exportDateTo): void {
                $join->on('ar.intern_user_id', '=', 'i.user_id')
                    ->whereBetween('ar.date', [$exportDateFrom, $exportDateTo]);
            })
            ->select([
                'ar.date',
                'ar.intern_user_id',
                'i.user_id',
                'u.full_name',
                'u.email',
                'i.nisn',
                'i.gender',
                'i.school_name',
                'i.internship_start',
                'i.internship_end',
                'un.name as unit_name',
                'ar.status',
                'ar.status_marked_by',
                'ar.check_in_at',
                'ar.check_out_at',
                'ar.checkout_missing',
            ])
            ->orderBy('u.full_name')
            ->orderByDesc('ar.date');
        if ($internUserId !== null && (int) $internUserId > 0) {
            $query->where('i.user_id', (int) $internUserId);
        }
        if ($schoolName !== '') {
            $query->where('i.school_name', $schoolName);
        }
        $rows = $query->get()->map(function (object $row): object {
            $data = (array) $row;
            if (! array_key_exists('intern_user_id', $data) || $data['intern_user_id'] === null) {
                $data['intern_user_id'] = (int) ($data['user_id'] ?? 0);
            }
            if (! array_key_exists('unit_name', $data) || $data['unit_name'] === null || $data['unit_name'] === '') {
                $data['unit_name'] = '-';
            }

            return (object) $data;
        });
        $filename = $this->buildRecapExportFilename(
            dateFrom: $exportDateFrom,
            dateTo: $exportDateTo,
            schoolName: $schoolName,
            format: $format
        );

        if ($format === 'xlsx') {
            $spreadsheet = RecapExcelExporter::build(
                rows: $rows,
                dateFrom: $exportDateFrom,
                dateTo: $exportDateTo,
                timezone: self::APP_TIMEZONE
            );

            return response()->streamDownload(function () use ($spreadsheet): void {
                $writer = new Xlsx($spreadsheet);
                $writer->save('php://output');
                $spreadsheet->disconnectWorksheets();
                unset($spreadsheet);
            }, $filename, [
                'Content-Type' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            ]);
        }

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
        }, $filename, ['Content-Type' => 'text/csv; charset=utf-8']);
    }

    public function finalizeDay(Request $request): JsonResponse
    {
        $user = $this->authAdmin($request);
        if ($user instanceof JsonResponse) {
            return $user;
        }

        $body = LegacyRequest::jsonBody($request, $invalidJson);
        if ($invalidJson) {
            return LegacyApiResponse::error('BAD_JSON', 'Body JSON tidak valid.', 400);
        }

        $date = (string) ($body['date'] ?? '');
        if ($date === '') {
            return LegacyApiResponse::error('MISSING_FIELDS', 'date wajib diisi (YYYY-MM-DD).', 422);
        }

        $target = CarbonImmutable::parse($date.' 00:00:00', self::APP_TIMEZONE);
        $today = CarbonImmutable::parse(CarbonImmutable::now(self::APP_TIMEZONE)->format('Y-m-d').' 00:00:00', self::APP_TIMEZONE);
        if ($target->greaterThanOrEqualTo($today)) {
            return LegacyApiResponse::error('INVALID_DATE', 'Finalize hanya untuk tanggal sebelum hari ini.', 409);
        }

        DB::table('attendance_records')
            ->where('date', $date)
            ->whereNotNull('check_in_at')
            ->whereNull('check_out_at')
            ->update([
                'checkout_missing' => 1,
                'updated_at' => CarbonImmutable::now(self::APP_TIMEZONE)->format('Y-m-d H:i:s'),
            ]);

        $interns = DB::table('interns')
            ->select(['user_id', 'unit_id'])
            ->where('active', 1)
            ->get();
        $created = 0;
        foreach ($interns as $intern) {
            $uid = (int) $intern->user_id;
            $exists = DB::table('attendance_records')
                ->where('intern_user_id', $uid)
                ->where('date', $date)
                ->exists();
            if ($exists) {
                continue;
            }

            $leave = DB::table('leave_requests')
                ->select(['id', 'type'])
                ->where('intern_user_id', $uid)
                ->where('status', 'APPROVED')
                ->where('date_from', '<=', $date)
                ->where('date_to', '>=', $date)
                ->first();
            if ($leave) {
                DB::table('attendance_records')->insert([
                    'intern_user_id' => $uid,
                    'unit_id' => (int) $intern->unit_id,
                    'date' => $date,
                    'status' => $leave->type,
                    'status_marked_by' => 'SYSTEM',
                    'checkout_missing' => 0,
                    'created_at' => CarbonImmutable::now(self::APP_TIMEZONE)->format('Y-m-d H:i:s'),
                    'updated_at' => CarbonImmutable::now(self::APP_TIMEZONE)->format('Y-m-d H:i:s'),
                ]);
                $created++;
                continue;
            }

            DB::table('attendance_records')->insert([
                'intern_user_id' => $uid,
                'unit_id' => (int) $intern->unit_id,
                'date' => $date,
                'status' => 'ALPA',
                'status_marked_by' => 'SYSTEM',
                'checkout_missing' => 0,
                'created_at' => CarbonImmutable::now(self::APP_TIMEZONE)->format('Y-m-d H:i:s'),
                'updated_at' => CarbonImmutable::now(self::APP_TIMEZONE)->format('Y-m-d H:i:s'),
            ]);
            $created++;
        }

        return LegacyApiResponse::ok([
            'date' => $date,
            'createdOrFilled' => $created,
        ]);
    }

    private function authAdmin(Request $request): array|JsonResponse
    {
        $user = $request->attributes->get('auth_user');
        if (! is_array($user)) {
            return LegacyApiResponse::error('UNAUTHENTICATED', 'Butuh login.', 401);
        }
        if (($user['role'] ?? null) !== 'ADMIN') {
            return LegacyApiResponse::error('FORBIDDEN', 'Akses ditolak.', 403);
        }

        return $user;
    }

    private function getSettings(): array
    {
        $row = DB::table('settings')->where('id', 1)->first();
        if (! $row) {
            return [
                'timezone' => self::APP_TIMEZONE,
                'work_start_time' => self::DEFAULT_WORK_START_TIME,
                'work_end_time' => self::DEFAULT_WORK_END_TIME,
                'tolerance_minutes' => self::DEFAULT_TOLERANCE_MINUTES,
                'day_cutoff_time' => self::DEFAULT_DAY_CUTOFF_TIME,
                'workdays_json' => self::DEFAULT_WORKDAYS_JSON,
                'offline_threshold_seconds' => self::DEFAULT_OFFLINE_THRESHOLD_SECONDS,
                'qr_token_ttl_seconds' => self::DEFAULT_QR_TTL_SECONDS,
            ];
        }

        $arr = (array) $row;
        $arr += [
            'timezone' => self::APP_TIMEZONE,
            'work_start_time' => self::DEFAULT_WORK_START_TIME,
            'work_end_time' => self::DEFAULT_WORK_END_TIME,
            'tolerance_minutes' => self::DEFAULT_TOLERANCE_MINUTES,
            'day_cutoff_time' => self::DEFAULT_DAY_CUTOFF_TIME,
            'workdays_json' => self::DEFAULT_WORKDAYS_JSON,
            'offline_threshold_seconds' => self::DEFAULT_OFFLINE_THRESHOLD_SECONDS,
            'qr_token_ttl_seconds' => self::DEFAULT_QR_TTL_SECONDS,
        ];
        if (! array_key_exists('work_end_time', $arr) || $arr['work_end_time'] === null || $arr['work_end_time'] === '') {
            $arr['work_end_time'] = self::DEFAULT_WORK_END_TIME;
        }
        if (! array_key_exists('day_cutoff_time', $arr) || $arr['day_cutoff_time'] === null || $arr['day_cutoff_time'] === '') {
            $arr['day_cutoff_time'] = self::DEFAULT_DAY_CUTOFF_TIME;
        }

        return $arr;
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

    private function buildRecapExportFilename(
        string $dateFrom,
        string $dateTo,
        string $schoolName,
        string $format,
    ): string {
        $ext = strtolower($format) === 'xlsx' ? 'xlsx' : 'csv';
        $datePart = $dateFrom === $dateTo ? $dateFrom : "{$dateFrom}_{$dateTo}";
        $schoolPart = trim($schoolName);

        if ($schoolPart === '') {
            return "rekap_absen_{$datePart}_keseluruhan.{$ext}";
        }

        return "rekap_absen_{$this->slugForFilename($schoolPart)}_{$datePart}.{$ext}";
    }

    private function slugForFilename(string $value): string
    {
        $clean = preg_replace('/[\\\\\\/:"*?<>|]+/', '', trim($value)) ?? '';
        $clean = preg_replace('/\s+/', '_', $clean) ?? '';
        $clean = trim($clean, '_');
        if ($clean === '') {
            return 'sekolah';
        }

        return strlen($clean) > 60 ? substr($clean, 0, 60) : $clean;
    }
}
