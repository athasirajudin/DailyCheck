# Absensi PKL/Magang Lemhannas

Proyek absensi PKL/magang untuk kantor **Lemhannas** dengan konsep:
- QR token dari device display (kiosk) + validasi lokasi (geofence)
- Check-in / check-out untuk intern
- Approval izin/sakit + override status oleh pembimbing (audit log)
- Admin settings, pairing device, monitoring device, rekap/export

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

## 3) Alur cepat (End-to-End)

1. Login sebagai Admin → Generate pairing code (menu Pairing Device)
2. Buka “Mode Display (Kiosk)” → Pair device → token tampil sebagai QR
3. Login sebagai Intern → “Check-in / Check-out” → scan QR → GPS otomatis → status HADIR/TERLAMBAT
4. Login sebagai Pembimbing → Approve izin/sakit & override status jika perlu

Catatan: pairing display cukup sekali. AuthKey disimpan di device display (kiosk) agar setelah restart tetap bisa menampilkan QR token.

## 4) Self Register (Request)

Di halaman Login, klik `Daftar PKL (Request)`:
- Status awal `PENDING`
- Admin approve di menu `Approval Pendaftaran`
- Sistem membuat akun intern + password sementara (ditampilkan ke admin)
 - Data asal sekolah disimpan untuk admin & pembimbing

## Catatan

- Realtime dibuat via polling (interval beberapa detik) untuk dashboard/status/list.
- Endpoint `POST /api/system/finalize-day` disiapkan untuk semi-auto ALPA + checkout missing untuk tanggal yang sudah lewat (sebaiknya dipanggil scheduler). 
