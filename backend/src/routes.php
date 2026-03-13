<?php
declare(strict_types=1);

function route_request(mysqli $db): void {
  $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
  $path = request_path();
  if (!str_starts_with($path, '/api/')) {
    json_error('NOT_FOUND', 'Endpoint tidak ditemukan.', 404);
  }
  $p = substr($path, 4); // remove "/api"

  if ($method === 'POST' && $p === '/auth/login') {
    route_auth_login($db);
    return;
  }
  if ($method === 'POST' && $p === '/register/request') {
    route_register_request($db);
    return;
  }
  if ($method === 'GET' && $p === '/me') {
    $u = require_user($db);
    json_ok([
      'userId' => (int)$u['user_id'],
      'email' => $u['email'],
      'fullName' => $u['full_name'],
      'role' => $u['role'],
    ]);
  }
  if ($method === 'GET' && $p === '/units') {
    route_units_list($db);
    return;
  }
  if ($method === 'GET' && $p === '/public/units') {
    route_public_units_list($db);
    return;
  }

  if ($method === 'GET' && $p === '/settings') {
    require_user($db, ['ADMIN']);
    json_ok(get_settings($db));
  }
  if ($method === 'POST' && $p === '/settings') {
    route_admin_save_settings($db);
    return;
  }

  if ($method === 'GET' && $p === '/admin/registration-requests') {
    route_admin_registration_requests($db);
    return;
  }
  if ($method === 'POST' && preg_match('#^/admin/registration-requests/(\\d+)/(approve|reject)$#', $p, $m) === 1) {
    route_admin_registration_decide($db, (int)$m[1], $m[2]);
    return;
  }
  if ($method === 'GET' && $p === '/admin/interns') {
    route_admin_interns_list($db);
    return;
  }
  if ($method === 'GET' && $p === '/admin/mentors') {
    route_admin_mentors_list($db);
    return;
  }
  if (in_array($method, ['PUT', 'POST'], true) && preg_match('#^/admin/units/(\\d+)$#', $p, $m) === 1) {
    route_admin_units_update($db, (int)$m[1]);
    return;
  }
  if ($method === 'POST' && $p === '/admin/interns') {
    route_admin_interns_create($db);
    return;
  }
  if ($method === 'PUT' && preg_match('#^/admin/interns/(\\d+)$#', $p, $m) === 1) {
    route_admin_interns_update($db, (int)$m[1]);
    return;
  }
  if ($method === 'POST' && preg_match('#^/admin/interns/(\\d+)/(activate|deactivate)$#', $p, $m) === 1) {
    route_admin_interns_toggle($db, (int)$m[1], $m[2] === 'activate');
    return;
  }
  if (in_array($method, ['DELETE', 'POST'], true) && preg_match('#^/admin/interns/(\\d+)$#', $p, $m) === 1) {
    route_admin_interns_delete($db, (int)$m[1]);
    return;
  }
  if ($method === 'GET' && $p === '/admin/recap') {
    route_admin_recap($db);
    return;
  }
  if ($method === 'GET' && $p === '/admin/recap/export') {
    route_admin_recap_export($db);
    return;
  }

  if ($method === 'GET' && $p === '/intern/today') {
    route_intern_today($db);
    return;
  }
  if ($method === 'POST' && $p === '/attendance/check') {
    route_attendance_check($db);
    return;
  }
  if ($method === 'POST' && $p === '/leave/request') {
    route_leave_request($db);
    return;
  }

  if ($method === 'GET' && $p === '/mentor/interns') {
    route_mentor_interns($db);
    return;
  }
  if ($method === 'GET' && $p === '/mentor/units') {
    route_mentor_units($db);
    return;
  }
  if ($method === 'POST' && $p === '/mentor/interns') {
    route_mentor_interns_create($db);
    return;
  }
  if ($method === 'POST' && preg_match('#^/mentor/interns/(\\d+)/(activate|deactivate)$#', $p, $m) === 1) {
    route_mentor_interns_toggle($db, (int)$m[1], $m[2] === 'activate');
    return;
  }
  if (in_array($method, ['DELETE', 'POST'], true) && preg_match('#^/mentor/interns/(\\d+)$#', $p, $m) === 1) {
    route_mentor_interns_delete($db, (int)$m[1]);
    return;
  }
  if ($method === 'GET' && $p === '/mentor/leave') {
    route_mentor_leave_list($db);
    return;
  }
  if ($method === 'GET' && $p === '/mentor/recap') {
    route_mentor_recap($db);
    return;
  }
  if ($method === 'GET' && $p === '/mentor/recap/export') {
    route_mentor_recap_export($db);
    return;
  }
  if ($method === 'POST' && preg_match('#^/mentor/leave/(\\d+)/(approve|reject)$#', $p, $m) === 1) {
    route_mentor_leave_decide($db, (int)$m[1], $m[2]);
    return;
  }
  if ($method === 'POST' && preg_match('#^/mentor/attendance/(\\d+)/override$#', $p, $m) === 1) {
    route_mentor_attendance_override($db, (int)$m[1]);
    return;
  }

  if ($method === 'POST' && $p === '/system/finalize-day') {
    route_system_finalize_day($db);
    return;
  }

  json_error('NOT_FOUND', 'Endpoint tidak ditemukan.', 404);
}

function route_units_list(mysqli $db): void {
  require_user($db, ['ADMIN', 'PEMBIMBING', 'INTERN']);
  $rows = db_all($db, 'SELECT id, name, geofence_lat, geofence_lon, geofence_radius_m FROM units ORDER BY id');
  $out = array_map(fn($r) => [
    'id' => (int)$r['id'],
    'name' => $r['name'],
    'geofenceLat' => (float)$r['geofence_lat'],
    'geofenceLon' => (float)$r['geofence_lon'],
    'geofenceRadiusM' => (int)$r['geofence_radius_m'],
  ], $rows);
  json_ok($out);
}

function route_public_units_list(mysqli $db): void {
  $rows = db_all($db, 'SELECT id, name FROM units ORDER BY id');
  $out = array_map(fn($r) => ['id' => (int)$r['id'], 'name' => $r['name']], $rows);
  json_ok($out);
}

function route_register_request(mysqli $db): void {
  $body = json_body();
  require_fields($body, ['email', 'fullName', 'unitId', 'internshipStart', 'internshipEnd']);
  $email = strtolower(trim((string)$body['email']));
  $fullName = trim((string)$body['fullName']);
  $unitId = (int)$body['unitId'];
  $mentorUserId = array_key_exists('mentorUserId', $body) ? ($body['mentorUserId'] === null ? null : (int)$body['mentorUserId']) : null;
  $schoolName = trim((string)($body['schoolName'] ?? ''));
  $schoolAddress = trim((string)($body['schoolAddress'] ?? ''));
  $internshipStart = (string)$body['internshipStart'];
  $internshipEnd = (string)$body['internshipEnd'];
  $notes = trim((string)($body['notes'] ?? ''));

  if ($email === '' || $fullName === '') {
    json_error('BAD_INPUT', 'Email dan nama wajib diisi.', 422);
  }
  if ($internshipStart > $internshipEnd) {
    json_error('BAD_RANGE', 'internshipStart harus <= internshipEnd.', 422);
  }
  $unit = db_one($db, 'SELECT id FROM units WHERE id=? LIMIT 1', 'i', [$unitId]);
  if (!$unit) {
    json_error('NOT_FOUND', 'Unit tidak ditemukan.', 404);
  }
  $existingUser = db_one($db, 'SELECT id FROM users WHERE email=? LIMIT 1', 's', [$email]);
  if ($existingUser) {
    json_error('EMAIL_USED', 'Email sudah terdaftar. Hubungi admin jika butuh reset.', 409);
  }
  $existingPending = db_one($db, 'SELECT id FROM registration_requests WHERE email=? AND status="PENDING" LIMIT 1', 's', [$email]);
  if ($existingPending) {
    json_error('ALREADY_PENDING', 'Request pendaftaran kamu masih PENDING.', 409);
  }

  db_exec(
    $db,
    'INSERT INTO registration_requests (email, full_name, unit_id, mentor_user_id, school_name, school_address, internship_start, internship_end, notes, status, created_at)
     VALUES (?,?,?,?,?,?,?,?,?,"PENDING",NOW())',
    'ssiisssss',
    [$email, $fullName, $unitId, $mentorUserId, ($schoolName === '' ? null : $schoolName), ($schoolAddress === '' ? null : $schoolAddress), $internshipStart, $internshipEnd, $notes]
  );
  $id = (int)$db->insert_id;
  json_ok(['requestId' => $id, 'status' => 'PENDING'], 201);
}

