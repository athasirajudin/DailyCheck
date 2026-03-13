<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Support\LegacyApiResponse;
use Illuminate\Http\Request;

class UserController extends Controller
{
    public function me(Request $request)
    {
        $user = $request->attributes->get('auth_user');
        if (! is_array($user)) {
            return LegacyApiResponse::error('UNAUTHENTICATED', 'Butuh login.', 401);
        }

        return LegacyApiResponse::ok([
            'userId' => (int) $user['user_id'],
            'email' => $user['email'],
            'fullName' => $user['full_name'],
            'role' => $user['role'],
        ]);
    }
}
