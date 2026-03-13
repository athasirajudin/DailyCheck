import 'package:flutter/foundation.dart';

import '../../core/models/leave_models.dart';
import '../../core/services/api_client_base.dart';
import '../../core/services/session_store.dart';

class MentorInternsManageViewModel extends ChangeNotifier {
  MentorInternsManageViewModel({required this.apiClient, required this.session});

  final ApiClient apiClient;
  final SessionStore session;

  bool loading = false;
  String? error;
  List<InternDto> interns = const [];

  Future<void> load() async {
    if (!session.isAuthenticated) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final data = await apiClient.getJson('/api/mentor/interns', bearerToken: session.token);
      if (data is! List) throw ApiError(code: 'BAD_RESPONSE', message: 'Format intern tidak valid.');
      interns = data.whereType<Map>().map((e) => InternDto.fromJson(Map<String, dynamic>.from(e))).toList(growable: false);
    } on ApiError catch (e) {
      error = e.message;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> toggleActive({required int userId, required bool activate}) async {
    if (!session.isAuthenticated) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      await apiClient.postJson('/api/mentor/interns/$userId/${activate ? 'activate' : 'deactivate'}', bearerToken: session.token);
      await load();
    } on ApiError catch (e) {
      error = e.message;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> deletePermanently({required int userId, required bool force}) async {
    if (!session.isAuthenticated) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      await apiClient.postJson(
        '/api/mentor/interns/$userId',
        bearerToken: session.token,
        body: {'confirm': 'HAPUS', 'force': force},
      );
      await load();
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