function route_auth_login(mysqli $db): void {
  $body = json_body();
  require_fields($body, ['email', 'password']);
  $email = strtolower(trim((string)$body['email']));
  $password = (string)$body['password'];
  $user = db_one($db, 'SELECT id, email, full_name, role, password_hash FROM users WHERE email=? LIMIT 1', 's', [$email]);
  if (!$user || !password_verify($password, $user['password_hash'])) {
    json_error('INVALID_CREDENTIALS', 'Email atau password salah.', 401);
  }
  $token = issue_auth_token($db, (int)$user['id']);
  json_ok([
    'token' => $token,
    'user' => [
      'id' => (int)$user['id'],
      'email' => $user['email'],
      'fullName' => $user['full_name'],
      'role' => $user['role'],
    ],
  ]);
}

function route_admin_save_settings(mysqli $db): void {
  $u = require_user($db, ['ADMIN']);
  $body = json_body();
  $timezone = (string)($body['timezone'] ?? APP_TIMEZONE);
  $workStart = (string)($body['work_start_time'] ?? DEFAULT_WORK_START_TIME);
  $workEnd = (string)($body['work_end_time'] ?? DEFAULT_WORK_END_TIME);
  $tol = (int)($body['tolerance_minutes'] ?? DEFAULT_TOLERANCE_MINUTES);
  $cutoff = (string)($body['day_cutoff_time'] ?? DEFAULT_DAY_CUTOFF_TIME);
  $workdaysJson = json_encode($body['workdays'] ?? [1, 2, 3, 4, 5]);
  $offlineThreshold = (int)($body['offline_threshold_seconds'] ?? DEFAULT_OFFLINE_THRESHOLD_SECONDS);
  $qrTtl = (int)($body['qr_token_ttl_seconds'] ?? DEFAULT_QR_TTL_SECONDS);

  db_exec(
    $db,
    'INSERT INTO settings (id, timezone, work_start_time, work_end_time, tolerance_minutes, day_cutoff_time, workdays_json, offline_threshold_seconds, qr_token_ttl_seconds, updated_at, updated_by_user_id)
     VALUES (1,?,?,?,?,?,?,?,?,NOW(),?)
     ON DUPLICATE KEY UPDATE
       timezone=VALUES(timezone),
       work_start_time=VALUES(work_start_time),
       work_end_time=VALUES(work_end_time),
       tolerance_minutes=VALUES(tolerance_minutes),
       day_cutoff_time=VALUES(day_cutoff_time),
       workdays_json=VALUES(workdays_json),
       offline_threshold_seconds=VALUES(offline_threshold_seconds),
       qr_token_ttl_seconds=VALUES(qr_token_ttl_seconds),
       updated_at=NOW(),
       updated_by_user_id=VALUES(updated_by_user_id)',
    'sssissiii',
    [$timezone, $workStart, $workEnd, $tol, $cutoff, $workdaysJson, $offlineThreshold, $qrTtl, (int)$u['user_id']]
  );
  json_ok(get_settings($db));
}

function route_intern_today(mysqli $db): void {
  $u = require_user($db, ['INTERN']);
  $intern = db_one(
    $db,
    'SELECT i.unit_id, u.name AS unit_name, u.geofence_lat, u.geofence_lon, u.geofence_radius_m, i.internship_start, i.internship_end, i.active
     FROM interns i JOIN units u ON u.id=i.unit_id WHERE i.user_id=? LIMIT 1',
    'i',
    [(int)$u['user_id']]
  );
  if (!$intern) {
    json_error('NOT_FOUND', 'Data intern belum terdaftar.', 404);
  }
  $now = now_jakarta();
  $today = $now->format('Y-m-d');
  $rec = db_one($db, 'SELECT * FROM attendance_records WHERE intern_user_id=? AND date=? LIMIT 1', 'is', [(int)$u['user_id'], $today]);
  $settings = get_settings($db);
  $windows = attendance_windows($now, $settings);
  json_ok([
    'date' => $today,
    'unit' => [
      'id' => (int)$intern['unit_id'],
      'name' => $intern['unit_name'],
      'geofence' => [
        'lat' => (float)$intern['geofence_lat'],
        'lon' => (float)$intern['geofence_lon'],
        'radiusM' => (int)$intern['geofence_radius_m'],
      ],
    ],
    'attendance' => $rec ? attendance_to_dto($rec) : null,
    'availability' => [
      'checkin' => [
        'open' => $windows['checkin']['isOpen'],
        'opensAt' => $windows['checkin']['openAt']->format('Y-m-d H:i:s'),
        'closesAt' => $windows['checkin']['closeAt']->format('Y-m-d H:i:s'),
      ],
      'checkout' => [
        'open' => $windows['checkout']['isOpen'],
        'opensAt' => $windows['checkout']['openAt']->format('Y-m-d H:i:s'),
        'closesAt' => $windows['checkout']['closeAt']->format('Y-m-d H:i:s'),
      ],
    ],
    'serverTime' => $now->format('Y-m-d H:i:s'),
    'timezone' => $settings['timezone'] ?? APP_TIMEZONE,
    'isWorkday' => is_workday($db, $now),
  ]);
}

