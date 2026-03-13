<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Legacy\LegacyBridge;
use Illuminate\Http\Request;

class LegacyFallbackController extends Controller
{
    public function __invoke(Request $request)
    {
        return LegacyBridge::dispatch($request);
    }
}
