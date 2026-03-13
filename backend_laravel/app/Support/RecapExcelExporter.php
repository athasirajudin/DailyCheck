<?php

namespace App\Support;

use Carbon\CarbonImmutable;
use Illuminate\Support\Collection;
use PhpOffice\PhpSpreadsheet\Cell\Coordinate;
use PhpOffice\PhpSpreadsheet\Cell\DataType;
use PhpOffice\PhpSpreadsheet\IOFactory;
use PhpOffice\PhpSpreadsheet\Spreadsheet;
use PhpOffice\PhpSpreadsheet\Style\Alignment;
use PhpOffice\PhpSpreadsheet\Style\Border;
use PhpOffice\PhpSpreadsheet\Style\Fill;
use PhpOffice\PhpSpreadsheet\Worksheet\Worksheet;

class RecapExcelExporter
{
    private const START_DATA_ROW = 9;
    private const MIN_TABLE_ROWS = 12;
    private const START_DATE_COL = 8; // H
    private const MAX_TEMPLATE_DATE_COL = 38; // AL

    /**
     * @param Collection<int, object> $rows
     */
    public static function build(
        Collection $rows,
        string $dateFrom,
        string $dateTo,
        string $timezone = 'Asia/Jakarta',
    ): Spreadsheet {
        $spreadsheet = self::loadTemplate();
        $sheet = $spreadsheet->getActiveSheet();

        [$reportStart, $reportEnd, $dates] = self::buildMonthlyWindow($dateFrom, $dateTo, $timezone);
        $daysInMonth = count($dates);
        $lastDateCol = self::START_DATE_COL + max($daysInMonth - 1, 0);
        $sakitCol = $lastDateCol + 1;
        $izinCol = $lastDateCol + 2;
        $alpaCol = $lastDateCol + 3;
        $lastCol = $alpaCol;

        self::clearTemplateValueArea($sheet, $lastCol);
        self::setDateColumnVisibility($sheet, $lastDateCol, $sakitCol);
        self::prepareDynamicMergesAndHeader($sheet, $reportStart, $lastCol, $lastDateCol, $sakitCol, $izinCol, $alpaCol);

        self::writeDateHeaders($sheet, $dates);

        $interns = self::groupByIntern($rows);
        $internCount = count($interns);
        $lastDataRow = max(self::START_DATA_ROW, self::START_DATA_ROW + $internCount - 1);
        $lastTableRow = max($lastDataRow, self::START_DATA_ROW + self::MIN_TABLE_ROWS - 1);

        self::writeInternRows(
            $sheet,
            $interns,
            $dates,
            $lastDateCol,
            $sakitCol,
            $izinCol,
            $alpaCol,
            $lastDataRow,
            $lastTableRow
        );
        self::styleSheet($sheet, $lastCol, $lastDateCol, $sakitCol, $lastDataRow, $lastTableRow);

        return $spreadsheet;
    }

    /**
     * Normalisasi rentang export XLSX ke 1 bulan kalender (berdasarkan dateTo).
     *
     * @return array{0:string,1:string}
     */
    public static function normalizeMonthlyRange(
        string $dateFrom,
        string $dateTo,
        string $timezone = 'Asia/Jakarta',
    ): array {
        [$start, $end] = self::buildMonthlyBoundaries($dateFrom, $dateTo, $timezone);

        return [$start->format('Y-m-d'), $end->format('Y-m-d')];
    }

    /**
     * @return array<int, CarbonImmutable>
     */
    private static function buildDateRange(
        string $dateFrom,
        string $dateTo,
        string $timezone,
    ): array {
        $from = CarbonImmutable::parse($dateFrom.' 00:00:00', $timezone);
        $to = CarbonImmutable::parse($dateTo.' 00:00:00', $timezone);
        if ($from->greaterThan($to)) {
            return [];
        }

        $dates = [];
        for ($cursor = $from; $cursor->lessThanOrEqualTo($to); $cursor = $cursor->addDay()) {
            $dates[] = $cursor;
        }

        return $dates;
    }

