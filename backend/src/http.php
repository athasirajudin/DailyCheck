<?php
declare(strict_types=1);

function json_body(): array {
  $raw = file_get_contents('php://input');
  if ($raw === false || trim($raw) === '') {
    return [];
  }
  $data = json_decode($raw, true);
  if (!is_array($data)) {
    json_error('BAD_JSON', 'Body JSON tidak valid.', 400);
  }
  return $data;
}

function json_ok($data, int $status = 200): void {
  http_response_code($status);
  header('Content-Type: application/json; charset=utf-8');
  echo json_encode(['ok' => true, 'data' => $data], JSON_UNESCAPED_UNICODE);
  exit;
}

function json_error(string $code, string $message, int $status = 400, array $extra = []): void {
  http_response_code($status);
  header('Content-Type: application/json; charset=utf-8');
  $payload = array_merge([
    'ok' => false,
    'error' => [
      'code' => $code,
      'message' => $message,
    ],
  ], $extra ? ['extra' => $extra] : []);
  echo json_encode($payload, JSON_UNESCAPED_UNICODE);
  exit;
}

function require_fields(array $data, array $fields): void {
  $missing = [];
  foreach ($fields as $f) {
    if (!array_key_exists($f, $data) || $data[$f] === null || $data[$f] === '') {
      $missing[] = $f;
    }
  }
  if ($missing) {
    json_error('MISSING_FIELDS', 'Field wajib belum diisi.', 422, ['missing' => $missing]);
  }
}