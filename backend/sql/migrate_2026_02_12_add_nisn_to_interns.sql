-- Add NISN for intern login (unique identifier)
ALTER TABLE interns
  ADD COLUMN nisn VARCHAR(20) NULL AFTER user_id,
  ADD UNIQUE KEY uniq_intern_nisn (nisn);

-- Prefill existing interns with a fallback (change as needed)
UPDATE interns
SET nisn = CONCAT('NISN', LPAD(user_id, 6, '0'))
WHERE nisn IS NULL;
