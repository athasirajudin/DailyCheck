SET @has_gender := (
  SELECT COUNT(*)
  FROM information_schema.columns
  WHERE table_schema = DATABASE()
    AND table_name = 'interns'
    AND column_name = 'gender'
);

SET @ddl := IF(
  @has_gender = 0,
  'ALTER TABLE interns ADD COLUMN gender ENUM(''L'',''P'') NULL AFTER nisn',
  'SELECT ''gender column already exists'''
);

PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
