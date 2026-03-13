import 'package:flutter/foundation.dart';

import '../../app/app_scope.dart';
import '../../core/models/app_user.dart';
import '../../core/services/api_client_base.dart';
import '../../core/services/session_store.dart';

class LoginViewModel extends ChangeNotifier {
  LoginViewModel({
    required this.apiClient,
    required this.session,
  });

  final ApiClient apiClient;
  final SessionStore session;

  bool _loading = false;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;

  Future<void> login({required String email, required String password}) async {
    _setLoading(true);
    _error = null;
    notifyListeners();
    try {
      final data = await apiClient.postJson(
        '/api/auth/login',
        body: {'email': email, 'password': password},
      );
      if (data is! Map) {
        throw ApiError(code: 'BAD_RESPONSE', message: 'Format login tidak valid.');
      }
      final map = Map<String, dynamic>.from(data);
      final token = (map['token'] ?? '').toString();
      final userJson = map['user'];
      if (token.isEmpty || userJson is! Map) {
        throw ApiError(code: 'BAD_RESPONSE', message: 'Login gagal (data tidak lengkap).');
      }
      final user = AppUser.fromJson(Map<String, dynamic>.from(userJson));
      session.setSession(user: user, token: token);
    } on ApiError catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Gagal login: $e';
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  static LoginViewModel of(AppScope scope) {
    return LoginViewModel(apiClient: scope.apiClient, session: scope.session);
  }
}