function route_attendance_check(mysqli $db): void {
  $u = require_user($db, ['INTERN']);
  $body = json_body();
  require_fields($body, ['action', 'lat', 'lon']);
  $action = strtolower(trim((string)$body['action']));
  if (!in_array($action, ['checkin', 'checkout'], true)) {
    json_error('BAD_ACTION', 'Action harus "checkin" atau "checkout".', 422);
  }
  $lat = (float)$body['lat'];
  $lon = (float)$body['lon'];

  $now = now_jakarta();
  if (!is_workday($db, $now)) {
    json_error('NOT_WORKDAY', 'Hari ini bukan hari kerja / hari libur.', 409);
  }

  $intern = db_one(
    $db,
    'SELECT i.unit_id, i.internship_start, i.internship_end, i.active, u.geofence_lat, u.geofence_lon, u.geofence_radius_m
     FROM interns i
     JOIN units u ON u.id=i.unit_id
     WHERE i.user_id=? LIMIT 1',
    'i',
    [(int)$u['user_id']]
  );
  if (!$intern || (int)$intern['active'] !== 1) {
    json_error('INTERN_INACTIVE', 'Intern tidak aktif.', 403);
  }
  $start = new DateTimeImmutable($intern['internship_start'], new DateTimeZone(APP_TIMEZONE));
  $end = new DateTimeImmutable($intern['internship_end'], new DateTimeZone(APP_TIMEZONE));
  if ($now < $start || $now > $end) {
    json_error('OUTSIDE_PERIOD', 'Di luar periode PKL/magang.', 403);
  }

  $gfLat = (float)$intern['geofence_lat'];
  $gfLon = (float)$intern['geofence_lon'];
  $gfR = (int)$intern['geofence_radius_m'];
  $dist = haversine_m($lat, $lon, $gfLat, $gfLon);
  if ($dist > $gfR) {
    json_error('OUT_OF_AREA', 'Di luar area geofence.', 403, ['distanceM' => $dist, 'radiusM' => $gfR]);
  }

  $settings = get_settings($db);
  $windows = attendance_windows($now, $settings);
  if ($action === 'checkin' && !$windows['checkin']['isOpen']) {
    json_error('CHECKIN_CLOSED', 'Belum/diluar jam check-in.', 403, [
      'opensAt' => $windows['checkin']['openAt']->format('Y-m-d H:i:s'),
      'closesAt' => $windows['checkin']['closeAt']->format('Y-m-d H:i:s'),
      'timezone' => $settings['timezone'] ?? APP_TIMEZONE,
    ]);
  }
  if ($action === 'checkout' && !$windows['checkout']['isOpen']) {
    json_error('CHECKOUT_CLOSED', 'Belum/diluar jam check-out.', 403, [
      'opensAt' => $windows['checkout']['openAt']->format('Y-m-d H:i:s'),
      'closesAt' => $windows['checkout']['closeAt']->format('Y-m-d H:i:s'),
      'timezone' => $settings['timezone'] ?? APP_TIMEZONE,
    ]);
  }

  $date = $now->format('Y-m-d');
  $rec = db_one($db, 'SELECT * FROM attendance_records WHERE intern_user_id=? AND date=? LIMIT 1', 'is', [(int)$u['user_id'], $date]);

  $workStart = (string)($settings['work_start_time'] ?? DEFAULT_WORK_START_TIME);
  $tolMin = (int)($settings['tolerance_minutes'] ?? DEFAULT_TOLERANCE_MINUTES);
  $tz = new DateTimeZone($settings['timezone'] ?? APP_TIMEZONE);
  $startDt = new DateTimeImmutable($date . ' ' . $workStart, $tz);
  $limit = $startDt->modify("+{$tolMin} minutes");
  $unitId = (int)$intern['unit_id'];

  if ($action === 'checkin') {
    if ($rec && $rec['check_in_at'] !== null) {
      json_error('ALREADY_CHECKED_IN', 'Kamu sudah check-in hari ini.', 409);
    }
    $status = ($now <= $limit) ? 'HADIR' : 'TERLAMBAT';
    if ($rec) {
      db_exec(
        $db,
        'UPDATE attendance_records
         SET check_in_at=?, status=?, status_marked_by="SYSTEM", gps_check_in_lat=?, gps_check_in_lon=?, updated_at=NOW()
         WHERE id=?',
        'ssddi',
        [$now->format('Y-m-d H:i:s'), $status, $lat, $lon, (int)$rec['id']]
      );
      $rec = db_one($db, 'SELECT * FROM attendance_records WHERE id=? LIMIT 1', 'i', [(int)$rec['id']]);
    } else {
      db_exec(
        $db,
        'INSERT INTO attendance_records (intern_user_id, unit_id, date, check_in_at, status, status_marked_by, gps_check_in_lat, gps_check_in_lon, checkout_missing, created_at, updated_at)
         VALUES (?,?,?,? ,?, "SYSTEM", ?,?, 0, NOW(), NOW())',
        'iisssdd',
        [(int)$u['user_id'], $unitId, $date, $now->format('Y-m-d H:i:s'), $status, $lat, $lon]
      );
      $newId = (int)$db->insert_id;
      $rec = db_one($db, 'SELECT * FROM attendance_records WHERE id=? LIMIT 1', 'i', [$newId]);
    }
    json_ok(['attendance' => attendance_to_dto($rec), 'result' => ['status' => $status]]);
  }

  if (!$rec || $rec['check_in_at'] === null) {
    json_error('NO_CHECKIN', 'Belum ada check-in hari ini.', 409);
  }
  if ($rec['check_out_at'] !== null) {
    json_error('ALREADY_CHECKED_OUT', 'Kamu sudah check-out hari ini.', 409);
  }
  db_exec(
    $db,
    'UPDATE attendance_records
     SET check_out_at=?, gps_check_out_lat=?, gps_check_out_lon=?, checkout_missing=0, updated_at=NOW()
     WHERE id=?',
    'sddi',
    [$now->format('Y-m-d H:i:s'), $lat, $lon, (int)$rec['id']]
  );
  $rec = db_one($db, 'SELECT * FROM attendance_records WHERE id=? LIMIT 1', 'i', [(int)$rec['id']]);
  json_ok(['attendance' => attendance_to_dto($rec), 'result' => ['status' => $rec['status']]]);
}

function route_leave_request(mysqli $db): void {
  $u = require_user($db, ['INTERN']);
  $body = json_body();
  require_fields($body, ['type', 'dateFrom', 'dateTo', 'reason']);
  $type = strtoupper(trim((string)$body['type']));
  if (!in_array($type, ['IZIN', 'SAKIT'], true)) {
    json_error('BAD_TYPE', 'Type harus IZIN atau SAKIT.', 422);
  }
  $dateFrom = (string)$body['dateFrom'];
  $dateTo = (string)$body['dateTo'];
  if ($dateFrom > $dateTo) {
    json_error('BAD_RANGE', 'dateFrom harus <= dateTo.', 422);
  }
  $reason = trim((string)$body['reason']);
  $attachmentBase64 = trim((string)($body['attachmentBase64'] ?? ''));
  $attachmentName = trim((string)($body['attachmentName'] ?? ''));
  if ($type === 'SAKIT' && $attachmentBase64 === '') {
    json_error('ATTACHMENT_REQUIRED', 'Gambar belum diupload.', 422);
  }

  $attachmentUrl = null;
  if ($attachmentBase64 !== '') {
    $attachmentUrl = save_base64_attachment($attachmentBase64, $attachmentName, (int)$u['user_id']);
    if ($attachmentUrl === null) {
      json_error('ATTACHMENT_INVALID', 'File bukti tidak valid.', 422);
    }
  }
  db_exec(
    $db,
    'INSERT INTO leave_requests (intern_user_id, type, date_from, date_to, reason, attachment_url, status, created_at)
     VALUES (?,?,?,?,?,?,"PENDING",NOW())',
    'isssss',
    [(int)$u['user_id'], $type, $dateFrom, $dateTo, $reason, $attachmentUrl]
  );
  $id = (int)$db->insert_id;
  $row = db_one($db, 'SELECT * FROM leave_requests WHERE id=? LIMIT 1', 'i', [$id]);
  json_ok(['leave' => $row], 201);
}

