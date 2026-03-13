<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Support\LegacyApiResponse;
use App\Support\LegacyRequest;
use Carbon\CarbonImmutable;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AuthController extends Controller
{
    public function login(Request $request)
    {
        $body = LegacyRequest::jsonBody($request, $invalidJson);
        if ($invalidJson) {
            return LegacyApiResponse::error('BAD_JSON', 'Body JSON tidak valid.', 400);
        }

        $missing = LegacyRequest::missingFields($body, ['email', 'password']);
        if ($missing !== []) {
            return LegacyApiResponse::error('MISSING_FIELDS', 'Field wajib belum diisi.', 422, ['missing' => $missing]);
        }

        $email = strtolower(trim((string) $body['email']));
        $password = (string) $body['password'];

        $user = DB::table('users')
            ->select(['id', 'email', 'full_name', 'role', 'password_hash'])
            ->where('email', $email)
            ->first();

        if (! $user || ! password_verify($password, (string) $user->password_hash)) {
            return LegacyApiResponse::error('INVALID_CREDENTIALS', 'Email atau password salah.', 401);
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
}
