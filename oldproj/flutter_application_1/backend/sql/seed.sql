INSERT INTO units (id, name, geofence_lat, geofence_lon, geofence_radius_m)
VALUES
  (1, 'Lemhannas - Kantor Utama', -6.2174000, 106.8066000, 250)
ON DUPLICATE KEY UPDATE
  name=VALUES(name),
  geofence_lat=VALUES(geofence_lat),
  geofence_lon=VALUES(geofence_lon),
  geofence_radius_m=VALUES(geofence_radius_m);

-- Default users
-- Passwords:
-- - admin@lemhannas.go.id  : Admin123!
-- - mentor@lemhannas.go.id : Mentor123!
-- - intern@lemhannas.go.id : Intern123!

INSERT INTO users (id, email, full_name, role, password_hash, created_at)
VALUES
  (1, 'admin@lemhannas.go.id', 'Admin Sistem', 'ADMIN', '$2y$10$usTmomMp91RfWf2Cd1XoD.e3o603fmFF3nWUUW8xptaPzWyHplUXW', NOW()),
  (2, 'mentor@lemhannas.go.id', 'Pembimbing Magang', 'PEMBIMBING', '$2y$10$b8E0ifCOxvbXqfT5nMxKTO9pNM8Kt4BbGsYaUsvpOHy5/pBHFGl2.', NOW()),
  (3, 'intern@lemhannas.go.id', 'Siswa PKL', 'INTERN', '$2y$10$CN9JoBC4wFlGQnj1.QN6r.s2DctuWzHlQUc0VwHW1bVYIrlkwigXm', NOW())
ON DUPLICATE KEY UPDATE
  email=VALUES(email),
  full_name=VALUES(full_name),
  role=VALUES(role),
  password_hash=VALUES(password_hash);

INSERT INTO interns (user_id, unit_id, mentor_user_id, internship_start, internship_end, active)
VALUES
  (3, 1, 2, '2026-01-01', '2026-12-31', 1)
ON DUPLICATE KEY UPDATE
  unit_id=VALUES(unit_id),
  mentor_user_id=VALUES(mentor_user_id),
  internship_start=VALUES(internship_start),
  internship_end=VALUES(internship_end),
  active=VALUES(active);

