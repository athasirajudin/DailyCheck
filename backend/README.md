# Backend (Laragon + MySQL)

Backend ini adalah API sederhana berbasis PHP + MySQL untuk aplikasi **Absensi PKL/Magang Lemhannas**.

## Setup cepat (Laragon)

1. Buat database: `absensi_pkl`
2. Import schema: `backend/sql/schema.sql`
3. Import seed (opsional): `backend/sql/seed.sql`
4. Pastikan URL bisa diakses:
   - Dev mudah: buka `backend/public/index.php` lewat Laragon/Apache (gunakan rewrite `.htaccess`).

Jika DB sudah terlanjur dibuat sebelum fitur self-register, jalankan migration:
- `backend/sql/migrate_2026_02_04_registration_requests.sql`
- `backend/sql/migrate_2026_02_05_intern_school_fields.sql`

## Endpoint utama (ringkas)

- `POST /api/auth/login` → login (Bearer token user)
- `POST /api/register/request` → self-register (request PENDING)
- `GET /api/me`
- `POST /api/admin/pairing/create` → buat pairing code perangkat display (ADMIN)
- `POST /api/mentor/pairing/create` → buat pairing code perangkat display (PEMBIMBING) untuk unit bimbingan
- `GET /api/mentor/units` → list unit yang dibimbing (untuk pairing)
- `POST /api/device/pair` → tukar pairing code jadi `authKey` (perangkat)
- `POST /api/device/heartbeat` (Authorization: Bearer `<authKey>`)
- `POST /api/device/qr-token` (Authorization: Bearer `<authKey>`)
- `POST /api/attendance/check` (Authorization: Bearer `<token user>`) action: `checkin|checkout`
- `POST /api/leave/request`
- `GET /api/units` (auth) dan `GET /api/public/units` (tanpa auth)
- `POST /api/admin/units/{id}` → update nama unit + geofence (ADMIN)
- `GET /api/admin/registration-requests` + `POST /api/admin/registration-requests/{id}/approve|reject`
- `GET /api/admin/interns` + `POST /api/admin/interns` + `PUT /api/admin/interns/{userId}` + `POST /api/admin/interns/{userId}/activate|deactivate`
- `POST /api/admin/interns/{userId}` → hapus permanen (body: confirm=HAPUS, force=true|false)
- `POST /api/mentor/interns` (pembimbing buat akun intern)
- `POST /api/mentor/interns/{userId}/activate|deactivate`
- `POST /api/mentor/interns/{userId}` → hapus permanen (body: confirm=HAPUS, force=true|false)
- `GET /api/admin/recap` dan `GET /api/admin/recap/export?format=csv`
- `GET /api/mentor/recap` dan `GET /api/mentor/recap/export?format=csv`
- `POST /api/system/finalize-day` (ADMIN) → semi-auto ALPA & checkout missing untuk tanggal yang sudah lewat

## Catatan produksi

- Endpoint `system/finalize-day` sebaiknya dipanggil scheduler (Windows Task Scheduler / cron) dan **diproteksi** (secret key / internal network).
- Untuk realtime, client melakukan polling (interval pendek) ke endpoint status. Jika ingin realtime murni, tambahkan WebSocket service (di luar scope backend PHP minimal ini).
