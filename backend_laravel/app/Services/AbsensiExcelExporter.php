<?php

namespace App\Services;

use Carbon\CarbonImmutable;
use PhpOffice\PhpSpreadsheet\Cell\Coordinate;
use PhpOffice\PhpSpreadsheet\Cell\DataType;
use PhpOffice\PhpSpreadsheet\IOFactory;
use PhpOffice\PhpSpreadsheet\Spreadsheet;
use PhpOffice\PhpSpreadsheet\Style\Alignment;
use PhpOffice\PhpSpreadsheet\Writer\Xlsx;
use RuntimeException;

class AbsensiExcelExporter
{
    private const FIRST_DATE_COL = 'H';
    private const LAST_DATE_COL = 'AL';
    private const RECAP_SAKIT_COL = 'AM';
    private const RECAP_IZIN_COL = 'AN';
    private const RECAP_ALPA_COL = 'AO';
    private const START_ROW = 9;
    private const DEFAULT_TIMEZONE = 'Asia/Jakarta';

    /**
     * @param array{
     *   month:int|string,
     *   year:int|string,
     *   rows:array<int, array{
     *     no?:int|string,
     *     nisn:string,
     *     nama:string,
     *     lp?:string|null,
     *     sekolah?:string|null,
     *     periodeStart:string,
     *     periodeEnd:string,
     *     marks?:array<string|int, string>
     *   }>
     * } $payload
     * @return array{path:string,filename:string}
     */
    public function export(array $payload): array
    {
        $month = (int) $payload['month'];
        $year = (int) $payload['year'];
        $rows = $payload['rows'] ?? [];

        $templatePath = storage_path('app/templates/rekap_absensi_template_31hari.xlsx');
        if (! is_file($templatePath)) {
            throw new RuntimeException('Template Excel tidak ditemukan di storage/app/templates/rekap_absensi_template_31hari.xlsx');
        }

        /** @var Spreadsheet $spreadsheet */
        $spreadsheet = IOFactory::load($templatePath);
        $sheet = $spreadsheet->getActiveSheet();

        $daysInMonth = CarbonImmutable::create($year, $month, 1, 0, 0, 0, self::DEFAULT_TIMEZONE)->daysInMonth;
        $firstDateIndex = Coordinate::columnIndexFromString(self::FIRST_DATE_COL);
        $lastDateIndex = Coordinate::columnIndexFromString(self::LAST_DATE_COL);
        $lastUsedDateIndex = $firstDateIndex + ($daysInMonth - 1);
        $lastUsedDateCol = Coordinate::stringFromColumnIndex($lastUsedDateIndex);

        $this->applyMonthTitle($sheet, $month);
        $this->setDateColumnVisibility($sheet, $lastUsedDateIndex, $lastDateIndex);
        $this->clearDataArea($sheet, max(self::START_ROW + count($rows) + 12, 80));
        $this->fillRows($sheet, $rows, $daysInMonth, $lastUsedDateCol);
        $this->fillOverallSummaryFormula($sheet, count($rows));

        $filename = sprintf('rekap_absensi_%04d-%02d.xlsx', $year, $month);
        $tmpPath = tempnam(storage_path('app'), 'rekap_absensi_');
        if ($tmpPath === false) {
            throw new RuntimeException('Gagal membuat file temporary export.');
        }
        $tmpXlsxPath = $tmpPath.'.xlsx';
        @unlink($tmpPath);

        $writer = new Xlsx($spreadsheet);
        $writer->save($tmpXlsxPath);
        $spreadsheet->disconnectWorksheets();
        unset($spreadsheet);

        return [
            'path' => $tmpXlsxPath,
            'filename' => $filename,
        ];
    }

    private function applyMonthTitle(\PhpOffice\PhpSpreadsheet\Worksheet\Worksheet $sheet, int $month): void
    {
        $sheet->setCellValue('B2', strtoupper($this->monthNameIndo($month)));
    }

    private function setDateColumnVisibility(
        \PhpOffice\PhpSpreadsheet\Worksheet\Worksheet $sheet,
        int $lastUsedDateIndex,
        int $lastDateIndex,
    ): void {
        $firstDateIndex = Coordinate::columnIndexFromString(self::FIRST_DATE_COL);

        for ($col = $firstDateIndex; $col <= $lastDateIndex; $col++) {
            $letter = Coordinate::stringFromColumnIndex($col);
            $sheet->getColumnDimension($letter)->setVisible(true);
        }

        if ($lastUsedDateIndex >= $lastDateIndex) {
            return;
        }

        for ($col = $lastUsedDateIndex + 1; $col <= $lastDateIndex; $col++) {
            $letter = Coordinate::stringFromColumnIndex($col);
            $sheet->getColumnDimension($letter)->setVisible(false);
        }
    }

    private function clearDataArea(
        \PhpOffice\PhpSpreadsheet\Worksheet\Worksheet $sheet,
        int $untilRow,
    ): void {
        for ($row = self::START_ROW; $row <= $untilRow; $row++) {
            for ($col = 2; $col <= Coordinate::columnIndexFromString(self::RECAP_ALPA_COL); $col++) {
                $cell = Coordinate::stringFromColumnIndex($col).$row;
                $sheet->setCellValue($cell, null);
            }
        }
    }

