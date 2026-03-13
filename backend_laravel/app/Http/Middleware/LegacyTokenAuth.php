<?php

namespace App\Http\Middleware;

use App\Support\LegacyApiResponse;
use Carbon\CarbonImmutable;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpFoundation\Response;

class LegacyTokenAuth
{
    public function handle(Request $request, Closure $next, string ...$roles): Response
    {
        $token = $request->bearerToken();
        if (! $token) {
            return LegacyApiResponse::error('UNAUTHENTICATED', 'Butuh login.', 401);
        }

        $tokenHash = hash('sha256', $token);

        $row = DB::table('auth_tokens as t')
            ->join('users as u', 'u.id', '=', 't.user_id')
            ->select([
                't.user_id',
                't.expires_at',
                'u.email',
                'u.full_name',
                'u.role',
            ])
            ->where('t.token_hash', $tokenHash)
            ->whereNull('t.revoked_at')
            ->first();

        if (! $row) {
            return LegacyApiResponse::error('UNAUTHENTICATED', 'Token tidak valid.', 401);
        }

        $now = CarbonImmutable::now('Asia/Jakarta');
        $expiresAt = CarbonImmutable::parse($row->expires_at, 'Asia/Jakarta');
        if ($expiresAt->lessThanOrEqualTo($now)) {
            return LegacyApiResponse::error('UNAUTHENTICATED', 'Token sudah kedaluwarsa.', 401);
        }

        if ($roles !== [] && ! in_array($row->role, $roles, true)) {
            return LegacyApiResponse::error('FORBIDDEN', 'Akses ditolak.', 403);
        }

        $request->attributes->set('auth_user', [
            'user_id' => (int) $row->user_id,
            'email' => $row->email,
            'full_name' => $row->full_name,
            'role' => $row->role,
        ]);

        return $next($request);
    }
}
