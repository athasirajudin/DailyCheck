<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Support\LegacyApiResponse;
use Illuminate\Support\Facades\DB;

class UnitController extends Controller
{
    public function index()
    {
        $rows = DB::table('units')
            ->select(['id', 'name', 'geofence_lat', 'geofence_lon', 'geofence_radius_m'])
            ->orderBy('id')
            ->get();

        $data = $rows->map(fn (object $row): array => [
            'id' => (int) $row->id,
            'name' => $row->name,
            'geofenceLat' => (float) $row->geofence_lat,
            'geofenceLon' => (float) $row->geofence_lon,
            'geofenceRadiusM' => (int) $row->geofence_radius_m,
        ])->all();

        return LegacyApiResponse::ok($data);
    }

    public function publicIndex()
    {
        $rows = DB::table('units')
            ->select(['id', 'name'])
            ->orderBy('id')
            ->get();

        $data = $rows->map(fn (object $row): array => [
            'id' => (int) $row->id,
            'name' => $row->name,
        ])->all();

        return LegacyApiResponse::ok($data);
    }
}