    /**
     * @param array<int, array{
     *   no?:int|string,
     *   nisn:string,
     *   nama:string,
     *   lp?:string|null,
     *   sekolah?:string|null,
     *   periodeStart:string,
     *   periodeEnd:string,
     *   marks?:array<string|int, string>
     * }> $rows
     */
    private function fillRows(
        \PhpOffice\PhpSpreadsheet\Worksheet\Worksheet $sheet,
        array $rows,
        int $daysInMonth,
        string $lastUsedDateCol,
    ): void {
        $firstDateIndex = Coordinate::columnIndexFromString(self::FIRST_DATE_COL);
        $recapSakitIndex = Coordinate::columnIndexFromString(self::RECAP_SAKIT_COL);
        $recapAlpaIndex = Coordinate::columnIndexFromString(self::RECAP_ALPA_COL);

        foreach ($rows as $idx => $row) {
            $excelRow = self::START_ROW + $idx;
            $no = isset($row['no']) ? (int) $row['no'] : $idx + 1;
            $nisn = trim((string) ($row['nisn'] ?? ''));
            $nama = trim((string) ($row['nama'] ?? ''));
            $lp = trim((string) ($row['lp'] ?? '-'));
            $sekolah = trim((string) ($row['sekolah'] ?? ''));
            $periodeStart = (string) ($row['periodeStart'] ?? '');
            $periodeEnd = (string) ($row['periodeEnd'] ?? '');
            $marks = is_array($row['marks'] ?? null) ? $row['marks'] : [];

            $sheet->setCellValue("B{$excelRow}", $no);
            $sheet->setCellValueExplicit("C{$excelRow}", $nisn, DataType::TYPE_STRING);
            $sheet->setCellValue("D{$excelRow}", $nama);
            $sheet->setCellValue("E{$excelRow}", $lp === '' ? '-' : $lp);
            $sheet->setCellValue("F{$excelRow}", $sekolah);
            $sheet->setCellValue("G{$excelRow}", "{$periodeStart} s/d {$periodeEnd}");

            for ($day = 1; $day <= $daysInMonth; $day++) {
                $col = Coordinate::stringFromColumnIndex($firstDateIndex + ($day - 1));
                $mark = strtoupper(trim((string) ($marks[$day] ?? $marks[(string) $day] ?? '')));
                if (! in_array($mark, ['S', 'I', 'A'], true)) {
                    $mark = '';
                }
                $sheet->setCellValue("{$col}{$excelRow}", $mark);
            }

            $range = sprintf('%s%d:%s%d', self::FIRST_DATE_COL, $excelRow, $lastUsedDateCol, $excelRow);
            $sheet->setCellValue(self::RECAP_SAKIT_COL.$excelRow, sprintf('=COUNTIF(%s,"S")', $range));
            $sheet->setCellValue(self::RECAP_IZIN_COL.$excelRow, sprintf('=COUNTIF(%s,"I")', $range));
            $sheet->setCellValue(self::RECAP_ALPA_COL.$excelRow, sprintf('=COUNTIF(%s,"A")', $range));

            $sheet->getStyle("B{$excelRow}:B{$excelRow}")->getAlignment()->setHorizontal(Alignment::HORIZONTAL_CENTER);
            $sheet->getStyle("E{$excelRow}:E{$excelRow}")->getAlignment()->setHorizontal(Alignment::HORIZONTAL_CENTER);
            $sheet->getStyle(self::FIRST_DATE_COL.$excelRow.':'.$lastUsedDateCol.$excelRow)
                ->getAlignment()
                ->setHorizontal(Alignment::HORIZONTAL_CENTER);
            $sheet->getStyle(self::RECAP_SAKIT_COL.$excelRow.':'.self::RECAP_ALPA_COL.$excelRow)
                ->getAlignment()
                ->setHorizontal(Alignment::HORIZONTAL_CENTER);

            $sheet->getStyle("C{$excelRow}:D{$excelRow}")
                ->getAlignment()
                ->setHorizontal(Alignment::HORIZONTAL_LEFT)
                ->setVertical(Alignment::VERTICAL_CENTER);
            $sheet->getStyle("F{$excelRow}:G{$excelRow}")
                ->getAlignment()
                ->setHorizontal(Alignment::HORIZONTAL_LEFT)
                ->setVertical(Alignment::VERTICAL_CENTER);
            $sheet->getStyle("B{$excelRow}:".Coordinate::stringFromColumnIndex($recapAlpaIndex)."{$excelRow}")
                ->getAlignment()
                ->setVertical(Alignment::VERTICAL_CENTER);
        }
    }

    private function fillOverallSummaryFormula(
        \PhpOffice\PhpSpreadsheet\Worksheet\Worksheet $sheet,
        int $rowCount,
    ): void {
        $lastDataRow = max(self::START_ROW, self::START_ROW + $rowCount - 1);

        $sheet->setCellValue('AM19', 'JUMLAH SAKIT =');
        $sheet->setCellValue('AN19', sprintf('=SUM(AM%d:AM%d)', self::START_ROW, $lastDataRow));

        $sheet->setCellValue('AM20', 'JUMLAH IZIN =');
        $sheet->setCellValue('AN20', sprintf('=SUM(AN%d:AN%d)', self::START_ROW, $lastDataRow));

        $sheet->setCellValue('AM21', 'JUMLAH ALPA =');
        $sheet->setCellValue('AN21', sprintf('=SUM(AO%d:AO%d)', self::START_ROW, $lastDataRow));
    }

    private function monthNameIndo(int $month): string
    {
        return match ($month) {
            1 => 'Januari',
            2 => 'Februari',
            3 => 'Maret',
            4 => 'April',
            5 => 'Mei',
            6 => 'Juni',
            7 => 'Juli',
            8 => 'Agustus',
            9 => 'September',
            10 => 'Oktober',
            11 => 'November',
            12 => 'Desember',
            default => '-',
        };
    }
}
