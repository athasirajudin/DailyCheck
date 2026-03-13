<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Support\LegacyApiResponse;
use App\Support\LegacyRequest;
use Carbon\CarbonImmutable;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class RegistrationController extends Controller
{
    public function store(Request $request)
    {
        $body = LegacyRequest::jsonBody($request, $invalidJson);
        if ($invalidJson) {
            return LegacyApiResponse::error('BAD_JSON', 'Body JSON tidak valid.', 400);
        }

        $missing = LegacyRequest::missingFields($body, ['email', 'fullName', 'unitId', 'internshipStart', 'internshipEnd']);
        if ($missing !== []) {
            return LegacyApiResponse::error('MISSING_FIELDS', 'Field wajib belum diisi.', 422, ['missing' => $missing]);
        }

        $email = strtolower(trim((string) $body['email']));
        $fullName = trim((string) $body['fullName']);
        $unitId = (int) $body['unitId'];
        $mentorUserId = array_key_exists('mentorUserId', $body)
            ? ($body['mentorUserId'] === null ? null : (int) $body['mentorUserId'])
            : null;
        $schoolName = trim((string) ($body['schoolName'] ?? ''));
        $schoolAddress = trim((string) ($body['schoolAddress'] ?? ''));
        $internshipStart = (string) $body['internshipStart'];
        $internshipEnd = (string) $body['internshipEnd'];
        $notes = trim((string) ($body['notes'] ?? ''));

        if ($email === '' || $fullName === '') {
            return LegacyApiResponse::error('BAD_INPUT', 'Email dan nama wajib diisi.', 422);
        }

        if ($internshipStart > $internshipEnd) {
            return LegacyApiResponse::error('BAD_RANGE', 'internshipStart harus <= internshipEnd.', 422);
        }

        $unitExists = DB::table('units')->where('id', $unitId)->exists();
        if (! $unitExists) {
            return LegacyApiResponse::error('NOT_FOUND', 'Unit tidak ditemukan.', 404);
        }

        $userExists = DB::table('users')->where('email', $email)->exists();
        if ($userExists) {
            return LegacyApiResponse::error('EMAIL_USED', 'Email sudah terdaftar. Hubungi admin jika butuh reset.', 409);
        }

        $pendingExists = DB::table('registration_requests')
            ->where('email', $email)
            ->where('status', 'PENDING')
            ->exists();
        if ($pendingExists) {
            return LegacyApiResponse::error('ALREADY_PENDING', 'Request pendaftaran kamu masih PENDING.', 409);
        }

        $id = DB::table('registration_requests')->insertGetId([
            'email' => $email,
            'full_name' => $fullName,
            'unit_id' => $unitId,
            'mentor_user_id' => $mentorUserId,
            'school_name' => $schoolName === '' ? null : $schoolName,
            'school_address' => $schoolAddress === '' ? null : $schoolAddress,
            'internship_start' => $internshipStart,
            'internship_end' => $internshipEnd,
            'notes' => $notes,
            'status' => 'PENDING',
            'created_at' => CarbonImmutable::now('Asia/Jakarta')->format('Y-m-d H:i:s'),
        ]);

        return LegacyApiResponse::ok([
            'requestId' => (int) $id,
            'status' => 'PENDING',
        ], 201);
    }
}
