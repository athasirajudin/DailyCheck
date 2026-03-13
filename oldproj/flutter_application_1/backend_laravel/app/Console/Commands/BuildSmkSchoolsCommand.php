<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Str;
use RuntimeException;

class BuildSmkSchoolsCommand extends Command
{
    protected $signature = 'schools:build-smk
        {source? : Path/URL to JSON metadata, JSON array, or CSV file}
        {--output=storage/app/reference/smk_schools.json : Output file path}
        {--level=SMK : School level filter (default SMK)}
        {--timeout=120 : HTTP timeout in seconds}
        {--retries=2 : HTTP retries}
        {--no-network : Disable network download (use local file only)}';

    protected $description = 'Build SMK schools reference JSON from source dataset';

    public function handle(): int
    {
        $source = trim((string) $this->argument('source'));
        if ($source === '') {
            $this->error('Argumen source wajib diisi. Contoh: php artisan schools:build-smk "C:\\path\\dataset.json"');

            return self::FAILURE;
        }

        try {
            $this->line('Source: '.$source);
            [$rows, $sourceInfo] = $this->loadRows($source);
            if ($rows === []) {
                $this->error('Data sumber tidak berisi baris yang bisa diproses.');

                return self::FAILURE;
            }

            $this->line('Parse OK: '.$sourceInfo);
            [$schools, $stats] = $this->transformRows($rows, (string) $this->option('level'));
            if ($schools === []) {
                $this->error('Tidak ada data sekolah yang cocok dengan filter level.');

                return self::FAILURE;
            }

            $outputPath = $this->resolveOutputPath((string) $this->option('output'));
            $outputDirectory = dirname($outputPath);
            if (! is_dir($outputDirectory) && ! mkdir($outputDirectory, 0777, true) && ! is_dir($outputDirectory)) {
                throw new RuntimeException('Gagal membuat folder output: '.$outputDirectory);
            }

            $this->line('Writing output...');
            $encoded = json_encode($schools, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
            if (! is_string($encoded)) {
                throw new RuntimeException('Gagal encode JSON output.');
            }

            $bytes = file_put_contents($outputPath, $encoded.PHP_EOL);
            if ($bytes === false) {
                throw new RuntimeException('Gagal menulis file output: '.$outputPath);
            }

            $this->info('Build selesai.');
            $this->line('Sumber: '.$sourceInfo);
            $this->line('Baris sumber: '.$stats['sourceRows']);
            $this->line('Lolos level: '.$stats['matchedRows']);
            $this->line('Duplikat dilewati: '.$stats['duplicateRows']);
            $this->line('Total output: '.$stats['outputRows']);
            $this->line('Output: '.$outputPath);

            return self::SUCCESS;
        } catch (\Throwable $exception) {
            $this->error($exception->getMessage());

            return self::FAILURE;
        }
    }

    /**
     * @return array{0:array<int,array<string,mixed>>,1:string}
     */
    private function loadRows(string $source): array
    {
        if ($this->isHttpSource($source)) {
            if ((bool) $this->option('no-network')) {
                throw new RuntimeException('Network dimatikan (--no-network). Download tidak diizinkan. Gunakan file lokal (CSV/JSON).');
            }

            $content = $this->fetchRemoteContent($source);

            return $this->parseSourceContent($content, $source);
        }

        $sourcePath = $this->resolveInputPath($source);
        if (is_dir($sourcePath)) {
            throw new RuntimeException('Source menunjuk ke folder, bukan file: '.$sourcePath);
        }
        if (! is_file($sourcePath)) {
            throw new RuntimeException('File source tidak ditemukan: '.$sourcePath);
        }

        $content = file_get_contents($sourcePath);
        if (! is_string($content) || trim($content) === '') {
            throw new RuntimeException('File source kosong: '.$sourcePath);
        }

        return $this->parseSourceContent($content, $sourcePath);
    }

    /**
     * @return array{0:array<int,array<string,mixed>>,1:string}
     */
    private function parseSourceContent(string $content, string $label): array
    {
        $decoded = json_decode($this->removeUtf8Bom($content), true);
        if (is_array($decoded)) {
            if ($this->isList($decoded)) {
                return [$decoded, 'JSON array ('.$label.')'];
            }

            $resourceUrl = $this->findResourceUrlFromMetadata($decoded);
            if ($resourceUrl !== null) {
                if ((bool) $this->option('no-network') && $this->isHttpSource($resourceUrl)) {
                    throw new RuntimeException('Metadata butuh download CSV, tapi network dimatikan (--no-network). Download dulu CSV-nya lalu jalankan command pakai file CSV lokal.');
                }

                $this->line('Metadata terdeteksi. Mengambil resource: '.$resourceUrl);
                $csvContent = $this->isHttpSource($resourceUrl)
                    ? $this->fetchRemoteContent($resourceUrl)
                    : file_get_contents($this->resolveInputPath($resourceUrl));

                if (! is_string($csvContent) || trim($csvContent) === '') {
                    throw new RuntimeException('Gagal membaca resource CSV dari metadata.');
                }

                return [$this->parseCsvRows($csvContent), 'CSV resource from metadata ('.$label.')'];
            }

            if (isset($decoded['data']) && is_array($decoded['data']) && $this->isList($decoded['data'])) {
                return [$decoded['data'], 'JSON data array ('.$label.')'];
            }
        }

        return [$this->parseCsvRows($content), 'CSV ('.$label.')'];
    }

    /**
     * @param  array<string,mixed>  $decoded
     */
    private function findResourceUrlFromMetadata(array $decoded): ?string
    {
        $resources = data_get($decoded, 'result.resources');
        if (! is_array($resources)) {
            return null;
        }

        $csvUrl = null;
        $fallbackUrl = null;

        foreach ($resources as $resource) {
            if (! is_array($resource)) {
                continue;
            }

            $url = trim((string) ($resource['url'] ?? ''));
            if ($url === '') {
                continue;
            }

            $format = strtoupper(trim((string) ($resource['format'] ?? '')));
            if ($fallbackUrl === null) {
                $fallbackUrl = $url;
            }

            if (str_contains($format, 'CSV')) {
                $csvUrl = $url;
                break;
            }
        }

        return $csvUrl ?? $fallbackUrl;
    }

    /**
     * @return array<int,array<string,mixed>>
     */
    private function parseCsvRows(string $content): array
    {
        $sanitized = str_replace("\r\n", "\n", $content);
        $sanitized = str_replace("\r", "\n", $sanitized);
        $lines = preg_split('/\n/', $sanitized);
        if (! is_array($lines) || $lines === []) {
            return [];
        }

        $headerLine = '';
        foreach ($lines as $line) {
            if (trim($line) !== '') {
                $headerLine = $line;
                break;
            }
        }

        if ($headerLine === '') {
            return [];
        }

        $delimiter = $this->detectDelimiter($headerLine);
        $stream = fopen('php://temp', 'r+');
        if (! is_resource($stream)) {
            throw new RuntimeException('Gagal membuka stream sementara untuk parsing CSV.');
        }

        fwrite($stream, $sanitized);
        rewind($stream);

        $headers = fgetcsv($stream, 0, $delimiter);
        if (! is_array($headers)) {
            fclose($stream);

            return [];
        }

        $normalizedHeaders = array_map(
            fn ($header): string => $this->normalizeHeader((string) $header),
            $headers
        );

        $rows = [];
        while (($values = fgetcsv($stream, 0, $delimiter)) !== false) {
            if (! is_array($values)) {
                continue;
            }

            if ($this->allValuesEmpty($values)) {
                continue;
            }

            $values = array_pad($values, count($normalizedHeaders), null);
            $row = [];
            foreach ($normalizedHeaders as $index => $header) {
                if ($header === '') {
                    continue;
                }
                $value = $values[$index] ?? null;
                $row[$header] = $value === null ? null : trim((string) $value);
            }

            if ($row !== []) {
                $rows[] = $row;
            }
        }

        fclose($stream);

        return $rows;
    }

    /**
     * @param  array<int,array<string,mixed>>  $rows
     * @return array{0:array<int,array<string,string|null>>,1:array{sourceRows:int,matchedRows:int,duplicateRows:int,outputRows:int}}
     */
    private function transformRows(array $rows, string $level): array
    {
        $targetLevel = strtoupper(trim($level));
        $outputLevel = $targetLevel === '' ? null : $targetLevel;
        $normalized = [];
        $seen = [];
        $matchedRows = 0;
        $duplicateRows = 0;

        foreach ($rows as $index => $row) {
            if (! is_array($row)) {
                continue;
            }

            $name = $this->cleanValue($this->pick($row, ['name', 'nama', 'nama_sekolah', 'sekolah', 'nama_satuan_pendidikan']));
            if ($name === '') {
                continue;
            }

            $rowLevel = $this->cleanValue($this->pick($row, ['level', 'jenjang', 'bentuk_pendidikan', 'bentuk']));
            if ($targetLevel !== '' && ! $this->levelMatches($rowLevel, $targetLevel, $name)) {
                continue;
            }
            $matchedRows++;

            $npsn = preg_replace('/\D+/', '', $this->cleanValue($this->pick($row, ['npsn'])));
            $npsn = is_string($npsn) && $npsn !== '' ? $npsn : null;
            $city = $this->cleanValue($this->pick($row, ['city', 'wilayah', 'kabupaten_kota', 'kota_kabupaten', 'kota', 'kabupaten']));
            $address = $this->cleanValue($this->pick($row, ['address', 'alamat', 'alamat_jalan', 'alamat_sekolah']));
            $rawId = $this->cleanValue($this->pick($row, ['id', 'kode', 'kode_sekolah', 'sekolah_id']));
            $id = $rawId !== '' ? $rawId : ($npsn ?? (string) ($index + 1));

            $dedupeKey = $npsn !== null
                ? 'npsn:'.$npsn
                : 'name:'.$this->compactText($name.'|'.$city);

            if (isset($seen[$dedupeKey])) {
                $duplicateRows++;
                continue;
            }
            $seen[$dedupeKey] = true;

            $normalized[] = [
                'id' => $id,
                'name' => $name,
                'npsn' => $npsn,
                'level' => $outputLevel,
                'city' => $city === '' ? null : $city,
                'address' => $address === '' ? null : $address,
            ];
        }

        usort($normalized, function (array $left, array $right): int {
            $cityCompare = strcmp((string) ($left['city'] ?? ''), (string) ($right['city'] ?? ''));
            if ($cityCompare !== 0) {
                return $cityCompare;
            }

            return strcmp((string) ($left['name'] ?? ''), (string) ($right['name'] ?? ''));
        });

        return [
            $normalized,
            [
                'sourceRows' => count($rows),
                'matchedRows' => $matchedRows,
                'duplicateRows' => $duplicateRows,
                'outputRows' => count($normalized),
            ],
        ];
    }

    /**
     * @param  array<string,mixed>  $row
     * @param  array<int,string>  $keys
     */
    private function pick(array $row, array $keys): ?string
    {
        foreach ($keys as $key) {
            if (! array_key_exists($key, $row)) {
                continue;
            }
            $value = $row[$key];
            if ($value === null) {
                continue;
            }
            $text = trim((string) $value);
            if ($text !== '') {
                return $text;
            }
        }

        return null;
    }

    private function levelMatches(string $rowLevel, string $targetLevel, string $name): bool
    {
        $normalizedTarget = $this->compactText($targetLevel);
        if ($normalizedTarget === '') {
            return true;
        }

        $normalizedLevel = $this->compactText($rowLevel);
        $normalizedName = $this->compactText($name);

        if ($normalizedTarget === 'SMK') {
            return str_contains($normalizedLevel, 'SMK')
                || str_contains($normalizedLevel, 'KEJURUAN')
                || str_contains($normalizedName, 'SMK');
        }

        return str_contains($normalizedLevel, $normalizedTarget)
            || str_contains($normalizedName, $normalizedTarget);
    }

    private function cleanValue(?string $value): string
    {
        return trim((string) $value);
    }

    private function compactText(string $value): string
    {
        $upper = strtoupper($value);
        $compact = preg_replace('/[^A-Z0-9]+/', '', $upper);

        return is_string($compact) ? $compact : $upper;
    }

    private function detectDelimiter(string $headerLine): string
    {
        $candidates = [',', ';', "\t", '|'];
        $bestDelimiter = ',';
        $bestCount = 0;

        foreach ($candidates as $candidate) {
            $parts = str_getcsv($headerLine, $candidate);
            $count = is_array($parts) ? count($parts) : 0;
            if ($count > $bestCount) {
                $bestDelimiter = $candidate;
                $bestCount = $count;
            }
        }

        return $bestDelimiter;
    }

    /**
     * @param  array<int,string|null>  $values
     */
    private function allValuesEmpty(array $values): bool
    {
        foreach ($values as $value) {
            if (trim((string) $value) !== '') {
                return false;
            }
        }

        return true;
    }

    private function normalizeHeader(string $header): string
    {
        $withoutBom = $this->removeUtf8Bom($header);
        $snake = Str::of($withoutBom)
            ->lower()
            ->replaceMatches('/[^a-z0-9]+/', '_')
            ->trim('_')
            ->toString();

        return $snake;
    }

    private function removeUtf8Bom(string $content): string
    {
        if (str_starts_with($content, "\xEF\xBB\xBF")) {
            return substr($content, 3);
        }

        return $content;
    }

    private function resolveInputPath(string $path): string
    {
        if ($this->isAbsolutePath($path)) {
            return $path;
        }

        return base_path($path);
    }

    private function resolveOutputPath(string $path): string
    {
        $trimmed = trim($path);
        if ($trimmed === '') {
            $trimmed = 'storage/app/reference/smk_schools.json';
        }

        if ($this->isAbsolutePath($trimmed)) {
            return $trimmed;
        }

        return base_path($trimmed);
    }

    private function isAbsolutePath(string $path): bool
    {
        return preg_match('/^(?:[A-Za-z]:[\\\\\\/]|\/)/', $path) === 1;
    }

    private function isHttpSource(string $source): bool
    {
        return Str::startsWith(strtolower($source), ['http://', 'https://']);
    }

    private function fetchRemoteContent(string $url): string
    {
        $timeout = max(5, (int) $this->option('timeout'));
        $retries = max(0, (int) $this->option('retries'));

        $this->line('Downloading...');
        $response = Http::timeout($timeout)
            ->retry($retries, 500)
            ->withHeaders([
                'User-Agent' => 'absensi-schools-builder/1.0',
                'Accept' => '*/*',
            ])
            ->get($url);

        if (! $response->successful()) {
            throw new RuntimeException('Gagal download resource: '.$url.' (HTTP '.$response->status().')');
        }

        $body = $response->body();
        $this->line('Downloaded bytes: '.strlen($body));

        return $body;
    }

    /**
     * @param  array<mixed>  $array
     */
    private function isList(array $array): bool
    {
        if (function_exists('array_is_list')) {
            return array_is_list($array);
        }

        return $array === [] || array_keys($array) === range(0, count($array) - 1);
    }
}