function route_mentor_interns(mysqli $db): void {
  $u = require_user($db, ['PEMBIMBING', 'ADMIN']);
  if ($u['role'] === 'ADMIN') {
    $interns = db_all(
      $db,
      'SELECT i.user_id, u.full_name, u.email, un.name AS unit_name, i.active, i.school_name, i.school_address, i.internship_start, i.internship_end
       FROM interns i
       JOIN users u ON u.id=i.user_id
       JOIN units un ON un.id=i.unit_id
       ORDER BY u.full_name'
    );
  } else {
    $interns = db_all(
      $db,
      'SELECT i.user_id, u.full_name, u.email, un.name AS unit_name, i.active, i.school_name, i.school_address, i.internship_start, i.internship_end
       FROM interns i
       JOIN users u ON u.id=i.user_id
       JOIN units un ON un.id=i.unit_id
       WHERE i.mentor_user_id=?
       ORDER BY u.full_name',
      'i',
      [(int)$u['user_id']]
    );
  }
  $out = array_map(fn($r) => [
    'userId' => (int)$r['user_id'],
    'fullName' => $r['full_name'],
    'email' => $r['email'],
    'unitName' => $r['unit_name'],
    'active' => (int)$r['active'] === 1,
    'schoolName' => $r['school_name'],
    'schoolAddress' => $r['school_address'],
    'internshipStart' => $r['internship_start'],
    'internshipEnd' => $r['internship_end'],
  ], $interns);
  json_ok($out);
}

function route_mentor_leave_list(mysqli $db): void {
  $u = require_user($db, ['PEMBIMBING', 'ADMIN']);
  if ($u['role'] === 'ADMIN') {
    $rows = db_all(
      $db,
      'SELECT lr.*, u.full_name
       FROM leave_requests lr
       JOIN users u ON u.id=lr.intern_user_id
       ORDER BY lr.id DESC'
    );
  } else {
    $rows = db_all(
      $db,
      'SELECT lr.*, u.full_name
       FROM leave_requests lr
       JOIN users u ON u.id=lr.intern_user_id
       JOIN interns i ON i.user_id=lr.intern_user_id
       WHERE i.mentor_user_id=?
       ORDER BY lr.id DESC',
      'i',
      [(int)$u['user_id']]
    );
  }
  json_ok($rows);
}

function route_mentor_leave_decide(mysqli $db, int $leaveId, string $decision): void {
  $u = require_user($db, ['PEMBIMBING', 'ADMIN']);
  $body = json_body();
  $reason = trim((string)($body['reason'] ?? ''));
  $leave = db_one($db, 'SELECT * FROM leave_requests WHERE id=? LIMIT 1', 'i', [$leaveId]);
  if (!$leave) {
    json_error('NOT_FOUND', 'Leave request tidak ditemukan.', 404);
  }
  if ($u['role'] === 'PEMBIMBING') {
    $own = db_one($db, 'SELECT 1 FROM interns WHERE user_id=? AND mentor_user_id=? LIMIT 1', 'ii', [(int)$leave['intern_user_id'], (int)$u['user_id']]);
    if (!$own) {
      json_error('FORBIDDEN', 'Bukan intern bimbingan kamu.', 403);
    }
  }
  if ($leave['status'] !== 'PENDING') {
    json_error('INVALID_STATE', 'Request sudah diputus.', 409);
  }
  $newStatus = ($decision === 'approve') ? 'APPROVED' : 'REJECTED';
  db_exec($db, 'UPDATE leave_requests SET status=?, decided_by_user_id=?, decided_at=NOW() WHERE id=?', 'sii', [$newStatus, (int)$u['user_id'], $leaveId]);
  audit_log($db, (int)$u['user_id'], 'LEAVE_DECIDE', 'leave_requests', $leaveId, $leave, ['status' => $newStatus], $reason);
  $updated = db_one($db, 'SELECT * FROM leave_requests WHERE id=? LIMIT 1', 'i', [$leaveId]);
  json_ok($updated);
}

function route_mentor_attendance_override(mysqli $db, int $attendanceId): void {
  $u = require_user($db, ['PEMBIMBING', 'ADMIN']);
  $body = json_body();
  require_fields($body, ['status', 'reason']);
  $status = strtoupper(trim((string)$body['status']));
  $reason = trim((string)$body['reason']);
  if (!in_array($status, ['HADIR', 'TERLAMBAT', 'ALPA', 'IZIN', 'SAKIT'], true)) {
    json_error('BAD_STATUS', 'Status tidak valid.', 422);
  }
  $rec = db_one($db, 'SELECT * FROM attendance_records WHERE id=? LIMIT 1', 'i', [$attendanceId]);
  if (!$rec) {
    json_error('NOT_FOUND', 'AttendanceRecord tidak ditemukan.', 404);
  }
  if ($u['role'] === 'PEMBIMBING') {
    $own = db_one($db, 'SELECT 1 FROM interns WHERE user_id=? AND mentor_user_id=? LIMIT 1', 'ii', [(int)$rec['intern_user_id'], (int)$u['user_id']]);
    if (!$own) {
      json_error('FORBIDDEN', 'Bukan intern bimbingan kamu.', 403);
    }
  }
  $markedBy = ($u['role'] === 'ADMIN') ? 'ADMIN' : 'PEMBIMBING';
  db_exec($db, 'UPDATE attendance_records SET status=?, status_marked_by=?, updated_at=NOW() WHERE id=?', 'ssi', [$status, $markedBy, $attendanceId]);
  audit_log($db, (int)$u['user_id'], 'ATTENDANCE_OVERRIDE', 'attendance_records', $attendanceId, $rec, ['status' => $status, 'status_marked_by' => $markedBy], $reason);
  $updated = db_one($db, 'SELECT * FROM attendance_records WHERE id=? LIMIT 1', 'i', [$attendanceId]);
  json_ok(attendance_to_dto($updated));
}

function route_admin_recap(mysqli $db): void {
  require_user($db, ['ADMIN']);
  $dateFrom = $_GET['dateFrom'] ?? today_ymd();
  $dateTo = $_GET['dateTo'] ?? today_ymd();
  if (!is_string($dateFrom) || !is_string($dateTo) || $dateFrom > $dateTo) {
    json_error('BAD_RANGE', 'dateFrom harus <= dateTo.', 422);
  }
  $internUserId = isset($_GET['internUserId']) ? (int)$_GET['internUserId'] : null;

  $where = 'ar.date BETWEEN ? AND ?';
  $types = 'ss';
  $params = [$dateFrom, $dateTo];
  if ($internUserId) {
    $where .= ' AND ar.intern_user_id=?';
    $types .= 'i';
    $params[] = $internUserId;
  }

  $rows = db_all(
    $db,
    "SELECT ar.*, u.full_name, un.name AS unit_name
     FROM attendance_records ar
     JOIN users u ON u.id=ar.intern_user_id
     JOIN units un ON un.id=ar.unit_id
     WHERE $where
     ORDER BY ar.date DESC, u.full_name",
    $types,
    $params
  );

  $summary = [
    'HADIR' => 0,
    'TERLAMBAT' => 0,
    'IZIN' => 0,
    'SAKIT' => 0,
    'ALPA' => 0,
    'CHECKOUT_MISSING' => 0,
  ];
  foreach ($rows as $r) {
    $st = $r['status'];
    if (isset($summary[$st])) {
      $summary[$st]++;
    }
    if ((int)$r['checkout_missing'] === 1) {
      $summary['CHECKOUT_MISSING']++;
    }
  }

  $items = array_map(fn($r) => [
    'id' => (int)$r['id'],
    'date' => $r['date'],
    'internUserId' => (int)$r['intern_user_id'],
    'internName' => $r['full_name'],
    'unitName' => $r['unit_name'],
    'status' => $r['status'],
    'markedBy' => $r['status_marked_by'],
    'checkInAt' => $r['check_in_at'],
    'checkOutAt' => $r['check_out_at'],
    'checkoutMissing' => (int)$r['checkout_missing'] === 1,
  ], $rows);

  json_ok(['summary' => $summary, 'items' => $items]);
}

