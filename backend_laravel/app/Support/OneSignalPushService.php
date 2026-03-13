<?php

namespace App\Support;

use Illuminate\Http\Client\Response;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Schema;

class OneSignalPushService
{
    private const API_URL = 'https://api.onesignal.com/notifications';

    /**
     * @param array<int> $userIds
     * @param array<string, scalar|null> $data
     */
    public function sendToUsers(array $userIds, string $title, string $body, array $data = []): void
    {
        try {
            $appId = trim((string) env('ONESIGNAL_APP_ID', ''));
            $restApiKey = trim((string) env('ONESIGNAL_REST_API_KEY', ''));
            if ($appId === '' || $restApiKey === '') {
                Log::warning('OneSignal send skipped: missing ONESIGNAL_APP_ID / ONESIGNAL_REST_API_KEY');

                return;
            }

            $externalUserIds = array_values(array_unique(array_map(
                static fn (int $id): string => (string) $id,
                array_values(array_filter(
                    array_map('intval', $userIds),
                    static fn (int $id): bool => $id > 0
                ))
            )));
            if ($externalUserIds === []) {
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

            $basePayload = [
                'app_id' => $appId,
                'target_channel' => 'push',
                'headings' => [
                    'en' => $title,
                    'id' => $title,
                ],
                'contents' => [
                    'en' => $body,
                    'id' => $body,
                ],
                'data' => $payloadData,
            ];

            /** @var Response $response */
            $response = $this->postNotification([
                ...$basePayload,
                'include_aliases' => [
                    'external_id' => $externalUserIds,
                ],
            ], $restApiKey);

            $recipients = $this->extractRecipients($response);
            $notificationId = $this->extractNotificationId($response);
            if ($response->successful() && $notificationId !== null) {
                return;
            }

            Log::warning('OneSignal alias send failed/empty', [
                'status' => $response->status(),
                'recipients' => $recipients,
                'notification_id' => $notificationId,
                'body' => substr((string) $response->body(), 0, 500),
                'external_user_ids' => $externalUserIds,
            ]);

            // Hindari notifikasi dobel: fallback hanya saat request alias benar-benar gagal (non-2xx).
            if ($response->successful()) {
                return;
            }

            $subscriptionIds = $this->activeSubscriptionIdsForUsers($userIds);
            if ($subscriptionIds === []) {
                return;
            }

            /** @var Response $fallbackResponse */
            $fallbackResponse = $this->postNotification([
                ...$basePayload,
                'include_subscription_ids' => $subscriptionIds,
            ], $restApiKey);
            $fallbackRecipients = $this->extractRecipients($fallbackResponse);
            if ($fallbackResponse->successful() && $fallbackRecipients > 0) {
                return;
            }

            Log::warning('OneSignal fallback send failed/empty', [
                'status' => $fallbackResponse->status(),
                'recipients' => $fallbackRecipients,
                'body' => substr((string) $fallbackResponse->body(), 0, 500),
                'subscription_ids_count' => count($subscriptionIds),
                'external_user_ids' => $externalUserIds,
            ]);
        } catch (\Throwable $e) {
            Log::warning('OneSignal send runtime error', ['error' => $e->getMessage()]);
        }
    }

    private function postNotification(array $payload, string $restApiKey): Response
    {
        /** @var Response $response */
        $response = Http::withHeaders([
            'Authorization' => 'Basic '.$restApiKey,
            'Accept' => 'application/json',
        ])
            ->asJson()
            ->connectTimeout(8)
            ->timeout(20)
            ->retry(2, 250, throw: false)
            ->post(self::API_URL, $payload);

        return $response;
    }

    private function extractRecipients(Response $response): int
    {
        $json = $response->json();
        if (! is_array($json)) {
            return 0;
        }

        return (int) ($json['recipients'] ?? 0);
    }

    private function extractNotificationId(Response $response): ?string
    {
        $json = $response->json();
        if (! is_array($json)) {
            return null;
        }

        $id = trim((string) ($json['id'] ?? ''));

        return $id === '' ? null : $id;
    }

    /**
     * @param array<int> $userIds
     * @return array<int, string>
     */
    private function activeSubscriptionIdsForUsers(array $userIds): array
    {
        if (! Schema::hasTable('push_device_tokens')) {
            return [];
        }

        $ids = array_values(array_filter(
            array_map('intval', $userIds),
            static fn (int $id): bool => $id > 0
        ));
        if ($ids === []) {
            return [];
        }

        return DB::table('push_device_tokens')
            ->whereIn('user_id', $ids)
            ->whereNull('revoked_at')
            ->pluck('fcm_token')
            ->map(static fn (mixed $value): string => trim((string) $value))
            ->filter(static fn (string $value): bool => preg_match('/^[0-9a-fA-F-]{36}$/', $value) === 1)
            ->unique()
            ->values()
            ->all();
    }
}
