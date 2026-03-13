<?php

namespace App\Support;

use Illuminate\Http\Request;

class LegacyRequest
{
    public static function jsonBody(Request $request, ?bool &$invalidJson = null): array
    {
        $invalidJson = false;
        $raw = (string) $request->getContent();

        if (trim($raw) === '') {
            return [];
        }

        try {
            $payload = json_decode($raw, true, 512, JSON_THROW_ON_ERROR);
        } catch (\JsonException) {
            $invalidJson = true;

            return [];
        }

        if (! is_array($payload)) {
            $invalidJson = true;

            return [];
        }

        return $payload;
    }

    public static function missingFields(array $payload, array $fields): array
    {
        $missing = [];

        foreach ($fields as $field) {
            if (! array_key_exists($field, $payload) || $payload[$field] === null || $payload[$field] === '') {
                $missing[] = $field;
            }
        }

        return $missing;
    }
}
