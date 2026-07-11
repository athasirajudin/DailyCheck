## DailyCheck - Smart Internship Attendance & Monitoring System

DailyCheck merupakan sistem absensi dan monitoring kegiatan PKL/Magang berbasis Flutter dan Laravel yang dirancang untuk memastikan setiap proses kehadiran dilakukan secara real-time, terverifikasi, dan sesuai dengan lokasi serta jadwal kerja yang telah ditentukan.
Berbeda dengan sistem absensi konvensional yang hanya mencatat waktu kehadiran, DailyCheck melakukan serangkaian validasi sebelum pengguna dapat melakukan absensi. Setiap proses Check-in maupun Check-out akan memverifikasi beberapa kondisi secara bersamaan, meliputi lokasi pengguna melalui GPS, jarak terhadap area geofence unit kerja, jadwal kerja yang berlaku, serta status akun pengguna.
Sistem hanya akan mengaktifkan tombol absensi apabila seluruh persyaratan telah terpenuhi. Apabila pengguna berada di luar radius geofence, GPS tidak aktif, lokasi belum diperoleh, atau waktu absensi belum memasuki jam kerja yang ditentukan, maka proses absensi akan ditolak secara otomatis.
Selain mencatat waktu kehadiran, DailyCheck juga menyimpan informasi pendukung seperti koordinat GPS, jarak pengguna terhadap titik geofence, perangkat yang digunakan, hingga riwayat perubahan data sebagai Audit Log. Dengan demikian seluruh aktivitas absensi dapat ditelusuri kembali apabila diperlukan.
___________________________________________

Proyek absensi PKL/magang untuk kantor **Lemhannas** dengan konsep:
- Check-in / check-out memakai tombol + validasi GPS & radius geofence (tanpa QR)
- Tombol aktif hanya di jam kerja (jam mulai–jam pulang) & saat device berada di dalam radius
- Approval izin/sakit + override status oleh pembimbing (audit log)
- Admin settings, geofence unit, rekap/export

->

Catatan:

Default akun demo:
- Admin: `admin@lemhannas.go.id` / `Admin123!`
- Pembimbing: `mentor@lemhannas.go.id` / `Mentor123!`
- Intern: `intern@lemhannas.go.id` / `Intern123!`

Catatan backend legacy: lihat `backend/README.md`.
___________________________________________

## 1) Validasi Lokasi

Saat halaman absensi dibuka, aplikasi akan mengambil lokasi pengguna menggunakan GPS perangkat.
Sistem kemudian menghitung jarak antara posisi pengguna dengan titik geofence unit kerja menggunakan perhitungan koordinat.
Apabila pengguna berada di luar radius yang telah ditentukan, tombol absensi akan tetap dinonaktifkan.
___________________________________________

## 2) Autentikasi Pengguna

Setiap pengguna melakukan login menggunakan akun yang telah diberikan.
Hak akses sistem dibedakan berdasarkan role, yaitu:
Administrator
Pembimbing
Peserta PKL/Magang
___________________________________________

## 3) Validasi Waktu

Selain lokasi, sistem juga melakukan validasi terhadap jadwal kerja.
Administrator menentukan:
Jam mulai kerja
Jam pulang
Radius geofence
Check-in hanya dapat dilakukan pada rentang jam masuk, sedangkan Check-out hanya tersedia setelah memenuhi ketentuan jam pulang.
___________________________________________

## 4) Proses Check-in

Ketika seluruh validasi berhasil, pengguna dapat melakukan Check-in.
Data yang disimpan meliputi:
Tanggal
Waktu Check-in
Koordinat GPS
Radius terhadap geofence
Unit kerja
Status kehadiran
Semua data langsung dikirim ke server Laravel dan tersimpan di database.
___________________________________________

## 7) Monitoring Kehadiran

Administrator dan Pembimbing dapat memonitor kehadiran peserta secara real-time melalui dashboard.
Informasi yang ditampilkan meliputi:
Status hadir
Sedang bekerja
Belum hadir
Izin
Sakit
Alpha
Sudah Check-out
Data diperbarui secara berkala menggunakan mekanisme polling.
___________________________________________

## 8) Pengajuan Izin dan Sakit

Apabila peserta tidak dapat hadir, mereka dapat mengajukan izin atau sakit melalui aplikasi.
Permohonan akan diteruskan kepada Pembimbing untuk dilakukan proses persetujuan maupun penolakan.
Seluruh riwayat keputusan tersimpan dalam sistem sehingga dapat ditelusuri kembali.
___________________________________________

## 9) Override Kehadiran

Dalam kondisi tertentu, Pembimbing dapat mengubah status kehadiran peserta.
Misalnya apabila terjadi kendala GPS, gangguan jaringan, atau alasan administratif lainnya.
Setiap perubahan tidak langsung mengganti data begitu saja, tetapi dicatat ke dalam Audit Log sehingga histori perubahan tetap tersimpan.
___________________________________________

## 10) Rekapitulasi

Seluruh data absensi dapat direkap berdasarkan:
Periode
Unit kerja
Peserta
Status kehadiran
Administrator juga dapat mengekspor laporan sebagai dokumentasi maupun kebutuhan administrasi.
___________________________________________

## 11) Self Register (Request)

Di halaman Login, klik `Daftar PKL (Request)`:
- Status awal `PENDING`
- Admin approve di menu `Approval Pendaftaran`
- Sistem membuat akun intern + password sementara (ditampilkan ke admin)
 - Data asal sekolah disimpan untuk admin & pembimbing
 - 
___________________________________________

## 12) Alur cepat (End-to-End)

1. Admin set geofence unit + jam mulai/pulang di menu Settings & Unit.
2. Intern login → buka “Check-in / Check-out” → aplikasi cek GPS & radius → tombol aktif saat dalam radius + jam yang diizinkan → tap untuk hadir/pulang.
3. Pembimbing → Approve izin/sakit & override status jika perlu.
___________________________________________

## Teknologi yang Digunakan

Flutter sebagai aplikasi mobile lintas platform.
Laravel sebagai REST API dan backend utama.
MySQL sebagai basis data.
GPS & Geofence untuk validasi lokasi absensi.
Polling Realtime untuk memperbarui data dashboard secara berkala.
Nginx sebagai web server pada proses deployment.


## Catatan

- Realtime dibuat via polling (interval beberapa detik) untuk dashboard/status/list.
- Endpoint `POST /api/system/finalize-day` disiapkan untuk semi-auto ALPA + checkout missing untuk tanggal yang sudah lewat (sebaiknya dipanggil scheduler). 
