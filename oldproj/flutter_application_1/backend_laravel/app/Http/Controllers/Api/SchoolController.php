<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Support\LegacyApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class SchoolController extends Controller
{
    public function publicIndex(Request $request): JsonResponse
    {
        $query = trim((string) $request->query('q', ''));
        $level = strtoupper(trim((string) $request->query('level', 'SMK')));
        $limit = max(1, min(100, (int) $request->query('limit', 40)));

        $items = $this->fromSchoolTable(query: $query, level: $level, limit: $limit);
        if ($items === []) {
            $items = $this->fromFallbackFile(query: $query, level: $level, limit: $limit);
        }
        if ($items === []) {
            $items = $this->fromHistoricalData(query: $query, level: $level, limit: $limit);
        }

        return LegacyApiResponse::ok($items);
    }

    private function fromSchoolTable(string $query, string $level, int $limit): array
    {
        if (! Schema::hasTable('schools')) {
            return [];
        }

        $rows = DB::table('schools')
            ->select(['id', 'name', 'npsn', 'level', 'city', 'address'])
            ->when(Schema::hasColumn('schools', 'is_active'), fn ($builder) => $builder->where('is_active', 1))
            ->when($level !== '' && Schema::hasColumn('schools', 'level'), fn ($builder) => $builder->whereRaw('UPPER(level) LIKE ?', ['%'.$level.'%']))
            ->when($query !== '', function ($builder) use ($query): void {
                $q = '%'.$query.'%';
                $builder->where(function ($sub) use ($q): void {
                    $sub->where('name', 'like', $q)
                        ->orWhere('npsn', 'like', $q)
                        ->orWhere('city', 'like', $q);
                });
            })
            ->orderBy('name')
            ->limit($limit)
            ->get();

        return $rows->map(fn (object $row): array => [
            'id' => (string) $row->id,
            'name' => (string) $row->name,
            'npsn' => $row->npsn === null ? null : (string) $row->npsn,
            'level' => $row->level === null ? null : (string) $row->level,
            'city' => $row->city === null ? null : (string) $row->city,
            'address' => $row->address === null ? null : (string) $row->address,
        ])->all();
    }

    private function fromFallbackFile(string $query, string $level, int $limit): array
    {
        $path = storage_path('app/reference/smk_schools.json');
        if (! is_file($path)) {
            return [];
        }

        $raw = file_get_contents($path);
        if (! is_string($raw) || trim($raw) === '') {
            return [];
        }

        $decoded = json_decode($raw, true);
        if (! is_array($decoded)) {
            return [];
        }

        $items = [];
        foreach ($decoded as $index => $row) {
            if (! is_array($row)) {
                continue;
            }

            $name = trim((string) ($row['name'] ?? $row['nama'] ?? ''));
            $schoolLevel = strtoupper(trim((string) ($row['level'] ?? $row['jenjang'] ?? 'SMK')));
            $city = trim((string) ($row['city'] ?? $row['kabupaten_kota'] ?? ''));
            $npsn = trim((string) ($row['npsn'] ?? ''));
            $address = trim((string) ($row['address'] ?? $row['alamat'] ?? ''));
            if ($name === '') {
                continue;
            }

            if ($level !== '' && ! str_contains($schoolLevel, $level)) {
                continue;
            }

            if ($query !== '' && ! $this->matchesSchoolQuery($name, $city, $npsn, $query)) {
                continue;
            }

            $items[] = [
                'id' => (string) ($row['id'] ?? $row['kode'] ?? ($index + 1)),
                'name' => $name,
                'npsn' => $npsn === '' ? null : $npsn,
                'level' => $schoolLevel === '' ? null : $schoolLevel,
                'city' => $city === '' ? null : $city,
                'address' => $address === '' ? null : $address,
            ];

            if (count($items) >= $limit) {
                break;
            }
        }

        return $items;
    }

    private function fromHistoricalData(string $query, string $level, int $limit): array
    {
        $queryUpper = strtoupper($query);
        $levelUpper = strtoupper($level);
        $items = [];

        $candidates = DB::table('interns')
            ->selectRaw('DISTINCT school_name')
            ->whereNotNull('school_name')
            ->where('school_name', '!=', '')
            ->orderBy('school_name')
            ->limit(500)
            ->get();

        foreach ($candidates as $row) {
            $name = trim((string) $row->school_name);
            if ($name === '') {
                continue;
            }

            $upperName = strtoupper($name);
            if ($levelUpper !== '' && ! str_contains($upperName, $levelUpper)) {
                continue;
            }
            if ($queryUpper !== '' && ! $this->matchesSchoolQuery($name, null, null, $queryUpper)) {
                continue;
            }

            $items[] = [
                'id' => 'legacy:'.$name,
                'name' => $name,
                'npsn' => null,
                'level' => $levelUpper === '' ? null : $levelUpper,
                'city' => null,
                'address' => null,
            ];

            if (count($items) >= $limit) {
                break;
            }
        }

        return $items;
    }

    private function matchesSchoolQuery(string $name, ?string $city, ?string $npsn, string $query): bool
    {
        $haystack = strtoupper(trim($name.' '.($city ?? '').' '.($npsn ?? '')));
        $haystackCompact = $this->compact($haystack);

        foreach ($this->queryVariants($query) as $variant) {
            if ($variant === '') {
                continue;
            }
            if (str_contains($haystack, $variant)) {
                return true;
            }
            if (str_contains($haystackCompact, $this->compact($variant))) {
                return true;
            }
        }

        return false;
    }

    private function queryVariants(string $query): array
    {
        $q = strtoupper(trim($query));
        if ($q === '') {
            return [''];
        }

        $variants = [$q];
        $variants[] = str_replace('SMKN ', 'SMK NEGERI ', $q);
        $variants[] = str_replace('SMKS ', 'SMK SWASTA ', $q);
        $variants[] = str_replace('SMK NEGERI ', 'SMKN ', $q);
        $variants[] = str_replace('SMK SWASTA ', 'SMKS ', $q);

        return array_values(array_unique(array_filter($variants, fn (string $item): bool => trim($item) !== '')));
    }

    private function compact(string $text): string
    {
        $upper = strtoupper($text);
        $alnumOnly = preg_replace('/[^A-Z0-9]/', '', $upper);

        return is_string($alnumOnly) ? $alnumOnly : $upper;
    }
}
