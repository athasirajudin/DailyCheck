-- Migration: add school fields to interns and registration_requests
-- Run this if your DB was created before these fields existed.

ALTER TABLE interns
  ADD COLUMN school_name VARCHAR(190) NULL AFTER mentor_user_id,
  ADD COLUMN school_address TEXT NULL AFTER school_name;

ALTER TABLE registration_requests
  ADD COLUMN school_name VARCHAR(190) NULL AFTER mentor_user_id,
  ADD COLUMN school_address TEXT NULL AFTER school_name;

