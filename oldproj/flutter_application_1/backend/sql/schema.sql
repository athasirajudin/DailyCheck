-- Absensi PKL/Magang (Lemhannas) - MySQL schema
-- Default DB name: absensi_pkl

CREATE TABLE IF NOT EXISTS units (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(120) NOT NULL,
  geofence_lat DECIMAL(10,7) NOT NULL,
  geofence_lon DECIMAL(10,7) NOT NULL,
  geofence_radius_m INT NOT NULL DEFAULT 100
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(190) NOT NULL UNIQUE,
  full_name VARCHAR(190) NOT NULL,
  role ENUM('ADMIN','PEMBIMBING','INTERN') NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  created_at DATETIME NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS interns (
  user_id INT PRIMARY KEY,
  unit_id INT NOT NULL,
  mentor_user_id INT NULL,
  school_name VARCHAR(190) NULL,
  school_address TEXT NULL,
  internship_start DATE NOT NULL,
  internship_end DATE NOT NULL,
  active TINYINT(1) NOT NULL DEFAULT 1,
  CONSTRAINT fk_intern_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_intern_unit FOREIGN KEY (unit_id) REFERENCES units(id) ON DELETE RESTRICT,
  CONSTRAINT fk_intern_mentor FOREIGN KEY (mentor_user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS devices (
  id INT AUTO_INCREMENT PRIMARY KEY,
  unit_id INT NOT NULL,
  name VARCHAR(120) NOT NULL,
  auth_key_hash CHAR(64) NOT NULL UNIQUE,
  last_seen_at DATETIME NULL,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  CONSTRAINT fk_device_unit FOREIGN KEY (unit_id) REFERENCES units(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS pairing_codes (
  id INT AUTO_INCREMENT PRIMARY KEY,
  unit_id INT NOT NULL,
  device_name VARCHAR(120) NOT NULL,
  code VARCHAR(20) NOT NULL,
  expires_at DATETIME NOT NULL,
  created_by_user_id INT NOT NULL,
  created_at DATETIME NOT NULL,
  used_at DATETIME NULL,
  used_by_device_id INT NULL,
  KEY idx_pairing_code (code),
  CONSTRAINT fk_pair_unit FOREIGN KEY (unit_id) REFERENCES units(id) ON DELETE RESTRICT,
  CONSTRAINT fk_pair_creator FOREIGN KEY (created_by_user_id) REFERENCES users(id) ON DELETE RESTRICT,
  CONSTRAINT fk_pair_device FOREIGN KEY (used_by_device_id) REFERENCES devices(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS qr_sessions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  device_id INT NOT NULL,
  token VARCHAR(40) NOT NULL,
  expires_at DATETIME NOT NULL,
  active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL,
  deactivated_at DATETIME NULL,
  KEY idx_qr_token (token),
  KEY idx_qr_active (device_id, active),
  CONSTRAINT fk_qr_device FOREIGN KEY (device_id) REFERENCES devices(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS attendance_records (
  id INT AUTO_INCREMENT PRIMARY KEY,
  intern_user_id INT NOT NULL,
  unit_id INT NOT NULL,
  date DATE NOT NULL,
  check_in_at DATETIME NULL,
  check_out_at DATETIME NULL,
  status ENUM('HADIR','TERLAMBAT','ALPA','IZIN','SAKIT') NOT NULL,
  status_marked_by ENUM('SYSTEM','PEMBIMBING','ADMIN') NOT NULL DEFAULT 'SYSTEM',
  gps_check_in_lat DECIMAL(10,7) NULL,
  gps_check_in_lon DECIMAL(10,7) NULL,
  gps_check_out_lat DECIMAL(10,7) NULL,
  gps_check_out_lon DECIMAL(10,7) NULL,
  checkout_missing TINYINT(1) NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  UNIQUE KEY uniq_attendance (intern_user_id, date),
  KEY idx_attendance_date (date),
  CONSTRAINT fk_att_intern FOREIGN KEY (intern_user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_att_unit FOREIGN KEY (unit_id) REFERENCES units(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS leave_requests (
  id INT AUTO_INCREMENT PRIMARY KEY,
  intern_user_id INT NOT NULL,
  type ENUM('IZIN','SAKIT') NOT NULL,
  date_from DATE NOT NULL,
  date_to DATE NOT NULL,
  reason TEXT NOT NULL,
  attachment_url TEXT NULL,
  status ENUM('PENDING','APPROVED','REJECTED') NOT NULL DEFAULT 'PENDING',
  decided_by_user_id INT NULL,
  decided_at DATETIME NULL,
  created_at DATETIME NOT NULL,
  KEY idx_leave_intern (intern_user_id, status),
  CONSTRAINT fk_leave_intern FOREIGN KEY (intern_user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_leave_decider FOREIGN KEY (decided_by_user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS audit_logs (
  id INT AUTO_INCREMENT PRIMARY KEY,
  actor_user_id INT NOT NULL,
  action VARCHAR(64) NOT NULL,
  entity_type VARCHAR(64) NOT NULL,
  entity_id INT NOT NULL,
  before_json MEDIUMTEXT NULL,
  after_json MEDIUMTEXT NULL,
  reason TEXT NULL,
  created_at DATETIME NOT NULL,
  KEY idx_audit_entity (entity_type, entity_id),
  CONSTRAINT fk_audit_actor FOREIGN KEY (actor_user_id) REFERENCES users(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS settings (
  id INT PRIMARY KEY,
  timezone VARCHAR(64) NOT NULL,
  work_start_time TIME NOT NULL,
  tolerance_minutes INT NOT NULL,
  day_cutoff_time TIME NOT NULL,
  workdays_json TEXT NOT NULL,
  offline_threshold_seconds INT NOT NULL,
  qr_token_ttl_seconds INT NOT NULL,
  updated_at DATETIME NOT NULL,
  updated_by_user_id INT NOT NULL,
  CONSTRAINT fk_settings_user FOREIGN KEY (updated_by_user_id) REFERENCES users(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS holidays (
  id INT AUTO_INCREMENT PRIMARY KEY,
  date DATE NOT NULL UNIQUE,
  name VARCHAR(190) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS auth_tokens (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  token_hash CHAR(64) NOT NULL,
  expires_at DATETIME NOT NULL,
  created_at DATETIME NOT NULL,
  revoked_at DATETIME NULL,
  UNIQUE KEY uniq_token_hash (token_hash),
  KEY idx_token_user (user_id),
  CONSTRAINT fk_token_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS registration_requests (
  id INT AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(190) NOT NULL,
  full_name VARCHAR(190) NOT NULL,
  unit_id INT NOT NULL,
  mentor_user_id INT NULL,
  school_name VARCHAR(190) NULL,
  school_address TEXT NULL,
  internship_start DATE NOT NULL,
  internship_end DATE NOT NULL,
  notes TEXT NULL,
  status ENUM('PENDING','APPROVED','REJECTED') NOT NULL DEFAULT 'PENDING',
  decided_by_user_id INT NULL,
  decided_at DATETIME NULL,
  decision_reason TEXT NULL,
  created_at DATETIME NOT NULL,
  UNIQUE KEY uniq_regreq_email_pending (email, status),
  KEY idx_regreq_status (status, created_at),
  CONSTRAINT fk_regreq_unit FOREIGN KEY (unit_id) REFERENCES units(id) ON DELETE RESTRICT,
  CONSTRAINT fk_regreq_mentor FOREIGN KEY (mentor_user_id) REFERENCES users(id) ON DELETE SET NULL,
  CONSTRAINT fk_regreq_decider FOREIGN KEY (decided_by_user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
