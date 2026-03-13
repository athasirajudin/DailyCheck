<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Support\LegacyApiResponse;
use App\Support\LegacyRequest;
use App\Support\OneSignalPushService;
use Carbon\CarbonImmutable;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class AttendanceController extends Controller
{
    private const APP_TIMEZONE = 'Asia/Jakarta';
    private const DEFAULT_WORK_START_TIME = '09:00:00';
    private const DEFAULT_WORK_END_TIME = '17:00:00';
    private const DEFAULT_TOLERANCE_MINUTES = 15;
    private const DEFAULT_DAY_CUTOFF_TIME = '23:59:59';
    private const DEFAULT_WORKDAYS_JSON = '[1,2,3,4,5]';

    public function internToday(Request $request): JsonResponse
    {
        $user = $request->attributes->get('auth_user');
        if (! is_array($user)) {
            return LegacyApiResponse::error('UNAUTHENTICATED', 'Butuh login.', 401);
        }

        $intern = DB::table('interns as i')
            ->join('units as u', 'u.id', '=', 'i.unit_id')
            ->select([
                'i.unit_id',
                'u.name as unit_name',
                'u.geofence_lat',
                'u.geofence_lon',
                'u.geofence_radius_m',
                'i.internship_start',
                'i.internship_end',
                'i.active',
            ])
            ->where('i.user_id', (int) $user['user_id'])
            ->first();
        if (! $intern) {
            return LegacyApiResponse::error('NOT_FOUND', 'Data intern belum terdaftar.', 404);
        }

        $now = CarbonImmutable::now(self::APP_TIMEZONE);
        $today = $now->format('Y-m-d');
        $rec = DB::table('attendance_records')
            ->where('intern_user_id', (int) $user['user_id'])
            ->where('date', $today)
            ->first();

        $settings = $this->getSettings();
        $windows = $this->computeWindows($now, $settings);

        return LegacyApiResponse::ok([
            'date' => $today,
            'unit' => [
                'id' => (int) $intern->unit_id,
                'name' => $intern->unit_name,
                'geofence' => [
                    'lat' => (float) $intern->geofence_lat,
                    'lon' => (float) $intern->geofence_lon,
                    'radiusM' => (int) $intern->geofence_radius_m,
                ],
            ],
            'attendance' => $rec ? $this->attendanceToDto($rec) : null,
            'availability' => [
                'checkin' => [
                    'open' => $windows['checkin']['isOpen'],
                    'opensAt' => $windows['checkin']['openAt']->format('Y-m-d H:i:s'),
                    'closesAt' => $windows['checkin']['closeAt']->format('Y-m-d H:i:s'),
                ],
                'checkout' => [
                    'open' => $windows['checkout']['isOpen'],
                    'opensAt' => $windows['checkout']['openAt']->format('Y-m-d H:i:s'),
                    'closesAt' => $windows['checkout']['closeAt']->format('Y-m-d H:i:s'),
                ],
            ],
            'serverTime' => $now->format('Y-m-d H:i:s'),
            'timezone' => (string) ($settings['timezone'] ?? self::APP_TIMEZONE),
            'isWorkday' => $this->isWorkday($now),
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

        $missing = LegacyRequest::missingFields($body, ['action', 'lat', 'lon']);
        if ($missing !== []) {
            return LegacyApiResponse::error('MISSING_FIELDS', 'Field wajib belum diisi.', 422, ['missing' => $missing]);
        }

        $action = strtolower(trim((string) $body['action']));
        if (! in_array($action, ['checkin', 'checkout'], true)) {
            return LegacyApiResponse::error('BAD_ACTION', 'Action harus "checkin" atau "checkout".', 422);
        }

        $lat = (float) $body['lat'];
        $lon = (float) $body['lon'];
        $now = CarbonImmutable::now(self::APP_TIMEZONE);

        if (! $this->isWorkday($now)) {
            return LegacyApiResponse::error('NOT_WORKDAY', 'Hari ini bukan hari kerja / hari libur.', 409);
        }

        $intern = DB::table('interns as i')
            ->join('units as u', 'u.id', '=', 'i.unit_id')
            ->select([
                'i.unit_id',
                'i.internship_start',
                'i.internship_end',
                'i.active',
                'u.geofence_lat',
                'u.geofence_lon',
                'u.geofence_radius_m',
            ])
            ->where('i.user_id', (int) $user['user_id'])
            ->first();
        if (! $intern || (int) $intern->active !== 1) {
            return LegacyApiResponse::error('INTERN_INACTIVE', 'Intern tidak aktif.', 403);
        }

        $start = CarbonImmutable::parse((string) $intern->internship_start, self::APP_TIMEZONE);
        $end = CarbonImmutable::parse((string) $intern->internship_end, self::APP_TIMEZONE);
        if ($now->lessThan($start) || $now->greaterThan($end)) {
            return LegacyApiResponse::error('OUTSIDE_PERIOD', 'Di luar periode PKL/magang.', 403);
        }

        $distance = $this->haversineM($lat, $lon, (float) $intern->geofence_lat, (float) $intern->geofence_lon);
        $radius = (int) $intern->geofence_radius_m;
        if ($distance > $radius) {
            return LegacyApiResponse::error('OUT_OF_AREA', 'Di luar area geofence.', 403, [
                'distanceM' => $distance,
                'radiusM' => $radius,
                'yourLat' => $lat,
                'yourLon' => $lon,
                'unitLat' => (float) $intern->geofence_lat,
                'unitLon' => (float) $intern->geofence_lon,
            ]);
        }

        $date = $now->format('Y-m-d');
        $rec = DB::table('attendance_records')
            ->where('intern_user_id', (int) $user['user_id'])
            ->where('date', $date)
            ->first();

        $settings = $this->getSettings();
        $windows = $this->computeWindows($now, $settings);
        if ($action === 'checkin' && ! $windows['checkin']['isOpen']) {
            return LegacyApiResponse::error('CHECKIN_CLOSED', 'Belum/diluar jam check-in.', 403, [
                'opensAt' => $windows['checkin']['openAt']->format('Y-m-d H:i:s'),
                'closesAt' => $windows['checkin']['closeAt']->format('Y-m-d H:i:s'),
                'timezone' => (string) ($settings['timezone'] ?? self::APP_TIMEZONE),
            ]);
        }
        if ($action === 'checkout' && ! $windows['checkout']['isOpen']) {
            return LegacyApiResponse::error('CHECKOUT_CLOSED', 'Belum/diluar jam check-out.', 403, [
                'opensAt' => $windows['checkout']['openAt']->format('Y-m-d H:i:s'),
                'closesAt' => $windows['checkout']['closeAt']->format('Y-m-d H:i:s'),
                'timezone' => (string) ($settings['timezone'] ?? self::APP_TIMEZONE),
            ]);
        }

        $unitId = (int) $intern->unit_id;

        if ($action === 'checkin') {
            if ($rec && $rec->check_in_at !== null) {
                return LegacyApiResponse::error('ALREADY_CHECKED_IN', 'Kamu sudah check-in hari ini.', 409);
            }

            // Mode absensi tanpa status terlambat: check-in valid selalu HADIR.
            $status = 'HADIR';
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

        $dateFromRaw = (string) $body['dateFrom'];
        $dateToRaw = (string) $body['dateTo'];
        $dateFromParsed = $this->parseIsoDate($dateFromRaw);
        $dateToParsed = $this->parseIsoDate($dateToRaw);
        if ($dateFromParsed === null || $dateToParsed === null) {
            return LegacyApiResponse::error(
                'BAD_DATE',
                'Format tanggal harus valid (YYYY-MM-DD).',
                422
            );
        }
        $dateFrom = $dateFromParsed->format('Y-m-d');
        $dateTo = $dateToParsed->format('Y-m-d');
        $reason = trim((string) $body['reason']);
        $attachmentBase64 = trim((string) ($body['attachmentBase64'] ?? ''));
        $attachmentName = trim((string) ($body['attachmentName'] ?? ''));
        if ($dateFrom > $dateTo) {
            return LegacyApiResponse::error('BAD_RANGE', 'dateFrom harus <= dateTo.', 422);
        }
        if ($type === 'SAKIT' && $attachmentBase64 === '') {
            return LegacyApiResponse::error('ATTACHMENT_REQUIRED', 'Gambar belum diupload.', 422);
        }
        $intern = DB::table('interns')
            ->select(['mentor_user_id'])
            ->where('user_id', (int) $user['user_id'])
            ->first();
        if (! $intern) {
            return LegacyApiResponse::error('NOT_FOUND', 'Data intern belum terdaftar.', 404);
        }
        if ($intern->mentor_user_id === null) {
            return LegacyApiResponse::error(
                'NO_MENTOR',
                'Pengajuan belum bisa diproses karena pembimbing belum ditetapkan.',
                409
            );
        }

        $savedUrl = null;
        if ($attachmentBase64 !== '') {
            try {
                $binary = $this->decodeBase64Image($attachmentBase64);
                $ext = $this->guessExtension($attachmentName);
                $path = 'leave_attachments/'.(int) $user['user_id'].'/'.CarbonImmutable::now(self::APP_TIMEZONE)->format('Ymd_His').'_'.$this->randomString(6).'.'.$ext;
                Storage::disk('public')->put($path, $binary);
                $savedUrl = Storage::disk('public')->url($path);
            } catch (\Throwable $e) {
                return LegacyApiResponse::error('ATTACHMENT_INVALID', 'File bukti tidak valid.', 422, ['detail' => $e->getMessage()]);
            }
        }

        $now = CarbonImmutable::now(self::APP_TIMEZONE)->format('Y-m-d H:i:s');
        $newId = DB::table('leave_requests')->insertGetId([
            'intern_user_id' => (int) $user['user_id'],
            'type' => $type,
            'date_from' => $dateFrom,
            'date_to' => $dateTo,
            'reason' => $reason,
            'attachment_url' => $savedUrl,
            'status' => 'PENDING',
            'created_at' => $now,
        ]);

        $row = DB::table('leave_requests')->where('id', (int) $newId)->first();

        $adminIds = DB::table('users')
            ->where('role', 'ADMIN')
            ->pluck('id')
            ->map(fn (mixed $value): int => (int) $value)
            ->all();
        $recipientIds = array_values(array_unique([
            ...$adminIds,
            (int) $intern->mentor_user_id,
        ]));
        (new OneSignalPushService())->sendToUsers(
            userIds: $recipientIds,
            title: 'Pengajuan izin/sakit baru',
            body: "{$user['full_name']} mengajukan {$type} ({$dateFrom} s/d {$dateTo}).",
            data: [
                'kind' => 'LEAVE_REQUEST',
                'leaveId' => (string) $newId,
                'internUserId' => (string) $user['user_id'],
                'type' => $type,
                'dateFrom' => $dateFrom,
                'dateTo' => $dateTo,
            ],
        );

        return LegacyApiResponse::ok([
            'leave' => $row,
        ], 201);
    }

    /**
     * Hitung window buka tutup check-in / check-out berdasarkan settings (jam masuk, jam pulang, cutoff).
     */
    private function computeWindows(CarbonImmutable $now, array $settings): array
    {
        $tz = (string) ($settings['timezone'] ?? self::APP_TIMEZONE);
        $date = $now->format('Y-m-d');
        $workStart = CarbonImmutable::parse($date.' '.($settings['work_start_time'] ?? self::DEFAULT_WORK_START_TIME), $tz);
        $workEnd = CarbonImmutable::parse($date.' '.($settings['work_end_time'] ?? self::DEFAULT_WORK_END_TIME), $tz);
        if ($workEnd->lessThanOrEqualTo($workStart)) {
            $workEnd = $workEnd->addDay(); // handle shift melewati tengah malam
        }

        $cutoff = CarbonImmutable::parse($date.' '.($settings['day_cutoff_time'] ?? self::DEFAULT_DAY_CUTOFF_TIME), $tz);
        if ($cutoff->lessThanOrEqualTo($workStart)) {
            $cutoff = $cutoff->addDay();
        }

        $tolMin = (int) ($settings['tolerance_minutes'] ?? self::DEFAULT_TOLERANCE_MINUTES);
        $early = max(0, min($tolMin, 120)); // batasi buka awal max 2 jam sebelum jam mulai
        $checkinOpen = $workStart->subMinutes($early);
        $checkinClose = $workEnd->lessThan($cutoff) ? $workEnd : $cutoff;

        $checkoutOpen = $workEnd;
        $checkoutClose = $cutoff;

        return [
            'checkin' => [
                'openAt' => $checkinOpen,
                'closeAt' => $checkinClose,
                'isOpen' => $now->betweenIncluded($checkinOpen, $checkinClose),
            ],
            'checkout' => [
                'openAt' => $checkoutOpen,
                'closeAt' => $checkoutClose,
                'isOpen' => $now->betweenIncluded($checkoutOpen, $checkoutClose),
            ],
            'workStart' => $workStart,
            'workEnd' => $workEnd,
            'cutoff' => $cutoff,
        ];
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
        ];
        if (! array_key_exists('work_end_time', $arr) || $arr['work_end_time'] === null || $arr['work_end_time'] === '') {
            $arr['work_end_time'] = self::DEFAULT_WORK_END_TIME;
        }
        if (! array_key_exists('day_cutoff_time', $arr) || $arr['day_cutoff_time'] === null || $arr['day_cutoff_time'] === '') {
            $arr['day_cutoff_time'] = self::DEFAULT_DAY_CUTOFF_TIME;
        }

        return $arr;
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

    private function decodeBase64Image(string $input): string
    {
        $clean = preg_replace('#^data:image/[^;]+;base64,#', '', $input);
        $clean = str_replace(["\r", "\n", ' '], '', $clean);
        $binary = base64_decode($clean, true);
        if ($binary === false) {
            throw new \RuntimeException('Base64 decode gagal.');
        }

        return $binary;
    }

    private function guessExtension(string $name): string
    {
        $name = strtolower($name);
        if (str_ends_with($name, '.png')) {
            return 'png';
        }
        if (str_ends_with($name, '.gif')) {
            return 'gif';
        }
        return 'jpg';
    }

    private function randomString(int $len = 6): string
    {
        return substr(bin2hex(random_bytes($len)), 0, $len);
    }

    private function parseIsoDate(string $value): ?CarbonImmutable
    {
        $value = trim($value);
        if (! preg_match('/^\d{4}-\d{2}-\d{2}$/', $value)) {
            return null;
        }

        try {
            $date = CarbonImmutable::createFromFormat('Y-m-d', $value, self::APP_TIMEZONE);
        } catch (\Throwable) {
            return null;
        }

        if (! $date instanceof CarbonImmutable) {
            return null;
        }

        if ($date->format('Y-m-d') !== $value) {
            return null;
        }

        return $date;
    }
}
