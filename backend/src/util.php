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
      'work_end_time' => DEFAULT_WORK_END_TIME,
      'tolerance_minutes' => DEFAULT_TOLERANCE_MINUTES,
      'day_cutoff_time' => DEFAULT_DAY_CUTOFF_TIME,
      'workdays_json' => DEFAULT_WORKDAYS_JSON,
      'offline_threshold_seconds' => DEFAULT_OFFLINE_THRESHOLD_SECONDS,
      'qr_token_ttl_seconds' => DEFAULT_QR_TTL_SECONDS,
    ];
  }
  if (!array_key_exists('work_end_time', $row) || $row['work_end_time'] === null || $row['work_end_time'] === '') {
    $row['work_end_time'] = DEFAULT_WORK_END_TIME;
  }
  if (!array_key_exists('day_cutoff_time', $row) || $row['day_cutoff_time'] === null || $row['day_cutoff_time'] === '') {
    $row['day_cutoff_time'] = DEFAULT_DAY_CUTOFF_TIME;
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

function save_base64_attachment(string $input, string $name, int $userId): ?string {
  $clean = preg_replace('#^data:image/[^;]+;base64,#', '', $input);
  $clean = str_replace(["\r", "\n", ' '], '', $clean);
  $binary = base64_decode($clean, true);
  if ($binary === false) {
    return null;
  }
  $ext = 'jpg';
  $low = strtolower($name);
  if (str_ends_with($low, '.png')) {
    $ext = 'png';
  } elseif (str_ends_with($low, '.gif')) {
    $ext = 'gif';
  }
  $dir = __DIR__ . '/../public/leave_attachments/' . $userId;
  if (!is_dir($dir) && !mkdir($dir, 0777, true) && !is_dir($dir)) {
    return null;
  }
  $fname = date('Ymd_His') . '_' . substr(bin2hex(random_bytes(4)), 0, 6) . '.' . $ext;
  $path = $dir . '/' . $fname;
  if (file_put_contents($path, $binary) === false) {
    return null;
  }
  $relative = 'leave_attachments/' . $userId . '/' . $fname;
  return url_public($relative);
}

function url_public(string $relative): string {
  return '/' . ltrim($relative, '/');
}

function require_device(mysqli $db): array {
  json_error('NOT_FOUND', 'Fitur perangkat dinonaktifkan.', 404);
  return [];
}

/**
 * Hitung window buka/tutup check-in dan check-out berdasar jam mulai, jam selesai, cutoff.
 */
function attendance_windows(DateTimeImmutable $now, array $settings): array {
  $tz = (string)($settings['timezone'] ?? APP_TIMEZONE);
  $date = $now->format('Y-m-d');
  $workStart = new DateTimeImmutable($date . ' ' . ($settings['work_start_time'] ?? DEFAULT_WORK_START_TIME), new DateTimeZone($tz));
  $workEnd = new DateTimeImmutable($date . ' ' . ($settings['work_end_time'] ?? DEFAULT_WORK_END_TIME), new DateTimeZone($tz));
  if ($workEnd <= $workStart) {
    $workEnd = $workEnd->modify('+1 day'); // shift malam
  }
  $cutoff = new DateTimeImmutable($date . ' ' . ($settings['day_cutoff_time'] ?? DEFAULT_DAY_CUTOFF_TIME), new DateTimeZone($tz));
  if ($cutoff <= $workStart) {
    $cutoff = $cutoff->modify('+1 day');
  }
  $tolMin = (int)($settings['tolerance_minutes'] ?? DEFAULT_TOLERANCE_MINUTES);
  $early = max(0, min($tolMin, 120)); // buka awal max 2 jam sebelum jam mulai
  $checkinOpen = $workStart->modify("-{$early} minutes");
  $checkinClose = ($workEnd < $cutoff) ? $workEnd : $cutoff;
  $checkoutOpen = $workEnd;
  $checkoutClose = $cutoff;
  $between = fn(DateTimeImmutable $dt, DateTimeImmutable $a, DateTimeImmutable $b): bool => $dt >= $a && $dt <= $b;

  return [
    'checkin' => [
      'openAt' => $checkinOpen,
      'closeAt' => $checkinClose,
      'isOpen' => $between($now, $checkinOpen, $checkinClose),
    ],
    'checkout' => [
      'openAt' => $checkoutOpen,
      'closeAt' => $checkoutClose,
      'isOpen' => $between($now, $checkoutOpen, $checkoutClose),
    ],
    'workStart' => $workStart,
    'workEnd' => $workEnd,
    'cutoff' => $cutoff,
  ];
}