    /**
     * @return array{0:CarbonImmutable, 1:CarbonImmutable, 2:array<int, CarbonImmutable>}
     */
    private static function buildMonthlyWindow(
        string $dateFrom,
        string $dateTo,
        string $timezone,
    ): array {
        [$reportStart, $reportEnd] = self::buildMonthlyBoundaries($dateFrom, $dateTo, $timezone);
        $dates = self::buildDateRange(
            $reportStart->format('Y-m-d'),
            $reportEnd->format('Y-m-d'),
            $timezone
        );

        return [$reportStart, $reportEnd, $dates];
    }

    /**
     * @return array{0:CarbonImmutable,1:CarbonImmutable}
     */
    private static function buildMonthlyBoundaries(
        string $dateFrom,
        string $dateTo,
        string $timezone,
    ): array {
        $from = CarbonImmutable::parse($dateFrom.' 00:00:00', $timezone);
        $to = CarbonImmutable::parse($dateTo.' 00:00:00', $timezone);

        // Selalu pakai bulan dari tanggal akhir filter agar stabil saat ganti bulan.
        $anchor = $from->greaterThan($to) ? $from : $to;

        return [$anchor->startOfMonth(), $anchor->endOfMonth()];
    }

    private static function prepareDynamicMergesAndHeader(
        Worksheet $sheet,
        CarbonImmutable $reportStart,
        int $lastCol,
        int $lastDateCol,
        int $sakitCol,
        int $izinCol,
        int $alpaCol,
    ): void {
        self::unmergeIfMerged($sheet, 'B2:'.Coordinate::stringFromColumnIndex($lastCol).'6');
        self::unmergeIfMerged(
            $sheet,
            Coordinate::stringFromColumnIndex(self::START_DATE_COL).'7:'.Coordinate::stringFromColumnIndex($lastDateCol).'7'
        );
        $sheet->mergeCells('B2:'.Coordinate::stringFromColumnIndex($lastCol).'6');
        $sheet->mergeCells(
            Coordinate::stringFromColumnIndex(self::START_DATE_COL).'7:'.Coordinate::stringFromColumnIndex($lastDateCol).'7'
        );

        $sheet->setCellValue('B2', self::monthLabelUpper($reportStart, $reportStart));
        $sheet->getStyle('B2')->getAlignment()
            ->setHorizontal(Alignment::HORIZONTAL_CENTER)
            ->setVertical(Alignment::VERTICAL_CENTER);
        $sheet->getStyle('B2')->getFont()->setBold(false)->setSize(36);

        $sheet->setCellValue('B7', 'No');
        $sheet->setCellValue('C7', 'NISN');
        $sheet->setCellValue('D7', 'Nama');
        $sheet->setCellValue('E7', 'L/P');
        $sheet->setCellValue('F7', 'Sekolah');
        $sheet->setCellValue('G7', 'Periode');

        // Header kiri mengikuti template: merge vertikal baris 7-8 + center.
        foreach (['B', 'C', 'D', 'E', 'F', 'G'] as $col) {
            $mergeRange = "{$col}7:{$col}8";
            self::unmergeIfMerged($sheet, $mergeRange);
            $sheet->mergeCells($mergeRange);
            $sheet->getStyle($mergeRange)->getAlignment()
                ->setHorizontal(Alignment::HORIZONTAL_CENTER)
                ->setVertical(Alignment::VERTICAL_CENTER);
        }

        self::setCell($sheet, self::START_DATE_COL, 7, 'Tanggal');
        self::setCell($sheet, $sakitCol, 8, 'Sakit');
        self::setCell($sheet, $izinCol, 8, 'Izin');
        self::setCell($sheet, $alpaCol, 8, 'Alpa');
    }

    /**
     * @param array<int, CarbonImmutable> $dates
     */
    private static function writeDateHeaders(
        Worksheet $sheet,
        array $dates,
    ): void {
        foreach ($dates as $idx => $date) {
            $col = self::START_DATE_COL + $idx;
            self::setCell($sheet, $col, 8, (int) $date->format('j'));
        }
    }

