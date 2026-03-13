<?php
declare(strict_types=1);

function bearer_token(): ?string {
  $hdr =
      $_SERVER['HTTP_AUTHORIZATION'] ??
      $_SERVER['REDIRECT_HTTP_AUTHORIZATION'] ??
      '';
  if (!is_string($hdr) || $hdr === '') {
    // Fallback: some servers don't populate $_SERVER['HTTP_AUTHORIZATION'].
    if (function_exists('getallheaders')) {
      $headers = getallheaders();
      if (is_array($headers)) {
        foreach ($headers as $k => $v) {
          if (is_string($k) && strcasecmp($k, 'Authorization') === 0 && is_string($v)) {
            $hdr = $v;
            break;
          }
        }
      }
    }
    if ($hdr === '' && function_exists('apache_request_headers')) {
      $headers = apache_request_headers();
      if (is_array($headers)) {
        foreach ($headers as $k => $v) {
          if (is_string($k) && strcasecmp($k, 'Authorization') === 0 && is_string($v)) {
            $hdr = $v;
            break;
          }
        }
      }
    }
    if (!is_string($hdr) || $hdr === '') {
      return null;
    }
  }
  if (preg_match('/^Bearer\\s+(.+)$/i', $hdr, $m) !== 1) {
    return null;
  }
  return trim($m[1]);
}

function require_user(mysqli $db, array $roles = []): array {
  $token = bearer_token();
  if (!$token) {
    json_error('UNAUTHENTICATED', 'Butuh login.', 401);
  }
  $tokenHash = sha256($token);
  $row = db_one(
    $db,
    'SELECT t.user_id, t.expires_at, u.email, u.full_name, u.role
     FROM auth_tokens t
     JOIN users u ON u.id=t.user_id
     WHERE t.token_hash=? AND t.revoked_at IS NULL LIMIT 1',
    's',
    [$tokenHash]
  );
  if (!$row) {
    json_error('UNAUTHENTICATED', 'Token tidak valid.', 401);
  }
  $now = now_jakarta();
  if (new DateTimeImmutable($row['expires_at'], new DateTimeZone(APP_TIMEZONE)) <= $now) {
    json_error('UNAUTHENTICATED', 'Token sudah kedaluwarsa.', 401);
  }
  if ($roles && !in_array($row['role'], $roles, true)) {
    json_error('FORBIDDEN', 'Akses ditolak.', 403);
  }
  return $row;
}

function issue_auth_token(mysqli $db, int $userId): string {
  $token = random_token(32);
  $tokenHash = sha256($token);
  $expiresAt = now_jakarta()->modify('+' . AUTH_TOKEN_TTL_SECONDS . ' seconds')->format('Y-m-d H:i:s');
  db_exec(
    $db,
    'INSERT INTO auth_tokens (user_id, token_hash, expires_at, created_at) VALUES (?,?,?,NOW())',
    'iss',
    [$userId, $tokenHash, $expiresAt]
  );
  return $token;
}

function require_device(mysqli $db): array {
  $authKey = bearer_token();
  if (!$authKey) {
    json_error('UNAUTHENTICATED', 'Butuh authKey perangkat.', 401);
  }
  $authHash = sha256($authKey);
  $device = db_one(
    $db,
    'SELECT id, unit_id, name, last_seen_at FROM devices WHERE auth_key_hash=? LIMIT 1',
    's',
    [$authHash]
  );
  if (!$device) {
    json_error('UNAUTHENTICATED', 'AuthKey perangkat tidak valid.', 401);
  }
  return $device;
}
