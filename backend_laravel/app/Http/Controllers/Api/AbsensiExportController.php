<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\AbsensiExportRequest;
use App\Services\AbsensiExcelExporter;
use Illuminate\Http\JsonResponse;
use Symfony\Component\HttpFoundation\BinaryFileResponse;
use Throwable;

class AbsensiExportController extends Controller
{
    public function __construct(
        private readonly AbsensiExcelExporter $exporter
    ) {
    }

    public function export(AbsensiExportRequest $request): BinaryFileResponse|JsonResponse
    {
        try {
            $result = $this->exporter->export($request->validated());

            return response()->download(
                $result['path'],
                $result['filename'],
                [
                    'Content-Type' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                ]
            )->deleteFileAfterSend(true);
        } catch (Throwable $e) {
            return response()->json([
                'ok' => false,
                'code' => 'EXPORT_FAILED',
                'message' => $e->getMessage(),
            ], 500);
        }
    }
}
