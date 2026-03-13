<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Support\LegacyApiResponse;
use App\Support\LegacyRequest;
use Carbon\CarbonImmutable;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Contracts\Cache\Repository as CacheRepository;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;

class AuthController extends Controller
{
    public function verifyAdminPin(Request $request)
    {
        $body = $this->readRequestBody($request, $invalidJson);
        if ($invalidJson) {
            return LegacyApiResponse::error('BAD_JSON', 'Body JSON tidak valid.', 400);
        }

        $missing = LegacyRequest::missingFields($body, ['pin']);
        if ($missing !== []) {
            return LegacyApiResponse::error('MISSING_FIELDS', 'Field wajib belum diisi.', 422, ['missing' => $missing]);
        }

        $configuredPin = trim((string) config('app.admin_login_pin', ''));
        if ($configuredPin === '') {
            return LegacyApiResponse::error(
                'ADMIN_PIN_NOT_CONFIGURED',
                'PIN admin belum dikonfigurasi di server.',
                503
            );
        }

        $pin = trim((string) $body['pin']);
        if ($pin === '' || ! hash_equals($configuredPin, $pin)) {
            return LegacyApiResponse::error('INVALID_ADMIN_PIN', 'PIN admin salah.', 403);
        }

        $ttlSeconds = max(60, (int) config('app.admin_access_ttl_seconds', 300));
        $ticket = bin2hex(random_bytes(32));
        $this->adminAccessCache()->put(
            $this->adminAccessCacheKey($ticket),
            ['issued_at' => CarbonImmutable::now('Asia/Jakarta')->format('Y-m-d H:i:s')],
            now()->addSeconds($ttlSeconds)
        );

        return LegacyApiResponse::ok([
            'ticket' => $ticket,
            'expiresInSeconds' => $ttlSeconds,
        ]);
    }

    public function login(Request $request)
    {
        $body = $this->readRequestBody($request, $invalidJson);
        if ($invalidJson || $body === []) {
            \Log::warning('login payload issue', [
                'raw' => (string) $request->getContent(),
                'headers' => $request->headers->all(),
                'request_all' => $request->all(),
            ]);
        }
        $isJsonHeader = str_contains(strtolower($request->header('Content-Type', '')), 'application/json');
        if ($invalidJson && $isJsonHeader) {
            return LegacyApiResponse::error('BAD_JSON', 'Body JSON tidak valid.', 400);
        }

        $missing = LegacyRequest::missingFields($body, ['password']);
        if (! array_key_exists('identifier', $body) && ! array_key_exists('email', $body)) {
            $missing[] = 'identifier';
        }
        if ($missing !== []) {
            return LegacyApiResponse::error('MISSING_FIELDS', 'Field wajib belum diisi.', 422, ['missing' => $missing]);
        }

        $identifier = trim((string) ($body['identifier'] ?? $body['email'] ?? ''));
        $password = (string) $body['password'];
        $mode = strtoupper(trim((string) ($body['mode'] ?? '')));
        $adminAccessTicket = trim((string) ($body['admin_access_ticket'] ?? ''));

        if (! in_array($mode, ['INTERN', 'ADMIN', 'PEMBIMBING'], true)) {
            return LegacyApiResponse::error(
                'INVALID_LOGIN_MODE',
                'Mode login tidak valid.',
                422
            );
        }

        $user = $this->findUserByIdentifier($identifier);

        if (! $user || ! password_verify($password, (string) $user->password_hash)) {
            return LegacyApiResponse::error('INVALID_CREDENTIALS', 'Email atau password salah.', 401);
        }

        $role = strtoupper((string) $user->role);

        if ($mode === 'INTERN' && $role !== 'INTERN') {
            return LegacyApiResponse::error(
                'UNAUTHORIZED_ROLE',
                'Akun ini bukan akun intern. Gunakan halaman login admin/pembimbing.',
                403
            );
        }

        if ($mode === 'ADMIN' && $role !== 'ADMIN') {
            return LegacyApiResponse::error(
                'UNAUTHORIZED_ROLE',
                'Akun ini bukan akun admin. Gunakan halaman login yang sesuai.',
                403
            );
        }

        if ($mode === 'PEMBIMBING' && $role !== 'PEMBIMBING') {
            return LegacyApiResponse::error(
                'UNAUTHORIZED_ROLE',
                'Akun ini bukan akun pembimbing. Gunakan halaman login yang sesuai.',
                403
            );
        }

        if ($mode === 'ADMIN' || $mode === 'PEMBIMBING') {
            if (! $this->isEmailIdentifier($identifier)) {
                return LegacyApiResponse::error(
                    'INVALID_LOGIN_METHOD',
                    $mode === 'ADMIN'
                        ? 'Akun admin harus login menggunakan email.'
                        : 'Akun pembimbing harus login menggunakan email.',
                    422
                );
            }
        }

        if ($mode === 'ADMIN') {
            $ticketError = $this->consumeAdminAccessTicket($adminAccessTicket);
            if ($ticketError !== null) {
                return $ticketError;
            }
        } elseif ($mode === 'INTERN' && ! $this->isNisnIdentifier($identifier)) {
            return LegacyApiResponse::error(
                'INVALID_LOGIN_METHOD',
                'Akun intern harus login menggunakan NISN.',
                422
            );
        }

        $token = bin2hex(random_bytes(32));
        $expiresAt = CarbonImmutable::now('Asia/Jakarta')->addDays(7);

        DB::table('auth_tokens')->insert([
            'user_id' => (int) $user->id,
            'token_hash' => hash('sha256', $token),
            'expires_at' => $expiresAt->format('Y-m-d H:i:s'),
            'created_at' => CarbonImmutable::now('Asia/Jakarta')->format('Y-m-d H:i:s'),
        ]);

        return LegacyApiResponse::ok([
            'token' => $token,
            'user' => [
                'id' => (int) $user->id,
                'email' => $user->email,
                'fullName' => $user->full_name,
                'role' => $user->role,
            ],
        ]);
    }

