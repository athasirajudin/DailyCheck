<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;
use Carbon\CarbonImmutable;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

Artisan::command(
    'absensi:backfill-approved-leave {--dry-run : Hanya simulasi, tanpa update DB} {--from= : Filter leave dari tanggal (YYYY-MM-DD)} {--to= : Filter leave sampai tanggal (YYYY-MM-DD)}',
    function (): int {
        $timezone = 'Asia/Jakarta';
        $dryRun = (bool) $this->option('dry-run');
        $fromOpt = (string) ($this->option('from') ?? '');
        $toOpt = (string) ($this->option('to') ?? '');

        $query = DB::table('leave_requests as lr')
            ->leftJoin('interns as i', 'i.user_id', '=', 'lr.intern_user_id')
            ->leftJoin('users as decider', 'decider.id', '=', 'lr.decided_by_user_id')
            ->select([
                'lr.id',
                'lr.intern_user_id',
                'lr.type',
                'lr.date_from',
                'lr.date_to',
                'lr.status',
                'lr.decided_by_user_id',
                'i.unit_id',
                'decider.role as decider_role',
            ])
            ->where('lr.status', 'APPROVED')
            ->whereIn('lr.type', ['IZIN', 'SAKIT'])
            ->orderBy('lr.id');

        if ($fromOpt !== '') {
            $query->where('lr.date_to', '>=', $fromOpt);
        }
        if ($toOpt !== '') {
            $query->where('lr.date_from', '<=', $toOpt);
        }

        $leaves = $query->get();
        if ($leaves->isEmpty()) {
            $this->info('Tidak ada leave APPROVED untuk diproses.');
            return self::SUCCESS;
        }

        $processedLeave = 0;
        $createdRows = 0;
        $updatedRows = 0;
        $unchangedRows = 0;
        $skippedRows = 0;

        foreach ($leaves as $leave) {
            $processedLeave++;
            $unitId = (int) ($leave->unit_id ?? 0);
            if ($unitId <= 0) {
                $skippedRows++;
                $this->warn("Skip leave_id={$leave->id}: intern tidak punya unit.");
                continue;
            }

            $type = strtoupper((string) $leave->type);
            $deciderRole = strtoupper((string) ($leave->decider_role ?? ''));
            $markedBy = $deciderRole === 'ADMIN' ? 'ADMIN' : 'PEMBIMBING';
            $from = CarbonImmutable::parse((string) $leave->date_from.' 00:00:00', $timezone);
            $to = CarbonImmutable::parse((string) $leave->date_to.' 00:00:00', $timezone);

            for ($cursor = $from; $cursor->lessThanOrEqualTo($to); $cursor = $cursor->addDay()) {
                $date = $cursor->format('Y-m-d');
                $existing = DB::table('attendance_records')
                    ->where('intern_user_id', (int) $leave->intern_user_id)
                    ->where('date', $date)
                    ->first();

                if ($existing) {
                    $sameStatus = strtoupper((string) ($existing->status ?? '')) === $type;
                    $sameMarkedBy = strtoupper((string) ($existing->status_marked_by ?? '')) === $markedBy;
                    if ($sameStatus && $sameMarkedBy) {
                        $unchangedRows++;
                        continue;
                    }
                    $updatedRows++;
                    if ($dryRun) {
                        continue;
                    }

                    DB::table('attendance_records')
                        ->where('id', (int) $existing->id)
                        ->update([
                            'status' => $type,
                            'status_marked_by' => $markedBy,
                            'updated_at' => CarbonImmutable::now($timezone)->format('Y-m-d H:i:s'),
                        ]);
                    continue;
                }

                $createdRows++;
                if ($dryRun) {
                    continue;
                }

                $now = CarbonImmutable::now($timezone)->format('Y-m-d H:i:s');
                DB::table('attendance_records')->insert([
                    'intern_user_id' => (int) $leave->intern_user_id,
                    'unit_id' => $unitId,
                    'date' => $date,
                    'check_in_at' => null,
                    'check_out_at' => null,
                    'status' => $type,
                    'status_marked_by' => $markedBy,
                    'gps_check_in_lat' => null,
                    'gps_check_in_lon' => null,
                    'gps_check_out_lat' => null,
                    'gps_check_out_lon' => null,
                    'checkout_missing' => 0,
                    'created_at' => $now,
                    'updated_at' => $now,
                ]);
            }
        }

        $mode = $dryRun ? 'DRY-RUN' : 'APPLIED';
        $this->info("Backfill {$mode} selesai.");
        $this->table(
            ['processed_leave', 'created_rows', 'updated_rows', 'unchanged_rows', 'skipped_leave'],
            [[
                $processedLeave,
                $createdRows,
                $updatedRows,
                $unchangedRows,
                $skippedRows,
            ]]
        );

        return self::SUCCESS;
    }
)->purpose('Sinkronkan leave APPROVED lama ke attendance_records (IZIN/SAKIT)');
