# Absensi PKL/Magang Lemhannas

Proyek absensi PKL/magang untuk kantor **Lemhannas** dengan konsep:
- Check-in / check-out memakai tombol + validasi GPS & radius geofence (tanpa QR)
- Tombol aktif hanya di jam kerja (jam mulai–jam pulang) & saat device berada di dalam radius
- Approval izin/sakit + override status oleh pembimbing (audit log)
- Admin settings, geofence unit, rekap/export

Arsitektur Flutter: MVVM (ChangeNotifier).

## Akses Semua HP via ngrok (Laravel API)

Gunakan backend Laravel di folder `backend_laravel`:

1. Jalankan API Laravel:
   - `cd backend_laravel`
   - `php artisan serve --host 0.0.0.0 --port 8000`
2. Di terminal lain, buka tunnel ngrok:
   - `ngrok http 8000`
3. Ambil URL HTTPS ngrok, misalnya:
   - `https://abcd-1234.ngrok-free.app`
4. Jalankan Flutter dengan base URL ngrok:
   - `flutter run --dart-define=API_BASE_URL=https://abcd-1234.ngrok-free.app`

Catatan:
- Endpoint Flutter sudah pakai prefix `/api/...`, jadi `API_BASE_URL` cukup domain saja (tanpa `/api`).
- URL ngrok berubah setiap start; sekarang bisa diubah langsung dari halaman login lewat tombol `Ubah URL API (ngrok)`.
- Di `backend_laravel`, endpoint inti (`auth/login`, `me`, `units`, `public/units`, `register/request`) sudah native Laravel.
- Endpoint lain sementara lewat bridge ke logic lama `backend/src/routes.php` agar semua fitur tetap jalan saat migrasi bertahap.
- Jika muncul `Response server bukan JSON`, biasanya URL ngrok salah/tunnel mati/URL base memakai path yang keliru. Gunakan format `https://xxxx.ngrok-free.app` (tanpa `/api` dan tanpa trailing slash).

## 1) Setup Backend (Laragon)

1. Jalankan Laragon: **Apache + MySQL**
2. Buat database: `absensi_pkl`
3. Import schema: `backend/sql/schema.sql`
4. Import seed (opsional, untuk akun demo): `backend/sql/seed.sql`

Default akun demo:
- Admin: `admin@lemhannas.go.id` / `Admin123!`
- Pembimbing: `mentor@lemhannas.go.id` / `Mentor123!`
- Intern: `intern@lemhannas.go.id` / `Intern123!`

Catatan backend legacy: lihat `backend/README.md`.

## 2) Setup Flutter

1. Jalankan `flutter pub get`
2. Pastikan device punya akses ke base URL API.

Base URL API default ada di `lib/main.dart`:
- Host/Windows (Laravel local): `http://127.0.0.1:8000`

Untuk Android Emulator, gunakan:
- `http://10.0.2.2:8000`

Jalankan app dengan override base URL:
- `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000`

Konfigurasi login admin/pembimbing:
- Ubah `backend_laravel/.env` pada `ADMIN_LOGIN_PIN=...` untuk mengganti PIN verifikasi login admin.
- `ADMIN_ACCESS_TTL_SECONDS` mengatur masa berlaku tiket verifikasi PIN sebelum login admin.
- `ADMIN_ACCESS_CACHE_STORE=file` disarankan agar verifikasi PIN admin tidak bergantung pada tabel cache database.
- Jika Anda mengubah nilai env Laravel, jalankan `php artisan config:clear`.

## 3) Alur cepat (End-to-End)

1. Admin set geofence unit + jam mulai/pulang di menu Settings & Unit.
2. Intern login → buka “Check-in / Check-out” → aplikasi cek GPS & radius → tombol aktif saat dalam radius + jam yang diizinkan → tap untuk hadir/pulang.
3. Pembimbing → Approve izin/sakit & override status jika perlu.

## 4) Self Register (Request)

Di halaman Login, klik `Daftar PKL (Request)`:
- Status awal `PENDING`
- Admin approve di menu `Approval Pendaftaran`
- Sistem membuat akun intern + password sementara (ditampilkan ke admin)
 - Data asal sekolah disimpan untuk admin & pembimbing

## Catatan

- Realtime dibuat via polling (interval beberapa detik) untuk dashboard/status/list.
- Endpoint `POST /api/system/finalize-day` disiapkan untuk semi-auto ALPA + checkout missing untuk tanggal yang sudah lewat (sebaiknya dipanggil scheduler). 