    /**
     * @param Collection<int, object> $rows
     * @return array<int, array{
     *   internUserId:int,
     *   nisn:string,
     *   fullName:string,
     *   gender:string,
     *   schoolName:string,
     *   period:string,
     *   statuses:array<string,string>,
     *   sakit:int,
     *   izin:int,
     *   alpa:int
     * }>
     */
    private static function groupByIntern(Collection $rows): array
    {
        $byIntern = [];
        foreach ($rows as $row) {
            $internUserId = (int) ($row->intern_user_id ?? 0);
            if ($internUserId <= 0) {
                continue;
            }

            if (! isset($byIntern[$internUserId])) {
                $periodStart = trim((string) ($row->internship_start ?? ''));
                $periodEnd = trim((string) ($row->internship_end ?? ''));
                $period = trim($periodStart.' s/d '.$periodEnd);

                $byIntern[$internUserId] = [
                    'internUserId' => $internUserId,
                    'nisn' => trim((string) ($row->nisn ?? '')),
                    'fullName' => trim((string) ($row->full_name ?? '')),
                    'gender' => strtoupper(trim((string) ($row->gender ?? '-'))),
                    'schoolName' => trim((string) ($row->school_name ?? '')),
                    'period' => $period === 's/d' ? '-' : $period,
                    'statuses' => [],
                    'sakit' => 0,
                    'izin' => 0,
                    'alpa' => 0,
                ];
            }

            $status = strtoupper(trim((string) ($row->status ?? '')));
            $statusCode = self::statusCode($status);
            $date = (string) ($row->date ?? '');
            if ($date !== '') {
                $byIntern[$internUserId]['statuses'][$date] = $statusCode;
            }

            if ($status === 'SAKIT') {
                $byIntern[$internUserId]['sakit']++;
            } elseif ($status === 'IZIN') {
                $byIntern[$internUserId]['izin']++;
            } elseif ($status === 'ALPA') {
                $byIntern[$internUserId]['alpa']++;
            }
        }

        $items = array_values($byIntern);
        usort($items, fn (array $a, array $b): int => strcasecmp($a['fullName'], $b['fullName']));

        return $items;
    }

