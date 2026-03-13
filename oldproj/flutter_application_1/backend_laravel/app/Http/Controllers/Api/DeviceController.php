<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Support\LegacyApiResponse;
use App\Support\LegacyRequest;
use Carbon\CarbonImmutable;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class DeviceController extends Controller
{
    private const DEFAULT_QR_TTL_SECONDS = 30;

    public function pair(Request $request): JsonResponse
    {
        $body = LegacyRequest::jsonBody($request, $invalidJson);
        if ($invalidJson) {
            return LegacyApiResponse::error('BAD_JSON', 'Body JSON tidak valid.', 400);
        }

        $missing = LegacyRequest::missingFields($body, ['pairingCode']);
        if ($missing !== []) {
            return LegacyApiResponse::error('MISSING_FIELDS', 'Field wajib belum diisi.', 422, ['missing' => $missing]);
        }

        $pairingCode = strtoupper(trim((string) $body['pairingCode']));
        $row = DB::table('pairing_codes')
            ->select(['id', 'unit_id', 'device_name', 'expires_at', 'used_at'])
            ->where('code', $pairingCode)
            ->orderByDesc('id')
            ->first();

        if (! $row) {
            return LegacyApiResponse::error('INVALID_PAIRING', 'Pairing code tidak valid.', 400);
        }
        if ($row->used_at !== null) {
            return LegacyApiResponse::error('INVALID_PAIRING', 'Pairing code sudah digunakan.', 400);
        }

        $expires = CarbonImmutable::parse($row->expires_at, 'Asia/Jakarta');
        if ($expires->lessThanOrEqualTo(CarbonImmutable::now('Asia/Jakarta'))) {
            return LegacyApiResponse::error('INVALID_PAIRING', 'Pairing code sudah kedaluwarsa.', 400);
        }

        $authKey = bin2hex(random_bytes(24));
        $authHash = hash('sha256', $authKey);
        $now = CarbonImmutable::now('Asia/Jakarta')->format('Y-m-d H:i:s');

        $deviceId = DB::table('devices')->insertGetId([
            'unit_id' => (int) $row->unit_id,
            'name' => $row->device_name,
            'auth_key_hash' => $authHash,
            'last_seen_at' => $now,
            'created_at' => $now,
            'updated_at' => $now,
        ]);

        DB::table('pairing_codes')
            ->where('id', (int) $row->id)
            ->update([
                'used_at' => $now,
                'used_by_device_id' => (int) $deviceId,
            ]);

        return LegacyApiResponse::ok([
            'deviceId' => (int) $deviceId,
            'unitId' => (int) $row->unit_id,
            'deviceName' => $row->device_name,
            'authKey' => $authKey,
        ]);
    }

    public function heartbeat(Request $request): JsonResponse
    {
        $device = $this->requireDevice($request);
        if ($device instanceof JsonResponse) {
            return $device;
        }

        DB::table('devices')
            ->where('id', (int) $device['id'])
            ->update([
                'last_seen_at' => CarbonImmutable::now('Asia/Jakarta')->format('Y-m-d H:i:s'),
                'updated_at' => CarbonImmutable::now('Asia/Jakarta')->format('Y-m-d H:i:s'),
            ]);

        return LegacyApiResponse::ok([
            'deviceId' => (int) $device['id'],
            'ok' => true,
        ]);
    }

    public function qrToken(Request $request): JsonResponse
    {
        $device = $this->requireDevice($request);
        if ($device instanceof JsonResponse) {
            return $device;
        }

        $settings = DB::table('settings')->where('id', 1)->first();
        $ttl = (int) ($settings->qr_token_ttl_seconds ?? self::DEFAULT_QR_TTL_SECONDS);
        $now = CarbonImmutable::now('Asia/Jakarta');

        DB::table('qr_sessions')
            ->where('device_id', (int) $device['id'])
            ->where('active', 1)
            ->update([
                'active' => 0,
                'deactivated_at' => $now->format('Y-m-d H:i:s'),
            ]);

        $token = strtoupper(substr(bin2hex(random_bytes(12)), 0, 24));
        $expiresAt = $now->addSeconds($ttl)->format('Y-m-d H:i:s');

        DB::table('qr_sessions')->insert([
            'device_id' => (int) $device['id'],
            'token' => $token,
            'expires_at' => $expiresAt,
            'active' => 1,
            'created_at' => $now->format('Y-m-d H:i:s'),
        ]);

        return LegacyApiResponse::ok([
            'token' => $token,
            'expiresAt' => $expiresAt,
        ]);
    }

    private function requireDevice(Request $request): array|JsonResponse
    {
        $authKey = (string) $request->bearerToken();
        if ($authKey === '') {
            return LegacyApiResponse::error('UNAUTHENTICATED', 'Butuh authKey perangkat.', 401);
        }

        $authHash = hash('sha256', $authKey);
        $device = DB::table('devices')
            ->select(['id', 'unit_id', 'name', 'last_seen_at'])
            ->where('auth_key_hash', $authHash)
            ->first();

        if (! $device) {
            return LegacyApiResponse::error('UNAUTHENTICATED', 'AuthKey perangkat tidak valid.', 401);
        }

        return [
            'id' => (int) $device->id,
            'unit_id' => (int) $device->unit_id,
            'name' => $device->name,
            'last_seen_at' => $device->last_seen_at,
        ];
    }
}
