-- Migration: add registration_requests table (self-register request workflow)
-- Run this if your DB was created before feature self-register.

CREATE TABLE IF NOT EXISTS registration_requests (
  id INT AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(190) NOT NULL,
  full_name VARCHAR(190) NOT NULL,
  unit_id INT NOT NULL,
  mentor_user_id INT NULL,
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

