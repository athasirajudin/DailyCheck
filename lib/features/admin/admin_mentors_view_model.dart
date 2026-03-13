import 'package:flutter/foundation.dart';

import '../../core/models/admin_user_models.dart';
import '../../core/services/api_client_base.dart';
import '../../core/services/session_store.dart';

class AdminMentorsViewModel extends ChangeNotifier {
  AdminMentorsViewModel({required this.apiClient, required this.session});

  final ApiClient apiClient;
  final SessionStore session;

  bool loading = false;
  String? error;
  List<MentorMiniDto> mentors = const [];

  Future<void> load() async {
    if (!session.isAuthenticated) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final data = await apiClient.getJson(
        '/api/admin/mentors',
        bearerToken: session.token,
      );
      if (data is! List) {
        throw ApiError(
          code: 'BAD_RESPONSE',
          message: 'Format mentor tidak valid.',
        );
      }
      mentors = data
          .whereType<Map>()
          .map((e) => MentorMiniDto.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    } on ApiError catch (e) {
      error = e.message;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> createMentor({
    required String email,
    required String fullName,
    String? workUnit,
    String? password,
  }) async {
    if (!session.isAuthenticated) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      await apiClient.postJson(
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

  Future<void> updateMentor({
    required int id,
    required String email,
    required String fullName,
    String? workUnit,
    String? password,
  }) async {
    if (!session.isAuthenticated) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      await apiClient.postJson(
        '/api/admin/mentors/$id',
        bearerToken: session.token,
        body: {
          'email': email,
          'fullName': fullName,
          'workUnit': workUnit?.trim() ?? '',
          if (password != null && password.trim().isNotEmpty)
            'password': password.trim(),
        },
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

  Future<void> deleteMentor(int id) async {
    if (!session.isAuthenticated) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      await apiClient.deleteJson(
        '/api/admin/mentors/$id',
        bearerToken: session.token,
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