function route_admin_recap_export(mysqli $db): void {
  require_user($db, ['ADMIN']);
  $format = strtolower((string)($_GET['format'] ?? 'csv'));
  if ($format !== 'csv') {
    json_error('BAD_FORMAT', 'Saat ini hanya mendukung format=csv.', 422);
  }
  $dateFrom = $_GET['dateFrom'] ?? today_ymd();
  $dateTo = $_GET['dateTo'] ?? today_ymd();
  if (!is_string($dateFrom) || !is_string($dateTo) || $dateFrom > $dateTo) {
    json_error('BAD_RANGE', 'dateFrom harus <= dateTo.', 422);
  }

  $rows = db_all(
    $db,
    'SELECT ar.date, u.full_name, u.email, un.name AS unit_name, ar.status, ar.status_marked_by, ar.check_in_at, ar.check_out_at, ar.checkout_missing
     FROM attendance_records ar
     JOIN users u ON u.id=ar.intern_user_id
     JOIN units un ON un.id=ar.unit_id
     WHERE ar.date BETWEEN ? AND ?
     ORDER BY ar.date DESC, u.full_name',
    'ss',
    [$dateFrom, $dateTo]
  );

  header('Content-Type: text/csv; charset=utf-8');
  header('Content-Disposition: attachment; filename="rekap_' . $dateFrom . '_' . $dateTo . '.csv"');
  $out = fopen('php://output', 'w');
  fputcsv($out, ['date', 'intern_name', 'email', 'unit', 'status', 'marked_by', 'check_in_at', 'check_out_at', 'checkout_missing']);
  foreach ($rows as $r) {
    fputcsv($out, [
      $r['date'],
      $r['full_name'],
      $r['email'],
      $r['unit_name'],
      $r['status'],
      $r['status_marked_by'],
      $r['check_in_at'],
      $r['check_out_at'],
      $r['checkout_missing'],
    ]);
  }
  fclose($out);
  exit;
}

function route_mentor_recap(mysqli $db): void {
  $u = require_user($db, ['PEMBIMBING']);
  $dateFrom = $_GET['dateFrom'] ?? today_ymd();
  $dateTo = $_GET['dateTo'] ?? today_ymd();
  if (!is_string($dateFrom) || !is_string($dateTo) || $dateFrom > $dateTo) {
    json_error('BAD_RANGE', 'dateFrom harus <= dateTo.', 422);
  }
  $internUserId = isset($_GET['internUserId']) ? (int)$_GET['internUserId'] : null;

  $where = 'ar.date BETWEEN ? AND ? AND i.mentor_user_id=?';
  $types = 'ssi';
  $params = [$dateFrom, $dateTo, (int)$u['user_id']];
  if ($internUserId) {
    $where .= ' AND ar.intern_user_id=?';
    $types .= 'i';
    $params[] = $internUserId;
  }

  $rows = db_all(
    $db,
    "SELECT ar.*, u.full_name, un.name AS unit_name
     FROM attendance_records ar
     JOIN users u ON u.id=ar.intern_user_id
     JOIN units un ON un.id=ar.unit_id
     JOIN interns i ON i.user_id=ar.intern_user_id
     WHERE $where
     ORDER BY ar.date DESC, u.full_name",
    $types,
    $params
  );

  $summary = [
    'HADIR' => 0,
    'TERLAMBAT' => 0,
    'IZIN' => 0,
    'SAKIT' => 0,
    'ALPA' => 0,
    'CHECKOUT_MISSING' => 0,
  ];
  foreach ($rows as $r) {
    $st = $r['status'];
    if (isset($summary[$st])) {
      $summary[$st]++;
    }
    if ((int)$r['checkout_missing'] === 1) {
      $summary['CHECKOUT_MISSING']++;
    }
  }

  $items = array_map(fn($r) => [
    'id' => (int)$r['id'],
    'date' => $r['date'],
    'internUserId' => (int)$r['intern_user_id'],
    'internName' => $r['full_name'],
    'unitName' => $r['unit_name'],
    'status' => $r['status'],
    'markedBy' => $r['status_marked_by'],
    'checkInAt' => $r['check_in_at'],
    'checkOutAt' => $r['check_out_at'],
    'checkoutMissing' => (int)$r['checkout_missing'] === 1,
  ], $rows);

  json_ok(['summary' => $summary, 'items' => $items]);
}

function route_mentor_recap_export(mysqli $db): void {
  $u = require_user($db, ['PEMBIMBING']);
  $format = strtolower((string)($_GET['format'] ?? 'csv'));
  if ($format !== 'csv') {
    json_error('BAD_FORMAT', 'Saat ini hanya mendukung format=csv.', 422);
  }
  $dateFrom = $_GET['dateFrom'] ?? today_ymd();
  $dateTo = $_GET['dateTo'] ?? today_ymd();
  if (!is_string($dateFrom) || !is_string($dateTo) || $dateFrom > $dateTo) {
    json_error('BAD_RANGE', 'dateFrom harus <= dateTo.', 422);
  }

  $rows = db_all(
    $db,
    'SELECT ar.date, u.full_name, u.email, un.name AS unit_name, ar.status, ar.status_marked_by, ar.check_in_at, ar.check_out_at, ar.checkout_missing
     FROM attendance_records ar
     JOIN users u ON u.id=ar.intern_user_id
     JOIN units un ON un.id=ar.unit_id
     JOIN interns i ON i.user_id=ar.intern_user_id
     WHERE ar.date BETWEEN ? AND ? AND i.mentor_user_id=?
     ORDER BY ar.date DESC, u.full_name',
    'ssi',
    [$dateFrom, $dateTo, (int)$u['user_id']]
  );

  header('Content-Type: text/csv; charset=utf-8');
  header('Content-Disposition: attachment; filename="rekap_mentor_' . $dateFrom . '_' . $dateTo . '.csv"');
  $out = fopen('php://output', 'w');
  fputcsv($out, ['date', 'intern_name', 'email', 'unit', 'status', 'marked_by', 'check_in_at', 'check_out_at', 'checkout_missing']);
  foreach ($rows as $r) {
    fputcsv($out, [
      $r['date'],
      $r['full_name'],
      $r['email'],
      $r['unit_name'],
      $r['status'],
      $r['status_marked_by'],
      $r['check_in_at'],
      $r['check_out_at'],
      $r['checkout_missing'],
    ]);
  }
  fclose($out);
  exit;
}

