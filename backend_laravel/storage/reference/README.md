Isi `smk_schools.json` dengan array objek sekolah untuk fitur pencarian publik `/api/public/schools`.

Contoh format:

```json
[
  {
    "id": "31740123",
    "name": "SMKN 64 JAKARTA TIMUR",
    "npsn": "69992345",
    "level": "SMK",
    "city": "KOTA JAKARTA TIMUR",
    "address": "Jl. Contoh No. 1"
  }
]
```

Field yang dibaca:
- `id` (opsional)
- `name` / `nama`
- `npsn` (opsional)
- `level` / `jenjang` (opsional, default `SMK`)
- `city` / `kabupaten_kota` (opsional)
- `address` / `alamat` (opsional)

## Build otomatis (1x command)

Gunakan command ini saat mau regenerate file dari sumber data mentah:

```bash
php artisan schools:build-smk "C:\path\dataset.json"
```

Sumber bisa berupa:
- file JSON metadata CKAN (`result.resources[*].url`),
- file JSON array data sekolah,
- file CSV.

Kalau sumbernya metadata CKAN, command akan download CSV dari internet. Kalau terasa lama atau koneksi tidak stabil, download CSV-nya dulu (jadi file lokal), lalu jalankan command pakai file CSV lokal.

Opsi tambahan:

```bash
php artisan schools:build-smk "C:\path\dataset.csv" --level=SMK --output=storage/app/reference/smk_schools.json
```

Jika mau paksa tanpa internet:

```bash
php artisan schools:build-smk "C:\path\dataset.csv" --no-network
```