    /**
     * @param array<int, array{
     *   internUserId:int,
     *   nisn:string,
     *   fullName:string,
     *   gender:string,
     *   schoolName:string,
     *   period:string,
     *   statuses:array<string,string>,
     *   sakit:int,
     *   izin:int,
     *   alpa:int
     * }> $interns
     * @param array<int, CarbonImmutable> $dates
     */
    private static function writeInternRows(
        Worksheet $sheet,
        array $interns,
        array $dates,
        int $lastDateCol,
        int $sakitCol,
        int $izinCol,
        int $alpaCol,
        int $lastDataRow,
        int $lastTableRow,
    ): void {
        $currentRow = self::START_DATA_ROW;

        foreach ($interns as $idx => $intern) {
            self::setCell($sheet, 2, $currentRow, $idx + 1);
            self::setCellExplicitString($sheet, 3, $currentRow, $intern['nisn']);
            self::setCell($sheet, 4, $currentRow, $intern['fullName']);
            self::setCell($sheet, 5, $currentRow, self::normalizeGender($intern['gender']));
            self::setCell($sheet, 6, $currentRow, $intern['schoolName']);
            self::setCell($sheet, 7, $currentRow, $intern['period']);

            foreach ($dates as $dateIdx => $date) {
                $dateKey = $date->format('Y-m-d');
                $col = self::START_DATE_COL + $dateIdx;
                self::setCell(
                    $sheet,
                    $col,
                    $currentRow,
                    $intern['statuses'][$dateKey] ?? ''
                );
            }

            $dateRange = Coordinate::stringFromColumnIndex(self::START_DATE_COL).$currentRow.':'
                .Coordinate::stringFromColumnIndex($lastDateCol).$currentRow;
            self::setCell($sheet, $sakitCol, $currentRow, sprintf('=COUNTIF(%s,"S")', $dateRange));
            self::setCell($sheet, $izinCol, $currentRow, sprintf('=COUNTIF(%s,"I")', $dateRange));
            self::setCell($sheet, $alpaCol, $currentRow, sprintf('=COUNTIF(%s,"A")', $dateRange));

            $currentRow++;
        }

        // Blok JUMLAH fixed sesuai layout terbaru:
        // AM:AO untuk "JUMLAH =", AP untuk label, AQ untuk angka, di baris 18..20.
        $jumlahRow = 18;
        $leftStartL = 'AM';
        $leftEndL = 'AO';
        $labelL = 'AP';
        $valueL = 'AQ';
        $sakitL = Coordinate::stringFromColumnIndex($sakitCol);
        $izinL = Coordinate::stringFromColumnIndex($izinCol);
        $alpaL = Coordinate::stringFromColumnIndex($alpaCol);

        self::unmergeIfMerged($sheet, "{$leftStartL}{$jumlahRow}:{$leftEndL}".($jumlahRow + 2));
        $sheet->mergeCells("{$leftStartL}{$jumlahRow}:{$leftEndL}".($jumlahRow + 2));
        $sheet->setCellValue("{$leftStartL}{$jumlahRow}", 'JUMLAH  =');

        $sheet->setCellValue("{$labelL}{$jumlahRow}", 'SAKIT');
        $sheet->setCellValue("{$labelL}".($jumlahRow + 1), 'IZIN');
        $sheet->setCellValue("{$labelL}".($jumlahRow + 2), 'ALPA');

        $sheet->setCellValue(
            "{$valueL}{$jumlahRow}",
            "=SUM({$sakitL}".self::START_DATA_ROW.":{$sakitL}{$lastDataRow})"
        );
        $sheet->setCellValue(
            "{$valueL}".($jumlahRow + 1),
            "=SUM({$izinL}".self::START_DATA_ROW.":{$izinL}{$lastDataRow})"
        );
        $sheet->setCellValue(
            "{$valueL}".($jumlahRow + 2),
            "=SUM({$alpaL}".self::START_DATA_ROW.":{$alpaL}{$lastDataRow})"
        );

        // Format blok jumlah: font 14, "JUMLAH =" center, label kiri, nilai center.
        $sheet->getStyle("{$leftStartL}{$jumlahRow}:{$valueL}".($jumlahRow + 2))
            ->getFont()
            ->setSize(14);
        $sheet->getStyle("{$leftStartL}{$jumlahRow}:{$leftEndL}".($jumlahRow + 2))
            ->getAlignment()
            ->setHorizontal(Alignment::HORIZONTAL_CENTER)
            ->setVertical(Alignment::VERTICAL_CENTER);
        $sheet->getStyle("{$labelL}{$jumlahRow}:{$labelL}".($jumlahRow + 2))
            ->getAlignment()
            ->setHorizontal(Alignment::HORIZONTAL_LEFT)
            ->setVertical(Alignment::VERTICAL_CENTER);
        $sheet->getStyle("{$valueL}{$jumlahRow}:{$valueL}".($jumlahRow + 2))
            ->getAlignment()
            ->setHorizontal(Alignment::HORIZONTAL_CENTER)
            ->setVertical(Alignment::VERTICAL_CENTER);
    }

