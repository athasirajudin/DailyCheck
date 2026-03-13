<?php
declare(strict_types=1);

function now_jakarta(): DateTimeImmutable {
  return new DateTimeImmutable('now', new DateTimeZone(APP_TIMEZONE));
}

function today_ymd(): string {
  return now_jakarta()->format('Y-m-d');
}

function random_token(int $bytes = 32): string {
  return bin2hex(random_bytes($bytes));
}

function sha256(string $s): string {
  return hash('sha256', $s);
}

function request_path(): string {
  $uriPath = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH);
  if (!is_string($uriPath)) {
    return '/';
  }
  $scriptDir = rtrim(str_replace('\\', '/', dirname($_SERVER['SCRIPT_NAME'] ?? '/')), '/');
  $path = $uriPath;
  if ($scriptDir !== '' && $scriptDir !== '/' && str_starts_with($path, $scriptDir)) {
    $path = substr($path, strlen($scriptDir));
  }
  if ($path === '') {
    $path = '/';
  }
  return $path;
}

function haversine_m(float $lat1, float $lon1, float $lat2, float $lon2): float {
  $r = 6371000.0;
  $dLat = deg2rad($lat2 - $lat1);
  $dLon = deg2rad($lon2 - $lon1);
  $a = sin($dLat / 2) ** 2 + cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * sin($dLon / 2) ** 2;
  $c = 2 * atan2(sqrt($a), sqrt(1 - $a));
  return $r * $c;
}

function get_settings(mysqli $db): array {
  $row = db_one($db, 'SELECT * FROM settings WHERE id=1');
  if (!$row) {
    return [
      'timezone' => APP_TIMEZONE,
      'work_start_time' => DEFAULT_WORK_START_TIME,
      'tolerance_minutes' => DEFAULT_TOLERANCE_MINUTES,
      'day_cutoff_time' => DEFAULT_DAY_CUTOFF_TIME,
      'workdays_json' => DEFAULT_WORKDAYS_JSON,
      'offline_threshold_seconds' => DEFAULT_OFFLINE_THRESHOLD_SECONDS,
      'qr_token_ttl_seconds' => DEFAULT_QR_TTL_SECONDS,
    ];
  }
  return $row;
}

function is_workday(mysqli $db, DateTimeImmutable $dt): bool {
  $settings = get_settings($db);
  $weekday = (int)$dt->format('N'); // 1..7
  $workdays = json_decode($settings['workdays_json'] ?? DEFAULT_WORKDAYS_JSON, true);
  if (!is_array($workdays) || !in_array($weekday, $workdays, true)) {
    return false;
  }
  $ymd = $dt->format('Y-m-d');
  $holiday = db_one($db, 'SELECT id FROM holidays WHERE date=? LIMIT 1', 's', [$ymd]);
  return $holiday === null;
}

