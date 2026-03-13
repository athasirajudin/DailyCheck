-- Drop legacy QR/pairing tables (kiosk) no longer used

DROP TABLE IF EXISTS qr_sessions;
DROP TABLE IF EXISTS pairing_codes;
DROP TABLE IF EXISTS devices;