    private static function styleSheet(
        Worksheet $sheet,
        int $lastCol,
        int $lastDateCol,
        int $sakitCol,
        int $lastDataRow,
        int $lastTableRow,
    ): void {
        $startCell = 'B7';
        $endCell = Coordinate::stringFromColumnIndex($lastCol).$lastTableRow;

        $sheet->getStyle("$startCell:$endCell")->getBorders()->getAllBorders()->setBorderStyle(Border::BORDER_THIN);
        // Hilangkan garis bawah tabel supaya tidak double dengan garis separator.
        $tableBottomRange = 'B'.$lastTableRow.':'.Coordinate::stringFromColumnIndex($lastCol).$lastTableRow;
        $sheet->getStyle($tableBottomRange)->getBorders()->getBottom()->setBorderStyle(Border::BORDER_NONE);

        // Pola manual Excel: No Border dulu, lalu Top Border (baris setelah tabel).
        $separatorRow = $lastTableRow + 1;
        $maxCol = max($lastCol, Coordinate::columnIndexFromString($sheet->getHighestColumn()));
        $separatorClearRange = 'B'.$separatorRow.':'.Coordinate::stringFromColumnIndex($maxCol).($separatorRow + 2);
        $separatorTopRange = 'B'.$separatorRow.':'.Coordinate::stringFromColumnIndex($lastCol).$separatorRow;
        $sheet->getStyle($separatorClearRange)->getBorders()->getAllBorders()->setBorderStyle(Border::BORDER_NONE);
        $sheet->getStyle($separatorTopRange)->getBorders()->getTop()->setBorderStyle(Border::BORDER_THIN);
        $sheet->getStyle("B7:{$endCell}")
            ->getAlignment()
            ->setVertical(Alignment::VERTICAL_CENTER);

        $headerEnd = Coordinate::stringFromColumnIndex($lastCol).'8';
        $sheet->getStyle("B7:$headerEnd")->getFont()->setBold(true);
        $sheet->getStyle("B7:$headerEnd")
            ->getAlignment()
            ->setHorizontal(Alignment::HORIZONTAL_CENTER);
        $sheet->getStyle("B7:$headerEnd")->getFill()->setFillType(Fill::FILL_SOLID)->getStartColor()->setARGB('FFDCE6F1');

        // Alignment sesuai kebutuhan: center No, NISN, L/P, Periode, tanggal, rekap.
        $sheet->getStyle('B'.self::START_DATA_ROW.':B'.$lastTableRow)->getAlignment()->setHorizontal(Alignment::HORIZONTAL_CENTER);
        $sheet->getStyle('C'.self::START_DATA_ROW.':C'.$lastTableRow)->getAlignment()->setHorizontal(Alignment::HORIZONTAL_CENTER);
        $sheet->getStyle('E'.self::START_DATA_ROW.':E'.$lastTableRow)->getAlignment()->setHorizontal(Alignment::HORIZONTAL_CENTER);
        $sheet->getStyle('G'.self::START_DATA_ROW.':G'.$lastTableRow)->getAlignment()->setHorizontal(Alignment::HORIZONTAL_CENTER);
        $sheet->getStyle(
            Coordinate::stringFromColumnIndex(self::START_DATE_COL).self::START_DATA_ROW
            .':'
            .Coordinate::stringFromColumnIndex($lastDateCol).$lastTableRow
        )->getAlignment()->setHorizontal(Alignment::HORIZONTAL_CENTER);
        $sheet->getStyle(
            Coordinate::stringFromColumnIndex($sakitCol).self::START_DATA_ROW
            .':'
            .Coordinate::stringFromColumnIndex($lastCol).$lastTableRow
        )->getAlignment()->setHorizontal(Alignment::HORIZONTAL_CENTER);
        $sheet->getStyle('D'.self::START_DATA_ROW.':D'.$lastTableRow)->getAlignment()->setHorizontal(Alignment::HORIZONTAL_LEFT);
        $sheet->getStyle('F'.self::START_DATA_ROW.':F'.$lastTableRow)->getAlignment()->setHorizontal(Alignment::HORIZONTAL_LEFT);

        // Lebar kolom sekolah sesuai setting manual template.
        $sheet->getColumnDimension('F')->setWidth(58.33);

        for ($row = self::START_DATA_ROW; $row <= $lastTableRow; $row++) {
            $sheet->getRowDimension($row)->setRowHeight(22);
        }
    }

