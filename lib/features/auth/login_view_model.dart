import 'package:flutter/foundation.dart';

import '../../app/app_scope.dart';
import '../../core/models/app_user.dart';
import '../../core/services/api_client_base.dart';
import '../../core/services/session_store.dart';
import 'login_mode.dart';

class LoginViewModel extends ChangeNotifier {
  LoginViewModel({required this.apiClient, required this.session});

  final ApiClient apiClient;
  final SessionStore session;

  bool _loading = false;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;

  Future<void> login({
    required String identifier,
    required String password,
    required LoginMode mode,
    String? adminAccessTicket,
  }) async {
    final validationError = _validateInput(
      identifier: identifier,
      password: password,
      mode: mode,
      adminAccessTicket: adminAccessTicket,
    );
    if (validationError != null) {
      _error = validationError;
      notifyListeners();
      return;
    }

    _setLoading(true);
    _error = null;
    notifyListeners();
    try {
      final data = await apiClient.postJson(
        '/api/auth/login',
        body: {
          'identifier': identifier,
          'password': password,
          'mode': _modeToApi(mode),
          if (adminAccessTicket != null && adminAccessTicket.trim().isNotEmpty)
            'admin_access_ticket': adminAccessTicket.trim(),
        },
      );
      if (data is! Map) {
        throw ApiError(
          code: 'BAD_RESPONSE',
          message: 'Format login tidak valid.',
        );
      }
      final map = Map<String, dynamic>.from(data);
      final token = (map['token'] ?? '').toString();
      final userJson = map['user'];
      if (token.isEmpty || userJson is! Map) {
        throw ApiError(
          code: 'BAD_RESPONSE',
          message: 'Login gagal (data tidak lengkap).',
        );
      }
      final user = AppUser.fromJson(Map<String, dynamic>.from(userJson));
      if (!_isAllowedRole(user.role, mode)) {
        throw ApiError(
          code: 'UNAUTHORIZED_ROLE',
          message: _roleErrorMessage(mode),
          statusCode: 403,
        );
      }
      session.setSession(user: user, token: token);
    } on ApiError catch (e) {
      _error = _isCredentialError(e)
          ? _credentialErrorMessage(identifier)
          : e.message;
    } catch (e) {
      if (_looksLikeProgressEventError(e)) {
        _error = _credentialErrorMessage(identifier);
      } else {
        _error = 'Terjadi kendala saat login, coba lagi.';
      }
    } finally {
      _setLoading(false);
    }
  }

  bool _isCredentialError(ApiError e) {
    final code = e.code.trim().toUpperCase();
    if (code == 'UNAUTHORIZED_ROLE' ||
        code == 'ADMIN_ACCESS_REQUIRED' ||
        code == 'ADMIN_ACCESS_EXPIRED' ||
        code == 'INVALID_LOGIN_METHOD' ||
        code == 'INVALID_LOGIN_MODE') {
      return false;
    }
    if (e.statusCode == 401 || e.statusCode == 403) {
      return true;
    }
    if (code == 'INVALID_CREDENTIALS' ||
        code == 'UNAUTHORIZED' ||
        code == 'AUTH_FAILED') {
      return true;
    }
    final msg = e.message.toLowerCase();
    return msg.contains('password salah') || msg.contains('credentials');
  }

  bool _looksLikeProgressEventError(Object e) {
    final text = e.toString().toLowerCase();
    return text.contains('progressevent');
  }

  String _credentialErrorMessage(String identifier) {
    final id = identifier.trim();
    if (id.contains('@')) {
      return 'email atau password salah, coba lagi.';
    }
    final onlyDigits = RegExp(r'^\d+$').hasMatch(id);
    if (onlyDigits) {
      return 'NISN atau Password salah, coba lagi.';
    }
    return 'username atau password salah, coba lagi.';
  }

  String? _validateInput({
    required String identifier,
    required String password,
    required LoginMode mode,
    required String? adminAccessTicket,
  }) {
    final trimmedIdentifier = identifier.trim();
    if (trimmedIdentifier.isEmpty || password.isEmpty) {
      return 'Semua field login wajib diisi.';
    }

    if (mode == LoginMode.intern) {
      final onlyDigits = RegExp(r'^\d+$').hasMatch(trimmedIdentifier);
      if (!onlyDigits) {
        return 'Masukkan NISN yang valid untuk akun intern.';
      }
      return null;
    }

    final validEmail = RegExp(
      r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
    ).hasMatch(trimmedIdentifier);
    if (!validEmail) {
      return mode == LoginMode.admin
          ? 'Masukkan email yang valid untuk akun admin.'
          : 'Masukkan email yang valid untuk akun pembimbing.';
    }
    if (mode == LoginMode.admin &&
        (adminAccessTicket == null || adminAccessTicket.trim().isEmpty)) {
      return 'Verifikasi PIN admin sudah habis. Kembali dan verifikasi ulang.';
    }
    return null;
  }

  Future<String> verifyAdminPin(String pin) async {
    final trimmedPin = pin.trim();
    if (trimmedPin.isEmpty) {
      throw ApiError(
        code: 'MISSING_PIN',
        message: 'PIN admin wajib diisi.',
        statusCode: 422,
      );
    }

    final data = await apiClient.postJson(
      '/api/auth/admin-access/verify-pin',
      body: {'pin': trimmedPin},
    );
    if (data is! Map) {
      throw ApiError(
        code: 'BAD_RESPONSE',
        message: 'Format verifikasi PIN tidak valid.',
      );
    }

    final map = Map<String, dynamic>.from(data);
    final ticket = (map['ticket'] ?? '').toString().trim();
    if (ticket.isEmpty) {
      throw ApiError(
        code: 'BAD_RESPONSE',
        message: 'Tiket akses admin tidak ditemukan.',
      );
    }
    return ticket;
  }

  bool _isAllowedRole(UserRole role, LoginMode mode) {
    return switch (mode) {
      LoginMode.intern => role == UserRole.intern,
      LoginMode.admin => role == UserRole.admin,
      LoginMode.mentor => role == UserRole.pembimbing,
    };
  }

  String _roleErrorMessage(LoginMode mode) {
    return switch (mode) {
      LoginMode.intern =>
        'Akun ini bukan akun intern. Gunakan halaman login admin/pembimbing.',
      LoginMode.admin =>
        'Akun ini bukan akun admin. Gunakan halaman login yang sesuai.',
      LoginMode.mentor =>
        'Akun ini bukan akun pembimbing. Gunakan halaman login yang sesuai.',
    };
  }

  String _modeToApi(LoginMode mode) {
    return switch (mode) {
      LoginMode.intern => 'INTERN',
      LoginMode.admin => 'ADMIN',
      LoginMode.mentor => 'PEMBIMBING',
    };
  }

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  static LoginViewModel of(AppScope scope) {
    return LoginViewModel(apiClient: scope.apiClient, session: scope.session);
  }
}
