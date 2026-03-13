import 'package:flutter/foundation.dart';

import '../../core/services/api_client_base.dart';
import '../../core/services/session_store.dart';

class LeaveRequestViewModel extends ChangeNotifier {
  LeaveRequestViewModel({required this.apiClient, required this.session});

  final ApiClient apiClient;
  final SessionStore session;

  bool loading = false;
  String? error;
  bool success = false;

  Future<void> submit({
    required String type, // IZIN/SAKIT
    required String dateFrom,
    required String dateTo,
    required String reason,
  }) async {
    if (!session.isAuthenticated) return;
    loading = true;
    error = null;
    success = false;
    notifyListeners();
    try {
      await apiClient.postJson(
        '/api/leave/request',
        bearerToken: session.token,
        body: {
          'type': type,
          'dateFrom': dateFrom,
          'dateTo': dateTo,
          'reason': reason,
        },
      );
      success = true;
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