    private static function clearTemplateValueArea(Worksheet $sheet, int $lastCol): void
    {
        $maxCol = max(Coordinate::columnIndexFromString($sheet->getHighestColumn()), $lastCol);
        $maxRow = max($sheet->getHighestRow(), 80);

        // Bersihkan area dinamis agar nilai template lama (hari/sum) tidak ikut terbawa.
        for ($row = 7; $row <= $maxRow; $row++) {
            for ($col = self::START_DATE_COL; $col <= $maxCol; $col++) {
                self::setCell($sheet, $col, $row, '');
            }
        }

        for ($row = self::START_DATA_ROW; $row <= $maxRow; $row++) {
            for ($col = 2; $col <= 7; $col++) {
                self::setCell($sheet, $col, $row, '');
            }
        }
    }

    private static function setDateColumnVisibility(Worksheet $sheet, int $lastDateCol, int $sakitCol): void
    {
        for ($col = self::START_DATE_COL; $col <= self::MAX_TEMPLATE_DATE_COL; $col++) {
            $letter = Coordinate::stringFromColumnIndex($col);
            // Kolom setelah lastDate bisa dipakai untuk rekap dinamis (sakit/izin/alpa), jadi jangan di-hide.
            $isUnusedDateOnly = $col > $lastDateCol && $col < $sakitCol;
            $sheet->getColumnDimension($letter)->setVisible(! $isUnusedDateOnly);
        }
    }

    private static function unmergeIfMerged(Worksheet $sheet, string $range): void
    {
        $merges = array_keys($sheet->getMergeCells());
        if ($merges === []) {
            return;
        }

        [$targetStart, $targetEnd] = Coordinate::rangeBoundaries($range);
        [$targetCol1, $targetRow1] = $targetStart;
        [$targetCol2, $targetRow2] = $targetEnd;

        foreach ($merges as $mergedRange) {
            [$mergeStart, $mergeEnd] = Coordinate::rangeBoundaries($mergedRange);
            [$mergeCol1, $mergeRow1] = $mergeStart;
            [$mergeCol2, $mergeRow2] = $mergeEnd;

            $disjoint = $mergeCol2 < $targetCol1
                || $mergeCol1 > $targetCol2
                || $mergeRow2 < $targetRow1
                || $mergeRow1 > $targetRow2;
            if (! $disjoint) {
                $sheet->unmergeCells($mergedRange);
            }
        }
    }

    private static function monthLabelUpper(
        CarbonImmutable $from,
        CarbonImmutable $to,
    ): string {
        if ($from->format('Y-m') === $to->format('Y-m')) {
            return strtoupper(self::indoMonth((int) $from->format('n')));
        }

        return strtoupper(
            self::indoMonth((int) $from->format('n')).' - '.self::indoMonth((int) $to->format('n'))
        );
    }

    private static function indoMonth(int $month): string
    {
        $map = [
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
        ];

        return $map[$month] ?? '-';
    }

    private static function statusCode(string $status): string
    {
        return match ($status) {
            'SAKIT' => 'S',
            'IZIN' => 'I',
            'ALPA' => 'A',
            default => '',
        };
    }

    private static function normalizeGender(string $gender): string
    {
        return match (strtoupper(trim($gender))) {
            'L', 'LAKI-LAKI' => 'L',
            'P', 'PEREMPUAN' => 'P',
            default => '-',
        };
    }

    private static function setCell(
        Worksheet $sheet,
        int $column,
        int $row,
        mixed $value,
    ): void {
        $cell = Coordinate::stringFromColumnIndex($column).$row;
        $sheet->setCellValue($cell, $value);
    }

    private static function setCellExplicitString(
        Worksheet $sheet,
        int $column,
        int $row,
        string $value,
    ): void {
        $cell = Coordinate::stringFromColumnIndex($column).$row;
        $sheet->getCell($cell)->setValueExplicit($value, DataType::TYPE_STRING);
    }

    private static function loadTemplate(): Spreadsheet
    {
        $templatePath = storage_path('reference/absensi_template.xlsx');
        if (is_file($templatePath)) {
            /** @var Spreadsheet $sheet */
            $sheet = IOFactory::load($templatePath);

            return $sheet;
        }

        return new Spreadsheet();
    }
}
