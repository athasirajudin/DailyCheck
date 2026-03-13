<?php
declare(strict_types=1);

function db_connect(): mysqli {
  mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);
  $db = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME, DB_PORT);
  $db->set_charset('utf8mb4');
  return $db;
}

function db_one(mysqli $db, string $sql, string $types = '', array $params = []): ?array {
  $stmt = $db->prepare($sql);
  if ($types !== '') {
    db_bind_params($stmt, $types, $params);
  }
  $stmt->execute();
  $res = $stmt->get_result();
  $row = $res->fetch_assoc();
  $stmt->close();
  return $row ?: null;
}

function db_all(mysqli $db, string $sql, string $types = '', array $params = []): array {
  $stmt = $db->prepare($sql);
  if ($types !== '') {
    db_bind_params($stmt, $types, $params);
  }
  $stmt->execute();
  $res = $stmt->get_result();
  $rows = [];
  while ($row = $res->fetch_assoc()) {
    $rows[] = $row;
  }
  $stmt->close();
  return $rows;
}

function db_exec(mysqli $db, string $sql, string $types = '', array $params = []): int {
  $stmt = $db->prepare($sql);
  if ($types !== '') {
    db_bind_params($stmt, $types, $params);
  }
  $stmt->execute();
  $affected = $stmt->affected_rows;
  $stmt->close();
  return $affected;
}

function db_bind_params(mysqli_stmt $stmt, string $types, array $params): void {
  $refs = [];
  foreach ($params as $k => $v) {
    $refs[$k] = $params[$k];
  }
  $bindArgs = array_merge([$types], $refs);
  $bindRefs = [];
  foreach ($bindArgs as $k => $v) {
    $bindRefs[$k] = &$bindArgs[$k];
  }
  call_user_func_array([$stmt, 'bind_param'], $bindRefs);
}
