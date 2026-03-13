-- Migration: add work_end_time to settings (jam pulang untuk kontrol tombol absensi)

ALTER TABLE settings
  ADD COLUMN work_end_time TIME NOT NULL DEFAULT '17:00:00' AFTER work_start_time;

-- Optional: isi nilai awal jika row settings sudah ada
UPDATE settings SET work_end_time = work_end_time WHERE id = 1;
