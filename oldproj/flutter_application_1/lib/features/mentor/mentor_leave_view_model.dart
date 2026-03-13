import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/models/leave_models.dart';
import '../../core/services/api_client_base.dart';
import '../../core/services/session_store.dart';

class MentorLeaveViewModel extends ChangeNotifier {
  MentorLeaveViewModel({required this.apiClient, required this.session});

  final ApiClient apiClient;
  final SessionStore session;

  bool loading = false;
  String? error;
  List<LeaveRequestDto> items = const [];
  bool pendingOnly = true;

  Timer? _timer;

  void start() {
    refresh();
    _timer = Timer.periodic(const Duration(seconds: 8), (_) => refresh(silent: true));
  }

  Future<void> refresh({bool silent = false}) async {
    if (!session.isAuthenticated) return;
    if (!silent) {
      loading = true;
      notifyListeners();
    }
    error = null;
    try {
      final data = await apiClient.getJson('/api/mentor/leave', bearerToken: session.token);
      if (data is! List) throw ApiError(code: 'BAD_RESPONSE', message: 'Format leave list tidak valid.');
      final list = data
          .whereType<Map>()
          .map((e) => LeaveRequestDto.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
      items = pendingOnly ? list.where((e) => e.status == 'PENDING').toList(growable: false) : list;
    } on ApiError catch (e) {
      error = e.message;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void setPendingOnly(bool v) {
    pendingOnly = v;
    refresh(silent: true);
  }

  Future<void> decide({
    required int leaveId,
    required bool approve,
    required String reason,
  }) async {
    if (!session.isAuthenticated) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      await apiClient.postJson(
        '/api/mentor/leave/$leaveId/${approve ? 'approve' : 'reject'}',
        bearerToken: session.token,
        body: {'reason': reason},
      );
      await refresh(silent: true);
    } on ApiError catch (e) {
      error = e.message;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

