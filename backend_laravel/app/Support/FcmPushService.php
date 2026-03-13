<?php

namespace App\Support;

use Carbon\CarbonImmutable;
use Illuminate\Http\Client\Response;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Schema;

class FcmPushService
{
    private const FIREBASE_SCOPE = 'https://www.googleapis.com/auth/firebase.messaging';
    private const DEFAULT_TOKEN_URI = 'https://oauth2.googleapis.com/token';
    private const HTTP_CONNECT_TIMEOUT_SECONDS = 8;
    private const HTTP_TIMEOUT_SECONDS = 25;

    private static ?string $cachedAccessToken = null;
    private static ?CarbonImmutable $cachedAccessTokenExpiry = null;

    /**
     * @param array<int> $userIds
     * @param array<string, scalar|null> $data
     */
    public function sendToUsers(array $userIds, string $title, string $body, array $data = []): void
    {
        try {
            if (! Schema::hasTable('push_device_tokens')) {
                return;
            }

            $userIds = array_values(array_unique(array_map('intval', $userIds)));
            $userIds = array_values(array_filter($userIds, fn (int $id): bool => $id > 0));
            if ($userIds === []) {
                return;
            }

            $projectId = trim((string) env('FCM_PROJECT_ID', ''));
            if ($projectId === '') {
                return;
            }

            $accessToken = $this->getAccessToken();
            if ($accessToken === null || $accessToken === '') {
                return;
            }

            $tokens = DB::table('push_device_tokens')
                ->whereIn('user_id', $userIds)
                ->whereNull('revoked_at')
                ->pluck('fcm_token')
                ->map(fn (mixed $value): string => trim((string) $value))
                ->filter(fn (string $value): bool => $value !== '')
                ->unique()
                ->values()
                ->all();
            if ($tokens === []) {
                return;
            }

            $payloadData = [];
            foreach ($data as $key => $value) {
                $k = trim((string) $key);
                if ($k === '') {
                    continue;
                }
                $payloadData[$k] = $value === null ? '' : (string) $value;
            }

            foreach ($tokens as $token) {
                try {
                    $this->sendToToken(
                        projectId: $projectId,
                        accessToken: $accessToken,
                        token: $token,
                        title: $title,
                        body: $body,
                        data: $payloadData
                    );
                } catch (\Throwable $e) {
                    Log::warning('FCM send token failed by runtime error', [
                        'token_tail' => substr($token, -12),
                        'error' => $e->getMessage(),
                    ]);
                }
            }
        } catch (\Throwable $e) {
            Log::warning('FCM send skipped by runtime error', ['error' => $e->getMessage()]);
        }
    }

    /**
     * @param array<string, string> $data
     */
    private function sendToToken(
        string $projectId,
        string $accessToken,
        string $token,
        string $title,
        string $body,
        array $data = [],
    ): void {
        /** @var Response $response */
        $response = Http::withToken($accessToken)
            ->acceptJson()
            ->connectTimeout(self::HTTP_CONNECT_TIMEOUT_SECONDS)
            ->timeout(self::HTTP_TIMEOUT_SECONDS)
            ->retry(2, 250, throw: false)
            ->post(
                "https://fcm.googleapis.com/v1/projects/{$projectId}/messages:send",
                [
                    'message' => [
                        'token' => $token,
                        'notification' => [
                            'title' => $title,
                            'body' => $body,
                        ],
                        'data' => $data,
                        'android' => [
                            'priority' => 'high',
                            'ttl' => '30s',
                            'notification' => [
                                'channel_id' => 'dailycheck_default',
                                'sound' => 'default',
                            ],
                        ],
                    ],
                ]
            );

        if ($response->successful()) {
            return;
        }

        $content = (string) $response->body();
        if (str_contains($content, 'UNREGISTERED')) {
            DB::table('push_device_tokens')
                ->where('fcm_token', $token)
                ->update([
                    'revoked_at' => CarbonImmutable::now('Asia/Jakarta')->format('Y-m-d H:i:s'),
                    'updated_at' => CarbonImmutable::now('Asia/Jakarta')->format('Y-m-d H:i:s'),
                ]);
        }

        Log::warning('FCM send failed', [
            'status' => $response->status(),
            'token_tail' => substr($token, -12),
            'body' => substr($content, 0, 300),
        ]);
    }