function route_system_finalize_day(mysqli $db): void {
  require_user($db, ['ADMIN']);
  $body = json_body();
  $date = (string)($body['date'] ?? '');
  if ($date === '') {
    json_error('MISSING_FIELDS', 'date wajib diisi (YYYY-MM-DD).', 422);
  }

  $target = new DateTimeImmutable($date . ' 00:00:00', new DateTimeZone(APP_TIMEZONE));
  $today = new DateTimeImmutable(today_ymd() . ' 00:00:00', new DateTimeZone(APP_TIMEZONE));
  if ($target >= $today) {
    json_error('INVALID_DATE', 'Finalize hanya untuk tanggal sebelum hari ini.', 409);
  }

  db_exec(
    $db,
    'UPDATE attendance_records SET checkout_missing=1, updated_at=NOW()
     WHERE date=? AND check_in_at IS NOT NULL AND check_out_at IS NULL',
    's',
    [$date]
  );

  $interns = db_all($db, 'SELECT user_id, unit_id FROM interns WHERE active=1');
  $created = 0;
  foreach ($interns as $i) {
    $uid = (int)$i['user_id'];
    $exists = db_one($db, 'SELECT id FROM attendance_records WHERE intern_user_id=? AND date=? LIMIT 1', 'is', [$uid, $date]);
    if ($exists) {
      continue;
    }
    $leave = db_one(
      $db,
      'SELECT id, type FROM leave_requests
       WHERE intern_user_id=? AND status="APPROVED" AND date_from <= ? AND date_to >= ?
       LIMIT 1',
      'iss',
      [$uid, $date, $date]
    );
    if ($leave) {
      $status = $leave['type']; // IZIN/SAKIT
      db_exec(
        $db,
        'INSERT INTO attendance_records (intern_user_id, unit_id, date, status, status_marked_by, checkout_missing, created_at, updated_at)
         VALUES (?,?,?,?,"SYSTEM",0,NOW(),NOW())',
        'iiss',
        [$uid, (int)$i['unit_id'], $date, $status]
      );
      $created++;
      continue;
    }
    db_exec(
      $db,
      'INSERT INTO attendance_records (intern_user_id, unit_id, date, status, status_marked_by, checkout_missing, created_at, updated_at)
       VALUES (?,?,?,"ALPA","SYSTEM",0,NOW(),NOW())',
      'iis',
      [$uid, (int)$i['unit_id'], $date]
    );
    $created++;
  }

  json_ok(['date' => $date, 'createdOrFilled' => $created]);
}

function attendance_to_dto(array $r): array {
  return [
    'id' => (int)$r['id'],
    'date' => $r['date'],
    'status' => $r['status'],
    'markedBy' => $r['status_marked_by'],
    'checkInAt' => $r['check_in_at'],
    'checkOutAt' => $r['check_out_at'],
    'checkoutMissing' => (int)$r['checkout_missing'] === 1,
  ];
}

function audit_log(mysqli $db, int $actorUserId, string $action, string $entityType, int $entityId, $before, $after, string $reason = ''): void {
  $beforeJson = json_encode($before, JSON_UNESCAPED_UNICODE);
  $afterJson = json_encode($after, JSON_UNESCAPED_UNICODE);
  db_exec(
    $db,
    'INSERT INTO audit_logs (actor_user_id, action, entity_type, entity_id, before_json, after_json, reason, created_at)
     VALUES (?,?,?,?,?,?,?,NOW())',
    'ississs',
    [$actorUserId, $action, $entityType, $entityId, $beforeJson, $afterJson, $reason]
  );
}

function route_admin_registration_requests(mysqli $db): void {
  require_user($db, ['ADMIN']);
  $status = strtoupper((string)($_GET['status'] ?? 'PENDING'));
  if (!in_array($status, ['PENDING', 'APPROVED', 'REJECTED'], true)) {
    $status = 'PENDING';
  }
  $rows = db_all(
    $db,
    'SELECT rr.*, u.name AS unit_name, m.full_name AS mentor_name
     FROM registration_requests rr
     JOIN units u ON u.id=rr.unit_id
     LEFT JOIN users m ON m.id=rr.mentor_user_id
     WHERE rr.status=?
     ORDER BY rr.id DESC',
    's',
    [$status]
  );
  json_ok($rows);
}

function route_admin_registration_decide(mysqli $db, int $requestId, string $decision): void {
  $u = require_user($db, ['ADMIN']);
  $body = json_body();
  $reason = trim((string)($body['reason'] ?? ''));

  $req = db_one($db, 'SELECT * FROM registration_requests WHERE id=? LIMIT 1', 'i', [$requestId]);
  if (!$req) {
    json_error('NOT_FOUND', 'Request tidak ditemukan.', 404);
  }
  if ($req['status'] !== 'PENDING') {
    json_error('INVALID_STATE', 'Request sudah diputus.', 409);
  }

  if ($decision === 'reject') {
    db_exec(
      $db,
      'UPDATE registration_requests SET status="REJECTED", decided_by_user_id=?, decided_at=NOW(), decision_reason=? WHERE id=?',
      'isi',
      [(int)$u['user_id'], $reason, $requestId]
    );
    audit_log($db, (int)$u['user_id'], 'REG_REQUEST_REJECT', 'registration_requests', $requestId, $req, ['status' => 'REJECTED'], $reason);
    $updated = db_one($db, 'SELECT * FROM registration_requests WHERE id=? LIMIT 1', 'i', [$requestId]);
    json_ok(['request' => $updated]);
  }

  // approve → create INTERN user + interns row
  $email = (string)$req['email'];
  $exists = db_one($db, 'SELECT id FROM users WHERE email=? LIMIT 1', 's', [$email]);
  if ($exists) {
    json_error('EMAIL_USED', 'Email sudah terdaftar.', 409);
  }

  $mentorUserId = array_key_exists('mentorUserId', $body)
    ? ($body['mentorUserId'] === null ? null : (int)$body['mentorUserId'])
    : ($req['mentor_user_id'] !== null ? (int)$req['mentor_user_id'] : null);
  $unitId = array_key_exists('unitId', $body) ? (int)$body['unitId'] : (int)$req['unit_id'];
  $start = (string)($body['internshipStart'] ?? $req['internship_start']);
  $end = (string)($body['internshipEnd'] ?? $req['internship_end']);
  $schoolName = trim((string)($body['schoolName'] ?? ($req['school_name'] ?? '')));
  $schoolAddress = trim((string)($body['schoolAddress'] ?? ($req['school_address'] ?? '')));
  if ($start > $end) {
    json_error('BAD_RANGE', 'internshipStart harus <= internshipEnd.', 422);
  }

  $tempPassword = trim((string)($body['tempPassword'] ?? ''));
  if ($tempPassword === '') {
    $tempPassword = 'Temp' . strtoupper(substr(bin2hex(random_bytes(3)), 0, 6)) . '!';
  }
  $passwordHash = password_hash($tempPassword, PASSWORD_DEFAULT);

  $fullName = (string)$req['full_name'];
  db_exec(
    $db,
    'INSERT INTO users (email, full_name, role, password_hash, created_at) VALUES (?,?, "INTERN", ?, NOW())',
    'sss',
    [$email, $fullName, $passwordHash]
  );
  $newUserId = (int)$db->insert_id;

  db_exec(
    $db,
    'INSERT INTO interns (user_id, unit_id, mentor_user_id, school_name, school_address, internship_start, internship_end, active)
     VALUES (?,?,?,?,?,?,?,1)',
    'iiissss',
    [$newUserId, $unitId, $mentorUserId, ($schoolName === '' ? null : $schoolName), ($schoolAddress === '' ? null : $schoolAddress), $start, $end]
  );

  db_exec(
    $db,
    'UPDATE registration_requests
     SET status="APPROVED", decided_by_user_id=?, decided_at=NOW(), decision_reason=?, mentor_user_id=?, unit_id=?, school_name=?, school_address=?, internship_start=?, internship_end=?
     WHERE id=?',
    'isiissssi',
    [(int)$u['user_id'], $reason, $mentorUserId, $unitId, ($schoolName === '' ? null : $schoolName), ($schoolAddress === '' ? null : $schoolAddress), $start, $end, $requestId]
  );
  audit_log(
    $db,
    (int)$u['user_id'],
    'REG_REQUEST_APPROVE',
    'registration_requests',
    $requestId,
    $req,
    ['status' => 'APPROVED', 'created_user_id' => $newUserId],
    $reason
  );
  json_ok(['createdUserId' => $newUserId, 'tempPassword' => $tempPassword]);
}