    private function readRequestBody(Request $request, ?bool &$invalidJson = null): array
    {
        $body = LegacyRequest::jsonBody($request, $invalidJson);
        if ($body !== []) {
            return $body;
        }

        return $request->all();
    }

    private function consumeAdminAccessTicket(string $ticket): ?JsonResponse
    {
        if ($ticket === '') {
            return LegacyApiResponse::error(
                'ADMIN_ACCESS_REQUIRED',
                'Verifikasi PIN admin wajib dilakukan sebelum login admin.',
                403
            );
        }

        $cacheKey = $this->adminAccessCacheKey($ticket);
        $issued = $this->adminAccessCache()->pull($cacheKey);
        if ($issued === null) {
            return LegacyApiResponse::error(
                'ADMIN_ACCESS_EXPIRED',
                'Verifikasi PIN admin sudah kedaluwarsa. Silakan verifikasi ulang.',
                403
            );
        }

        return null;
    }

    private function adminAccessCacheKey(string $ticket): string
    {
        return 'admin-access-ticket:'.hash('sha256', $ticket);
    }

    private function adminAccessCache(): CacheRepository
    {
        $store = trim((string) config('app.admin_access_cache_store', 'file'));

        return Cache::store($store);
    }

    private function isEmailIdentifier(string $identifier): bool
    {
        return filter_var(trim($identifier), FILTER_VALIDATE_EMAIL) !== false;
    }

    private function isNisnIdentifier(string $identifier): bool
    {
        return preg_match('/^\d+$/', trim($identifier)) === 1;
    }

    private function findUserByIdentifier(string $identifier): ?object
    {
        $identifier = trim($identifier);
        if ($identifier === '') {
            return null;
        }
        // Intern: allow login via NISN
        $user = DB::table('users')
            ->select(['u.id', 'u.email', 'u.full_name', 'u.role', 'u.password_hash'])
            ->from('users as u')
            ->join('interns as i', 'i.user_id', '=', 'u.id')
            ->where('i.nisn', $identifier)
            ->first();
        if ($user) {
            return $user;
        }
        // Fallback: email (all roles)
        return DB::table('users')
            ->select(['id', 'email', 'full_name', 'role', 'password_hash'])
            ->where('email', strtolower($identifier))
            ->first();
    }
}