    private function getAccessToken(): ?string
    {
        $now = CarbonImmutable::now('UTC');
        if (
            self::$cachedAccessToken !== null &&
            self::$cachedAccessTokenExpiry !== null &&
            $now->lessThan(self::$cachedAccessTokenExpiry)
        ) {
            return self::$cachedAccessToken;
        }

        $serviceAccount = $this->loadServiceAccount();
        if ($serviceAccount === null) {
            return null;
        }

        $tokenUri = trim((string) ($serviceAccount['token_uri'] ?? self::DEFAULT_TOKEN_URI));
        $jwt = $this->buildJwt($serviceAccount, $tokenUri);
        if ($jwt === null) {
            return null;
        }

        /** @var Response $response */
        $response = Http::asForm()
            ->connectTimeout(self::HTTP_CONNECT_TIMEOUT_SECONDS)
            ->timeout(self::HTTP_TIMEOUT_SECONDS)
            ->retry(2, 250, throw: false)
            ->post($tokenUri, [
            'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
            'assertion' => $jwt,
            ]);
        if (! $response->successful()) {
            Log::warning('FCM OAuth token request failed', [
                'status' => $response->status(),
                'body' => substr((string) $response->body(), 0, 300),
            ]);

            return null;
        }

        $json = $response->json();
        if (! is_array($json)) {
            return null;
        }

        $accessToken = trim((string) ($json['access_token'] ?? ''));
        $expiresIn = (int) ($json['expires_in'] ?? 3600);
        if ($accessToken === '') {
            return null;
        }

        self::$cachedAccessToken = $accessToken;
        self::$cachedAccessTokenExpiry = $now->addSeconds(max(60, $expiresIn - 60));

        return self::$cachedAccessToken;
    }

    /**
     * @return array<string, mixed>|null
     */
    private function loadServiceAccount(): ?array
    {
        $path = trim((string) env('FCM_SERVICE_ACCOUNT_PATH', ''));
        if ($path === '') {
            return null;
        }

        $candidates = array_unique(array_filter([
            $path,
            base_path($path),
            storage_path($path),
            storage_path('app/'.$path),
        ]));

        $resolvedPath = null;
        foreach ($candidates as $candidate) {
            if (is_file($candidate)) {
                $resolvedPath = $candidate;
                break;
            }
        }
        if ($resolvedPath === null) {
            Log::warning('FCM service account file not found', ['path' => $path]);

            return null;
        }

        $raw = @file_get_contents($resolvedPath);
        if (! is_string($raw) || trim($raw) === '') {
            Log::warning('FCM service account file unreadable', ['path' => $resolvedPath]);

            return null;
        }

        $json = json_decode($raw, true);
        if (! is_array($json)) {
            Log::warning('FCM service account JSON invalid', ['path' => $resolvedPath]);

            return null;
        }

        $required = ['client_email', 'private_key'];
        foreach ($required as $field) {
            if (! isset($json[$field]) || trim((string) $json[$field]) === '') {
                Log::warning('FCM service account missing field', ['field' => $field]);

                return null;
            }
        }

        return $json;
    }

    /**
     * @param array<string, mixed> $serviceAccount
     */
    private function buildJwt(array $serviceAccount, string $tokenUri): ?string
    {
        $clientEmail = trim((string) ($serviceAccount['client_email'] ?? ''));
        $privateKey = (string) ($serviceAccount['private_key'] ?? '');
        if ($clientEmail === '' || $privateKey === '') {
            return null;
        }

        $now = CarbonImmutable::now('UTC')->timestamp;
        $header = ['alg' => 'RS256', 'typ' => 'JWT'];
        $payload = [
            'iss' => $clientEmail,
            'scope' => self::FIREBASE_SCOPE,
            'aud' => $tokenUri,
            'iat' => $now,
            'exp' => $now + 3600,
        ];

        $headerEncoded = $this->base64UrlEncode(json_encode($header, JSON_UNESCAPED_SLASHES));
        $payloadEncoded = $this->base64UrlEncode(json_encode($payload, JSON_UNESCAPED_SLASHES));
        if ($headerEncoded === null || $payloadEncoded === null) {
            return null;
        }

        $toSign = $headerEncoded.'.'.$payloadEncoded;
        $signature = '';
        $signed = openssl_sign($toSign, $signature, $privateKey, OPENSSL_ALGO_SHA256);
        if (! $signed) {
            Log::warning('FCM JWT signing failed');

            return null;
        }

        $signatureEncoded = $this->base64UrlEncode($signature);
        if ($signatureEncoded === null) {
            return null;
        }

        return $toSign.'.'.$signatureEncoded;
    }

    private function base64UrlEncode(string $value): ?string
    {
        $encoded = base64_encode($value);
        if ($encoded === false) {
            return null;
        }

        return rtrim(strtr($encoded, '+/', '-_'), '=');
    }
}
