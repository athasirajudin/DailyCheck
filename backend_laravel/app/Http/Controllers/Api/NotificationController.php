<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Support\LegacyApiResponse;
use App\Support\LegacyRequest;
use Carbon\CarbonImmutable;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class NotificationController extends Controller
{
    private const APP_TIMEZONE = 'Asia/Jakarta';
    private const ALLOWED_PLATFORMS = ['ANDROID', 'IOS', 'WEB', 'WINDOWS'];

    public function registerDeviceToken(Request $request): JsonResponse
    {
        $user = $request->attributes->get('auth_user');
        if (! is_array($user)) {
            return LegacyApiResponse::error('UNAUTHENTICATED', 'Butuh login.', 401);
        }
        if (! Schema::hasTable('push_device_tokens')) {
            return LegacyApiResponse::error(
                'PUSH_NOT_READY',
                'Tabel push_device_tokens belum tersedia. Jalankan migration SQL notifikasi.',
                503
            );
        }

        $body = LegacyRequest::jsonBody($request, $invalidJson);
        if ($invalidJson) {
            return LegacyApiResponse::error('BAD_JSON', 'Body JSON tidak valid.', 400);
        }

        $missing = LegacyRequest::missingFields($body, ['token']);
        if ($missing !== []) {
            return LegacyApiResponse::error('MISSING_FIELDS', 'Field wajib belum diisi.', 422, ['missing' => $missing]);
        }

        $token = trim((string) $body['token']);
        if (strlen($token) < 20 || strlen($token) > 255) {
            return LegacyApiResponse::error('BAD_TOKEN', 'Format token perangkat tidak valid.', 422);
        }

        $platform = strtoupper(trim((string) ($body['platform'] ?? 'ANDROID')));
        if (! in_array($platform, self::ALLOWED_PLATFORMS, true)) {
            return LegacyApiResponse::error('BAD_PLATFORM', 'Platform notifikasi tidak valid.', 422);
        }

        $deviceName = trim((string) ($body['deviceName'] ?? ''));
        if (strlen($deviceName) > 190) {
            $deviceName = substr($deviceName, 0, 190);
        }

        $now = CarbonImmutable::now(self::APP_TIMEZONE)->format('Y-m-d H:i:s');
        $existing = DB::table('push_device_tokens')->where('fcm_token', $token)->first();
        if ($existing) {
            DB::table('push_device_tokens')
                ->where('id', (int) $existing->id)
                ->update([
                    'user_id' => (int) $user['user_id'],
                    'platform' => $platform,
                    'device_name' => $deviceName === '' ? null : $deviceName,
                    'last_seen_at' => $now,
                    'updated_at' => $now,
                    'revoked_at' => null,
                ]);
        } else {
            DB::table('push_device_tokens')->insert([
                'user_id' => (int) $user['user_id'],
                'platform' => $platform,
                'fcm_token' => $token,
                'device_name' => $deviceName === '' ? null : $deviceName,
                'last_seen_at' => $now,
                'created_at' => $now,
                'updated_at' => $now,
                'revoked_at' => null,
            ]);
        }

        return LegacyApiResponse::ok(['registered' => true]);
    }
}
