<?php

namespace App\Legacy {

    use Illuminate\Http\JsonResponse;
    use Illuminate\Http\Request;
    use Throwable;

    class LegacyBridgeResponse extends \RuntimeException
    {
        public function __construct(
            public readonly array $payload,
            public readonly int $status
        ) {
            parent::__construct('Legacy bridge response', $status);
        }
    }

    class LegacyBridgeContext
    {
        public static string $rawBody = '';
    }

    class LegacyBridgeHttp
    {
        public static function jsonBody(): array
        {
            $raw = LegacyBridgeContext::$rawBody;
            if (trim($raw) === '') {
                return [];
            }

            $data = json_decode($raw, true);
            if (! is_array($data)) {
                self::jsonError('BAD_JSON', 'Body JSON tidak valid.', 400);
            }

            return $data;
        }

        public static function jsonOk($data, int $status = 200): void
        {
            throw new LegacyBridgeResponse([
                'ok' => true,
                'data' => $data,
            ], $status);
        }

        public static function jsonError(string $code, string $message, int $status = 400, array $extra = []): void
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

            throw new LegacyBridgeResponse($payload, $status);
        }

        public static function requireFields(array $data, array $fields): void
        {
            $missing = [];
            foreach ($fields as $field) {
                if (! array_key_exists($field, $data) || $data[$field] === null || $data[$field] === '') {
                    $missing[] = $field;
                }
            }

            if ($missing !== []) {
                self::jsonError('MISSING_FIELDS', 'Field wajib belum diisi.', 422, ['missing' => $missing]);
            }
        }
    }

    class LegacyBridge
    {
        private static bool $bootstrapped = false;

        public static function dispatch(Request $request): JsonResponse
        {
            self::bootstrap();
            self::hydrateRequestContext($request);

            try {
                $db = \db_connect();
                \route_request($db);

                return response()->json([
                    'ok' => false,
                    'error' => [
                        'code' => 'INTERNAL_ERROR',
                        'message' => 'Legacy route tidak mengembalikan response.',
                    ],
                ], 500);
            } catch (LegacyBridgeResponse $bridgeResponse) {
                return response()->json($bridgeResponse->payload, $bridgeResponse->status);
            } catch (Throwable $exception) {
                return response()->json([
                    'ok' => false,
                    'error' => [
                        'code' => 'INTERNAL_ERROR',
                        'message' => 'Terjadi kesalahan pada server.',
                    ],
                    'extra' => APP_DEBUG
                        ? ['detail' => $exception->getMessage()."\n".$exception->getTraceAsString()]
                        : null,
                ], 500);
            }
        }

        private static function bootstrap(): void
        {
            if (self::$bootstrapped) {
                return;
            }

            $legacySrc = dirname(base_path()).DIRECTORY_SEPARATOR.'backend'.DIRECTORY_SEPARATOR.'src';

            require_once $legacySrc.DIRECTORY_SEPARATOR.'config.php';
            require_once $legacySrc.DIRECTORY_SEPARATOR.'db.php';
            require_once $legacySrc.DIRECTORY_SEPARATOR.'util.php';
            require_once $legacySrc.DIRECTORY_SEPARATOR.'auth.php';
            require_once $legacySrc.DIRECTORY_SEPARATOR.'routes.php';

            self::$bootstrapped = true;
        }

        private static function hydrateRequestContext(Request $request): void
        {
            LegacyBridgeContext::$rawBody = (string) $request->getContent();

            $_GET = $request->query->all();
            $_POST = [];
            $_REQUEST = array_merge($_GET, $_POST);
            $_SERVER['REQUEST_METHOD'] = strtoupper($request->getMethod());
            $_SERVER['REQUEST_URI'] = $request->getRequestUri();
            $_SERVER['SCRIPT_NAME'] = '/index.php';

            $authorization = (string) $request->header('Authorization', '');
            $_SERVER['HTTP_AUTHORIZATION'] = $authorization;
            $_SERVER['REDIRECT_HTTP_AUTHORIZATION'] = $authorization;

            date_default_timezone_set(APP_TIMEZONE);
        }
    }
}

namespace {

    use App\Legacy\LegacyBridgeHttp;

    if (! function_exists('json_body')) {
        function json_body(): array
        {
            return LegacyBridgeHttp::jsonBody();
        }
    }

    if (! function_exists('json_ok')) {
        function json_ok($data, int $status = 200): void
        {
            LegacyBridgeHttp::jsonOk($data, $status);
        }
    }

    if (! function_exists('json_error')) {
        function json_error(string $code, string $message, int $status = 400, array $extra = []): void
        {
            LegacyBridgeHttp::jsonError($code, $message, $status, $extra);
        }
    }

    if (! function_exists('require_fields')) {
        function require_fields(array $data, array $fields): void
        {
            LegacyBridgeHttp::requireFields($data, $fields);
        }
    }
}