function route_admin_mentors_list(mysqli $db): void {
  require_user($db, ['ADMIN']);
  $rows = db_all($db, 'SELECT id, email, full_name FROM users WHERE role="PEMBIMBING" ORDER BY full_name');
  $out = array_map(fn($r) => ['id' => (int)$r['id'], 'email' => $r['email'], 'fullName' => $r['full_name']], $rows);
  json_ok($out);
}

function route_admin_interns_list(mysqli $db): void {
  require_user($db, ['ADMIN']);
  $rows = db_all(
    $db,
    'SELECT i.user_id, u.full_name, u.email, i.unit_id, un.name AS unit_name, i.mentor_user_id, m.full_name AS mentor_name,
            i.school_name, i.school_address, i.internship_start, i.internship_end, i.active
     FROM interns i
     JOIN users u ON u.id=i.user_id
     JOIN units un ON un.id=i.unit_id
     LEFT JOIN users m ON m.id=i.mentor_user_id
     ORDER BY u.full_name'
  );
  json_ok($rows);
}

function route_admin_interns_create(mysqli $db): void {
  $u = require_user($db, ['ADMIN']);
  $body = json_body();
  require_fields($body, ['email', 'fullName', 'unitId', 'internshipStart', 'internshipEnd']);
  $email = strtolower(trim((string)$body['email']));
  $fullName = trim((string)$body['fullName']);
  $unitId = (int)$body['unitId'];
  $mentorUserId = array_key_exists('mentorUserId', $body) ? ($body['mentorUserId'] === null ? null : (int)$body['mentorUserId']) : null;
  $schoolName = trim((string)($body['schoolName'] ?? ''));
  $schoolAddress = trim((string)($body['schoolAddress'] ?? ''));
  $start = (string)$body['internshipStart'];
  $end = (string)$body['internshipEnd'];
  $password = trim((string)($body['password'] ?? ''));
  if ($password === '') {
    $password = 'Temp' . strtoupper(substr(bin2hex(random_bytes(3)), 0, 6)) . '!';
  }
  if ($start > $end) {
    json_error('BAD_RANGE', 'internshipStart harus <= internshipEnd.', 422);
  }
  $exists = db_one($db, 'SELECT id FROM users WHERE email=? LIMIT 1', 's', [$email]);
  if ($exists) {
    json_error('EMAIL_USED', 'Email sudah terdaftar.', 409);
  }

  $hash = password_hash($password, PASSWORD_DEFAULT);
  db_exec(
    $db,
    'INSERT INTO users (email, full_name, role, password_hash, created_at) VALUES (?,?, "INTERN", ?, NOW())',
    'sss',
    [$email, $fullName, $hash]
  );
  $newUserId = (int)$db->insert_id;
  db_exec(
    $db,
    'INSERT INTO interns (user_id, unit_id, mentor_user_id, school_name, school_address, internship_start, internship_end, active)
     VALUES (?,?,?,?,?,?,?,1)',
    'iiissss',
    [$newUserId, $unitId, $mentorUserId, ($schoolName === '' ? null : $schoolName), ($schoolAddress === '' ? null : $schoolAddress), $start, $end]
  );
  audit_log($db, (int)$u['user_id'], 'ADMIN_INTERN_CREATE', 'interns', $newUserId, null, ['email' => $email, 'userId' => $newUserId], 'create');
  json_ok(['userId' => $newUserId, 'tempPassword' => $password], 201);
}

function route_admin_interns_update(mysqli $db, int $userId): void {
  $u = require_user($db, ['ADMIN']);
  $body = json_body();
  $intern = db_one($db, 'SELECT * FROM interns WHERE user_id=? LIMIT 1', 'i', [$userId]);
  if (!$intern) {
    json_error('NOT_FOUND', 'Intern tidak ditemukan.', 404);
  }
  $before = $intern;
  $unitId = isset($body['unitId']) ? (int)$body['unitId'] : (int)$intern['unit_id'];
  $mentorUserId = array_key_exists('mentorUserId', $body)
    ? ($body['mentorUserId'] === null ? null : (int)$body['mentorUserId'])
    : ($intern['mentor_user_id'] !== null ? (int)$intern['mentor_user_id'] : null);
  $schoolName = array_key_exists('schoolName', $body) ? trim((string)($body['schoolName'] ?? '')) : (string)($intern['school_name'] ?? '');
  $schoolAddress = array_key_exists('schoolAddress', $body) ? trim((string)($body['schoolAddress'] ?? '')) : (string)($intern['school_address'] ?? '');
  $start = (string)($body['internshipStart'] ?? $intern['internship_start']);
  $end = (string)($body['internshipEnd'] ?? $intern['internship_end']);
  $active = isset($body['active']) ? ((bool)$body['active'] ? 1 : 0) : (int)$intern['active'];
  if ($start > $end) {
    json_error('BAD_RANGE', 'internshipStart harus <= internshipEnd.', 422);
  }
  db_exec(
    $db,
    'UPDATE interns SET unit_id=?, mentor_user_id=?, school_name=?, school_address=?, internship_start=?, internship_end=?, active=? WHERE user_id=?',
    'iissssii',
    [$unitId, $mentorUserId, ($schoolName === '' ? null : $schoolName), ($schoolAddress === '' ? null : $schoolAddress), $start, $end, $active, $userId]
  );
  audit_log($db, (int)$u['user_id'], 'ADMIN_INTERN_UPDATE', 'interns', $userId, $before, ['unitId' => $unitId, 'mentorUserId' => $mentorUserId, 'active' => $active], 'update');
  json_ok(['ok' => true]);
}

function route_admin_interns_toggle(mysqli $db, int $userId, bool $activate): void {
  $u = require_user($db, ['ADMIN']);
  $intern = db_one($db, 'SELECT * FROM interns WHERE user_id=? LIMIT 1', 'i', [$userId]);
  if (!$intern) {
    json_error('NOT_FOUND', 'Intern tidak ditemukan.', 404);
  }
  $newActive = $activate ? 1 : 0;
  db_exec($db, 'UPDATE interns SET active=? WHERE user_id=?', 'ii', [$newActive, $userId]);
  audit_log($db, (int)$u['user_id'], $activate ? 'ADMIN_INTERN_ACTIVATE' : 'ADMIN_INTERN_DEACTIVATE', 'interns', $userId, $intern, ['active' => $newActive], 'toggle');
  json_ok(['active' => $activate]);
}

function route_admin_interns_delete(mysqli $db, int $userId): void {
  $u = require_user($db, ['ADMIN']);
  $body = json_body();
  $confirm = strtoupper(trim((string)($body['confirm'] ?? '')));
  if ($confirm !== 'HAPUS') {
    json_error('CONFIRM_REQUIRED', 'Ketik "HAPUS" untuk konfirmasi hapus permanen.', 422);
  }
  $intern = db_one($db, 'SELECT i.user_id, u.email, u.full_name FROM interns i JOIN users u ON u.id=i.user_id WHERE i.user_id=? LIMIT 1', 'i', [$userId]);
  if (!$intern) {
    json_error('NOT_FOUND', 'Intern tidak ditemukan.', 404);
  }
  $att = db_one($db, 'SELECT id FROM attendance_records WHERE intern_user_id=? LIMIT 1', 'i', [$userId]);
  $leave = db_one($db, 'SELECT id FROM leave_requests WHERE intern_user_id=? LIMIT 1', 'i', [$userId]);
  if ($att || $leave) {
    $force = (bool)($body['force'] ?? false);
    if (!$force) {
      json_error('HAS_HISTORY', 'Intern punya riwayat absensi/izin. Set force=true untuk hapus permanen (akan menghapus riwayat).', 409);
    }
  }
  audit_log($db, (int)$u['user_id'], 'ADMIN_INTERN_DELETE', 'interns', $userId, $intern, ['deleted' => true], 'hard delete');
  db_exec($db, 'DELETE FROM users WHERE id=?', 'i', [$userId]);
  json_ok(['deleted' => true]);
}

