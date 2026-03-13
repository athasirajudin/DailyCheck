<?php
declare(strict_types=1);

const APP_DEBUG = true;
const APP_TIMEZONE = 'Asia/Jakarta';

// Laragon (MySQL) defaults.
const DB_HOST = '127.0.0.1';
const DB_PORT = 3306;
const DB_USER = 'root';
const DB_PASS = '';
const DB_NAME = 'absensi_pkl';

const AUTH_TOKEN_TTL_SECONDS = 60 * 60 * 24 * 7; // 7 days

// Business defaults (can be overwritten by `settings` row id=1)
const DEFAULT_WORK_START_TIME = '09:00:00';
const DEFAULT_WORK_END_TIME = '17:00:00';
const DEFAULT_TOLERANCE_MINUTES = 15;
const DEFAULT_DAY_CUTOFF_TIME = '23:59:59';
const DEFAULT_WORKDAYS_JSON = '[1,2,3,4,5]'; // Mon..Fri (PHP: 1=Mon .. 7=Sun)
const DEFAULT_OFFLINE_THRESHOLD_SECONDS = 120;
const DEFAULT_QR_TTL_SECONDS = 30;
