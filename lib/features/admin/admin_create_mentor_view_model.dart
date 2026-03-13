import 'package:flutter/foundation.dart';

import '../../core/services/api_client_base.dart';
import '../../core/services/session_store.dart';

class AdminCreateMentorViewModel extends ChangeNotifier {
  AdminCreateMentorViewModel({required this.apiClient, required this.session});

  final ApiClient apiClient;
  final SessionStore session;

  bool loading = false;
  String? error;
  String? tempPassword;

  Future<void> createMentor({
    required String email,
    required String fullName,
    String? workUnit,
    String? password,
  }) async {
    if (!session.isAuthenticated) return;
    loading = true;
    error = null;
    tempPassword = null;
    notifyListeners();
    try {
      final data = await apiClient.postJson(
        '/api/admin/mentors',
        bearerToken: session.token,
        body: {
          'email': email,
          'fullName': fullName,
          if (workUnit != null && workUnit.trim().isNotEmpty)
            'workUnit': workUnit.trim(),
          if (password != null && password.trim().isNotEmpty)
            'password': password.trim(),
        },
      );
      if (data is Map) {
        tempPassword = (data['tempPassword'] ?? '').toString();
      }
    } on ApiError catch (e) {
      error = e.message;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