function route_mentor_interns_toggle(mysqli $db, int $userId, bool $activate): void {
  $u = require_user($db, ['PEMBIMBING']);
  $own = db_one($db, 'SELECT * FROM interns WHERE user_id=? AND mentor_user_id=? LIMIT 1', 'ii', [$userId, (int)$u['user_id']]);
  if (!$own) {
    json_error('FORBIDDEN', 'Bukan intern bimbingan kamu.', 403);
  }
  $newActive = $activate ? 1 : 0;
  db_exec($db, 'UPDATE interns SET active=? WHERE user_id=?', 'ii', [$newActive, $userId]);
  audit_log($db, (int)$u['user_id'], $activate ? 'MENTOR_INTERN_ACTIVATE' : 'MENTOR_INTERN_DEACTIVATE', 'interns', $userId, $own, ['active' => $newActive], 'toggle');
  json_ok(['active' => $activate]);
}

function route_mentor_interns_delete(mysqli $db, int $userId): void {
  $u = require_user($db, ['PEMBIMBING']);
  $body = json_body();
  $confirm = strtoupper(trim((string)($body['confirm'] ?? '')));
  if ($confirm !== 'HAPUS') {
    json_error('CONFIRM_REQUIRED', 'Ketik "HAPUS" untuk konfirmasi hapus permanen.', 422);
  }
  $intern = db_one(
    $db,
    'SELECT i.user_id, u.email, u.full_name FROM interns i JOIN users u ON u.id=i.user_id WHERE i.user_id=? AND i.mentor_user_id=? LIMIT 1',
    'ii',
    [$userId, (int)$u['user_id']]
  );
  if (!$intern) {
    json_error('FORBIDDEN', 'Bukan intern bimbingan kamu.', 403);
  }
  $att = db_one($db, 'SELECT id FROM attendance_records WHERE intern_user_id=? LIMIT 1', 'i', [$userId]);
  $leave = db_one($db, 'SELECT id FROM leave_requests WHERE intern_user_id=? LIMIT 1', 'i', [$userId]);
  if ($att || $leave) {
    $force = (bool)($body['force'] ?? false);
    if (!$force) {
      json_error('HAS_HISTORY', 'Intern punya riwayat absensi/izin. Set force=true untuk hapus permanen (akan menghapus riwayat).', 409);
    }
  }
  audit_log($db, (int)$u['user_id'], 'MENTOR_INTERN_DELETE', 'interns', $userId, $intern, ['deleted' => true], 'hard delete');
  db_exec($db, 'DELETE FROM users WHERE id=?', 'i', [$userId]);
  json_ok(['deleted' => true]);
}

function route_admin_units_update(mysqli $db, int $unitId): void {
  $u = require_user($db, ['ADMIN']);
  $body = json_body();
  require_fields($body, ['name', 'geofenceLat', 'geofenceLon', 'geofenceRadiusM']);
  $unit = db_one($db, 'SELECT * FROM units WHERE id=? LIMIT 1', 'i', [$unitId]);
  if (!$unit) {
    json_error('NOT_FOUND', 'Unit tidak ditemukan.', 404);
  }
  $before = $unit;

  $name = trim((string)$body['name']);
  $lat = (float)$body['geofenceLat'];
  $lon = (float)$body['geofenceLon'];
  $radius = (int)$body['geofenceRadiusM'];

  if ($name === '') {
    json_error('BAD_INPUT', 'Nama unit wajib diisi.', 422);
  }
  if ($lat < -90 || $lat > 90 || $lon < -180 || $lon > 180) {
    json_error('BAD_INPUT', 'Koordinat lat/lon tidak valid.', 422);
  }
  if ($radius < 10 || $radius > 5000) {
    json_error('BAD_INPUT', 'Radius harus 10..5000 meter.', 422);
  }

  db_exec(
    $db,
    'UPDATE units SET name=?, geofence_lat=?, geofence_lon=?, geofence_radius_m=? WHERE id=?',
    'sddii',
    [$name, $lat, $lon, $radius, $unitId]
  );
  audit_log(
    $db,
    (int)$u['user_id'],
    'ADMIN_UNIT_UPDATE',
    'units',
    $unitId,
    $before,
    ['name' => $name, 'geofenceLat' => $lat, 'geofenceLon' => $lon, 'geofenceRadiusM' => $radius],
    'update geofence'
  );
  $updated = db_one($db, 'SELECT * FROM units WHERE id=? LIMIT 1', 'i', [$unitId]);
  json_ok($updated);
}

function route_mentor_interns_create(mysqli $db): void {
  $u = require_user($db, ['PEMBIMBING']);
  $body = json_body();
  require_fields($body, ['email', 'fullName', 'unitId', 'internshipStart', 'internshipEnd']);
  $email = strtolower(trim((string)$body['email']));
  $fullName = trim((string)$body['fullName']);
  $unitId = (int)$body['unitId'];
  $schoolName = trim((string)($body['schoolName'] ?? ''));
  $schoolAddress = trim((string)($body['schoolAddress'] ?? ''));
  $start = (string)$body['internshipStart'];
  $end = (string)$body['internshipEnd'];
  $password = trim((string)($body['password'] ?? ''));
  if ($password === '') {
    $password = 'Temp' . strtoupper(substr(bin2hex(random_bytes(3)), 0, 6)) . '!';
  }
  if ($start > $end) {
    json_error('BAD_RANGE', 'internshipStart harus <= internshipEnd.', 422);
  }
  $exists = db_one($db, 'SELECT id FROM users WHERE email=? LIMIT 1', 's', [$email]);
  if ($exists) {
    json_error('EMAIL_USED', 'Email sudah terdaftar.', 409);
  }

  $hash = password_hash($password, PASSWORD_DEFAULT);
  db_exec(
    $db,
    'INSERT INTO users (email, full_name, role, password_hash, created_at) VALUES (?,?, "INTERN", ?, NOW())',
    'sss',
    [$email, $fullName, $hash]
  );
  $newUserId = (int)$db->insert_id;
  db_exec(
    $db,
    'INSERT INTO interns (user_id, unit_id, mentor_user_id, school_name, school_address, internship_start, internship_end, active)
     VALUES (?,?,?,?,?,?,?,1)',
    'iiissss',
    [$newUserId, $unitId, (int)$u['user_id'], ($schoolName === '' ? null : $schoolName), ($schoolAddress === '' ? null : $schoolAddress), $start, $end]
  );
  audit_log($db, (int)$u['user_id'], 'MENTOR_INTERN_CREATE', 'interns', $newUserId, null, ['email' => $email, 'userId' => $newUserId], 'create');
  json_ok(['userId' => $newUserId, 'tempPassword' => $password], 201);
}

function route_mentor_units(mysqli $db): void {
  $u = require_user($db, ['PEMBIMBING']);
  $rows = db_all(
    $db,
    'SELECT DISTINCT un.id, un.name
     FROM interns i
     JOIN units un ON un.id=i.unit_id
     WHERE i.mentor_user_id=?
     ORDER BY un.name',
    'i',
    [(int)$u['user_id']]
  );
  $out = array_map(fn($r) => ['id' => (int)$r['id'], 'name' => $r['name']], $rows);
  json_ok($out);
}
