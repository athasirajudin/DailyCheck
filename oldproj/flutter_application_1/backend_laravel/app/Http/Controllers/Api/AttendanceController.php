<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Support\LegacyApiResponse;
use App\Support\LegacyRequest;
use Carbon\CarbonImmutable;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AttendanceController extends Controller
{
    private const APP_TIMEZONE = 'Asia/Jakarta';
    private const DEFAULT_WORK_START_TIME = '09:00:00';
    private const DEFAULT_TOLERANCE_MINUTES = 15;
    private const DEFAULT_WORKDAYS_JSON = '[1,2,3,4,5]';

    public function internToday(Request $request): JsonResponse
    {
        $user = $request->attributes->get('auth_user');
        if (! is_array($user)) {
            return LegacyApiResponse::error('UNAUTHENTICATED', 'Butuh login.', 401);
        }

        $intern = DB::table('interns as i')
            ->join('units as u', 'u.id', '=', 'i.unit_id')
            ->select(['i.unit_id', 'u.name as unit_name', 'i.internship_start', 'i.internship_end', 'i.active'])
            ->where('i.user_id', (int) $user['user_id'])
            ->first();
        if (! $intern) {
            return LegacyApiResponse::error('NOT_FOUND', 'Data intern belum terdaftar.', 404);
        }

        $today = CarbonImmutable::now(self::APP_TIMEZONE)->format('Y-m-d');
        $rec = DB::table('attendance_records')
            ->where('intern_user_id', (int) $user['user_id'])
            ->where('date', $today)
            ->first();

        return LegacyApiResponse::ok([
            'date' => $today,
            'unit' => [
                'id' => (int) $intern->unit_id,
                'name' => $intern->unit_name,
            ],
            'attendance' => $rec ? $this->attendanceToDto($rec) : null,
        ]);
    }

    public function check(Request $request): JsonResponse
    {
        $user = $request->attributes->get('auth_user');
        if (! is_array($user)) {
            return LegacyApiResponse::error('UNAUTHENTICATED', 'Butuh login.', 401);
        }

        $body = LegacyRequest::jsonBody($request, $invalidJson);
        if ($invalidJson) {
            return LegacyApiResponse::error('BAD_JSON', 'Body JSON tidak valid.', 400);
        }

        $missing = LegacyRequest::missingFields($body, ['qrToken', 'action', 'lat', 'lon']);
        if ($missing !== []) {
            return LegacyApiResponse::error('MISSING_FIELDS', 'Field wajib belum diisi.', 422, ['missing' => $missing]);
        }

        $action = strtolower(trim((string) $body['action']));
        if (! in_array($action, ['checkin', 'checkout'], true)) {
            return LegacyApiResponse::error('BAD_ACTION', 'Action harus "checkin" atau "checkout".', 422);
        }

        $qrToken = strtoupper(trim((string) $body['qrToken']));
        $lat = (float) $body['lat'];
        $lon = (float) $body['lon'];
        $now = CarbonImmutable::now(self::APP_TIMEZONE);

        if (! $this->isWorkday($now)) {
            return LegacyApiResponse::error('NOT_WORKDAY', 'Hari ini bukan hari kerja / hari libur.', 409);
        }

        $intern = DB::table('interns')
            ->select(['unit_id', 'internship_start', 'internship_end', 'active'])
            ->where('user_id', (int) $user['user_id'])
            ->first();
        if (! $intern || (int) $intern->active !== 1) {
            return LegacyApiResponse::error('INTERN_INACTIVE', 'Intern tidak aktif.', 403);
        }

        $start = CarbonImmutable::parse((string) $intern->internship_start, self::APP_TIMEZONE);
        $end = CarbonImmutable::parse((string) $intern->internship_end, self::APP_TIMEZONE);
        if ($now->lessThan($start) || $now->greaterThan($end)) {
            return LegacyApiResponse::error('OUTSIDE_PERIOD', 'Di luar periode PKL/magang.', 403);
        }

        $qr = DB::table('qr_sessions as qs')
            ->join('devices as d', 'd.id', '=', 'qs.device_id')
            ->join('units as u', 'u.id', '=', 'd.unit_id')
            ->select([
                'qs.id',
                'qs.device_id',
                'qs.expires_at',
                'qs.active',
                'd.unit_id',
                'u.geofence_lat',
                'u.geofence_lon',
                'u.geofence_radius_m',
            ])
            ->where('qs.token', $qrToken)
            ->first();
        if (! $qr) {
            return LegacyApiResponse::error('QR_INVALID', 'QR token tidak ditemukan.', 400);
        }
        if ((int) $qr->active !== 1) {
            return LegacyApiResponse::error('QR_EXPIRED', 'QR token sudah tidak aktif.', 409);
        }

        $qrExpires = CarbonImmutable::parse((string) $qr->expires_at, self::APP_TIMEZONE);
        if ($qrExpires->lessThanOrEqualTo($now)) {
            DB::table('qr_sessions')
                ->where('id', (int) $qr->id)
                ->update([
                    'active' => 0,
                    'deactivated_at' => $now->format('Y-m-d H:i:s'),
                ]);

            return LegacyApiResponse::error('QR_EXPIRED', 'QR token sudah kedaluwarsa.', 409);
        }

        $internUnitId = (int) $intern->unit_id;
        $unitId = (int) $qr->unit_id;
        if ($internUnitId !== $unitId) {
            return LegacyApiResponse::error('UNIT_MISMATCH', 'QR token bukan untuk unit kamu.', 403);
        }

        $distance = $this->haversineM(
            $lat,
            $lon,
            (float) $qr->geofence_lat,
            (float) $qr->geofence_lon
        );
        $radius = (int) $qr->geofence_radius_m;
        if ($distance > $radius) {
            return LegacyApiResponse::error('OUT_OF_AREA', 'Di luar area geofence.', 403, [
                'distanceM' => $distance,
                'radiusM' => $radius,
                'yourLat' => $lat,
                'yourLon' => $lon,
                'unitLat' => (float) $qr->geofence_lat,
                'unitLon' => (float) $qr->geofence_lon,
            ]);
        }

        $date = $now->format('Y-m-d');
        $rec = DB::table('attendance_records')
            ->where('intern_user_id', (int) $user['user_id'])
            ->where('date', $date)
            ->first();

        $settings = $this->getSettings();
        $workStart = (string) ($settings['work_start_time'] ?? self::DEFAULT_WORK_START_TIME);
        $tolMin = (int) ($settings['tolerance_minutes'] ?? self::DEFAULT_TOLERANCE_MINUTES);
        $startDt = CarbonImmutable::parse($date.' '.$workStart, self::APP_TIMEZONE);
        $limit = $startDt->addMinutes($tolMin);

        if ($action === 'checkin') {
            if ($rec && $rec->check_in_at !== null) {
                return LegacyApiResponse::error('ALREADY_CHECKED_IN', 'Kamu sudah check-in hari ini.', 409);
            }

            $status = $now->lessThanOrEqualTo($limit) ? 'HADIR' : 'TERLAMBAT';
            if ($rec) {
                DB::table('attendance_records')
                    ->where('id', (int) $rec->id)
                    ->update([
                        'check_in_at' => $now->format('Y-m-d H:i:s'),
                        'status' => $status,
                        'status_marked_by' => 'SYSTEM',
                        'gps_check_in_lat' => $lat,
                        'gps_check_in_lon' => $lon,
                        'updated_at' => $now->format('Y-m-d H:i:s'),
                    ]);

                $rec = DB::table('attendance_records')->where('id', (int) $rec->id)->first();
            } else {
                $newId = DB::table('attendance_records')->insertGetId([
                    'intern_user_id' => (int) $user['user_id'],
                    'unit_id' => $unitId,
                    'date' => $date,
                    'check_in_at' => $now->format('Y-m-d H:i:s'),
                    'status' => $status,
                    'status_marked_by' => 'SYSTEM',
                    'gps_check_in_lat' => $lat,
                    'gps_check_in_lon' => $lon,
                    'checkout_missing' => 0,
                    'created_at' => $now->format('Y-m-d H:i:s'),
                    'updated_at' => $now->format('Y-m-d H:i:s'),
                ]);

                $rec = DB::table('attendance_records')->where('id', (int) $newId)->first();
            }

            return LegacyApiResponse::ok([
                'attendance' => $this->attendanceToDto($rec),
                'result' => ['status' => $status],
            ]);
        }

        if (! $rec || $rec->check_in_at === null) {
            return LegacyApiResponse::error('NO_CHECKIN', 'Belum ada check-in hari ini.', 409);
        }
        if ($rec->check_out_at !== null) {
            return LegacyApiResponse::error('ALREADY_CHECKED_OUT', 'Kamu sudah check-out hari ini.', 409);
        }

        DB::table('attendance_records')
            ->where('id', (int) $rec->id)
            ->update([
                'check_out_at' => $now->format('Y-m-d H:i:s'),
                'gps_check_out_lat' => $lat,
                'gps_check_out_lon' => $lon,
                'checkout_missing' => 0,
                'updated_at' => $now->format('Y-m-d H:i:s'),
            ]);

        $rec = DB::table('attendance_records')->where('id', (int) $rec->id)->first();

        return LegacyApiResponse::ok([
            'attendance' => $this->attendanceToDto($rec),
            'result' => ['status' => $rec->status],
        ]);
    }

    public function leaveRequest(Request $request): JsonResponse
    {
        $user = $request->attributes->get('auth_user');
        if (! is_array($user)) {
            return LegacyApiResponse::error('UNAUTHENTICATED', 'Butuh login.', 401);
        }

        $body = LegacyRequest::jsonBody($request, $invalidJson);
        if ($invalidJson) {
            return LegacyApiResponse::error('BAD_JSON', 'Body JSON tidak valid.', 400);
        }

        $missing = LegacyRequest::missingFields($body, ['type', 'dateFrom', 'dateTo', 'reason']);
        if ($missing !== []) {
            return LegacyApiResponse::error('MISSING_FIELDS', 'Field wajib belum diisi.', 422, ['missing' => $missing]);
        }

        $type = strtoupper(trim((string) $body['type']));
        if (! in_array($type, ['IZIN', 'SAKIT'], true)) {
            return LegacyApiResponse::error('BAD_TYPE', 'Type harus IZIN atau SAKIT.', 422);
        }

        $dateFrom = (string) $body['dateFrom'];
        $dateTo = (string) $body['dateTo'];
        $reason = trim((string) $body['reason']);
        $attachmentUrl = trim((string) ($body['attachmentUrl'] ?? ''));
        if ($dateFrom > $dateTo) {
            return LegacyApiResponse::error('BAD_RANGE', 'dateFrom harus <= dateTo.', 422);
        }

        $now = CarbonImmutable::now(self::APP_TIMEZONE)->format('Y-m-d H:i:s');
        $newId = DB::table('leave_requests')->insertGetId([
            'intern_user_id' => (int) $user['user_id'],
            'type' => $type,
            'date_from' => $dateFrom,
            'date_to' => $dateTo,
            'reason' => $reason,
            'attachment_url' => ($attachmentUrl === '' ? null : $attachmentUrl),
            'status' => 'PENDING',
            'created_at' => $now,
        ]);

        $row = DB::table('leave_requests')->where('id', (int) $newId)->first();

        return LegacyApiResponse::ok([
            'leave' => $row,
        ], 201);
    }

    private function getSettings(): array
    {
        $row = DB::table('settings')->where('id', 1)->first();
        if (! $row) {
            return [
                'work_start_time' => self::DEFAULT_WORK_START_TIME,
                'tolerance_minutes' => self::DEFAULT_TOLERANCE_MINUTES,
                'workdays_json' => self::DEFAULT_WORKDAYS_JSON,
            ];
        }

        return (array) $row;
    }

    private function isWorkday(CarbonImmutable $dt): bool
    {
        $settings = $this->getSettings();
        $weekday = (int) $dt->format('N');
        $workdays = json_decode((string) ($settings['workdays_json'] ?? self::DEFAULT_WORKDAYS_JSON), true);
        if (! is_array($workdays) || ! in_array($weekday, $workdays, true)) {
            return false;
        }

        $ymd = $dt->format('Y-m-d');
        $holiday = DB::table('holidays')->where('date', $ymd)->first();

        return $holiday === null;
    }

    private function haversineM(float $lat1, float $lon1, float $lat2, float $lon2): float
    {
        $r = 6371000.0;
        $dLat = deg2rad($lat2 - $lat1);
        $dLon = deg2rad($lon2 - $lon1);
        $a = sin($dLat / 2) ** 2 + cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * sin($dLon / 2) ** 2;
        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));

        return $r * $c;
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
}
