CREATE TABLE IF NOT EXISTS push_device_tokens (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  platform ENUM('ANDROID','IOS','WEB','WINDOWS') NOT NULL DEFAULT 'ANDROID',
  fcm_token VARCHAR(255) NOT NULL,
  device_name VARCHAR(190) NULL,
  last_seen_at DATETIME NOT NULL,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  revoked_at DATETIME NULL,
  UNIQUE KEY uniq_push_fcm_token (fcm_token),
  KEY idx_push_user_active (user_id, revoked_at),
  CONSTRAINT fk_push_token_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
