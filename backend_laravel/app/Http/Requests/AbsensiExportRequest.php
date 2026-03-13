<?php

namespace App\Http\Requests;

use Illuminate\Contracts\Validation\Validator;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Support\Arr;

class AbsensiExportRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'month' => ['required', 'integer', 'between:1,12'],
            'year' => ['required', 'integer', 'between:2000,2100'],
            'rows' => ['required', 'array'],
            'rows.*.no' => ['nullable', 'integer', 'min:1'],
            'rows.*.nisn' => ['required', 'string', 'max:32'],
            'rows.*.nama' => ['required', 'string', 'max:255'],
            'rows.*.lp' => ['nullable', 'string', 'max:5'],
            'rows.*.sekolah' => ['nullable', 'string', 'max:255'],
            'rows.*.periodeStart' => ['required', 'date_format:Y-m-d'],
            'rows.*.periodeEnd' => ['required', 'date_format:Y-m-d'],
            'rows.*.marks' => ['nullable', 'array'],
        ];
    }

    public function messages(): array
    {
        return [
            'month.required' => 'Month wajib diisi.',
            'month.between' => 'Month harus 1 sampai 12.',
            'year.required' => 'Year wajib diisi.',
            'year.between' => 'Year harus di rentang 2000-2100.',
            'rows.required' => 'Rows wajib diisi.',
            'rows.array' => 'Rows harus berupa array.',
            'rows.*.nisn.required' => 'NISN wajib diisi.',
            'rows.*.nama.required' => 'Nama wajib diisi.',
            'rows.*.periodeStart.required' => 'Periode start wajib diisi.',
            'rows.*.periodeEnd.required' => 'Periode end wajib diisi.',
        ];
    }

    protected function withValidator(\Illuminate\Validation\Validator $validator): void
    {
        $validator->after(function (\Illuminate\Validation\Validator $validator): void {
            $rows = $this->input('rows', []);
            if (! is_array($rows)) {
                return;
            }

            foreach ($rows as $rowIndex => $row) {
                if (! is_array($row)) {
                    continue;
                }

                $start = Arr::get($row, 'periodeStart');
                $end = Arr::get($row, 'periodeEnd');
                if (is_string($start) && is_string($end) && $start > $end) {
                    $validator->errors()->add(
                        "rows.$rowIndex.periodeEnd",
                        'Periode end harus lebih besar/sama dengan periode start.'
                    );
                }

                $marks = Arr::get($row, 'marks', []);
                if (! is_array($marks)) {
                    $validator->errors()->add("rows.$rowIndex.marks", 'Marks harus berupa object/array.');
                    continue;
                }

                foreach ($marks as $day => $mark) {
                    if (! is_numeric((string) $day)) {
                        $validator->errors()->add(
                            "rows.$rowIndex.marks",
                            "Key marks '$day' tidak valid. Gunakan 1..31."
                        );
                        continue;
                    }

                    $dayInt = (int) $day;
                    if ($dayInt < 1 || $dayInt > 31) {
                        $validator->errors()->add(
                            "rows.$rowIndex.marks.$day",
                            'Nomor tanggal marks harus 1..31.'
                        );
                    }

                    $markUpper = strtoupper(trim((string) $mark));
                    if ($markUpper !== '' && ! in_array($markUpper, ['S', 'I', 'A'], true)) {
                        $validator->errors()->add(
                            "rows.$rowIndex.marks.$day",
                            "Nilai marks '$markUpper' tidak valid. Gunakan S/I/A."
                        );
                    }
                }
            }
        });
    }

    protected function failedValidation(Validator $validator): void
    {
        throw new HttpResponseException(response()->json([
            'ok' => false,
            'code' => 'VALIDATION_ERROR',
            'message' => 'Validasi export absensi gagal.',
            'errors' => $validator->errors(),
        ], 422));
    }
}
