<?php

namespace App\Support;

use Illuminate\Http\JsonResponse;

class LegacyApiResponse
{
    public static function ok(mixed $data, int $status = 200): JsonResponse
    {
        return response()->json([
            'ok' => true,
            'data' => $data,
        ], $status);
    }

    public static function error(string $code, string $message, int $status = 400, array $extra = []): JsonResponse
    {
        $payload = [
            'ok' => false,
            'error' => [
                'code' => $code,
                'message' => $message,
            ],
        ];

        if ($extra !== []) {
            $payload['extra'] = $extra;
        }

        return response()->json($payload, $status);
    }
}
