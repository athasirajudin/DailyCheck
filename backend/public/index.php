<?php
declare(strict_types=1);

require_once __DIR__ . '/../src/http.php';
require_once __DIR__ . '/../src/util.php';
require_once __DIR__ . '/../src/config.php';
require_once __DIR__ . '/../src/db.php';
require_once __DIR__ . '/../src/auth.php';
require_once __DIR__ . '/../src/routes.php';

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS');
if (($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'OPTIONS') {
  http_response_code(204);
  exit;
}

date_default_timezone_set(APP_TIMEZONE);

try {
  $db = db_connect();
  route_request($db);
} catch (Throwable $e) {
  json_error('INTERNAL_ERROR', 'Terjadi kesalahan pada server.', 500, [
    'detail' => APP_DEBUG ? ($e->getMessage() . "\n" . $e->getTraceAsString()) : null,
  ]);
}

