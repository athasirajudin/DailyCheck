import 'package:flutter/foundation.dart';

import '../../core/models/admin_user_models.dart';
import '../../core/models/registration_models.dart';
import '../../core/models/unit_models.dart';
import '../../core/services/api_client_base.dart';
import '../../core/services/session_store.dart';

class AdminRegistrationViewModel extends ChangeNotifier {
  AdminRegistrationViewModel({required this.apiClient, required this.session});

  final ApiClient apiClient;
  final SessionStore session;
  bool _disposed = false;

  bool loading = false;
  String? error;

  List<RegistrationRequestDto> pending = const [];
  List<MentorMiniDto> mentors = const [];
  List<UnitDto> units = const [];

  Future<void> loadAll() async {
    if (!session.isAuthenticated) return;
    loading = true;
    error = null;
    _safeNotify();
    try {
      final reqData = await apiClient.getJson(
        '/api/admin/registration-requests',
        bearerToken: session.token,
        query: {'status': 'PENDING'},
      );
      if (reqData is! List) throw ApiError(code: 'BAD_RESPONSE', message: 'Format request tidak valid.');
      pending = reqData
          .whereType<Map>()
          .map((e) => RegistrationRequestDto.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);

      final mentorsData = await apiClient.getJson('/api/admin/mentors', bearerToken: session.token);
      if (mentorsData is List) {
        mentors = mentorsData
            .whereType<Map>()
            .map((e) => MentorMiniDto.fromJson(Map<String, dynamic>.from(e)))
            .toList(growable: false);
      }

      final unitsData = await apiClient.getJson('/api/units', bearerToken: session.token);
      if (unitsData is List) {
        units = unitsData.whereType<Map>().map((e) => UnitDto.fromJson(Map<String, dynamic>.from(e))).toList(growable: false);
      }
    } on ApiError catch (e) {
      error = e.message;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      _safeNotify();
    }
  }

  Future<String?> approve({
    required int requestId,
    required int unitId,
    required int? mentorUserId,
    required String internshipStart,
    required String internshipEnd,
    required String tempPassword,
    required String reason,
  }) async {
    if (!session.isAuthenticated) return null;
    loading = true;
    error = null;
    _safeNotify();
    try {
      final data = await apiClient.postJson(
        '/api/admin/registration-requests/$requestId/approve',
        bearerToken: session.token,
        body: {
          'unitId': unitId,
          'mentorUserId': mentorUserId,
          'internshipStart': internshipStart,
          'internshipEnd': internshipEnd,
          'tempPassword': tempPassword.trim().isEmpty ? null : tempPassword.trim(),
          'reason': reason,
        },
      );
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        await loadAll();
        return (map['tempPassword'] ?? '').toString();
      }
      await loadAll();
      return null;
    } on ApiError catch (e) {
      error = e.message;
      return null;
    } catch (e) {
      error = e.toString();
      return null;
    } finally {
      loading = false;
      _safeNotify();
    }
  }

  Future<void> reject({required int requestId, required String reason}) async {
    if (!session.isAuthenticated) return;
    loading = true;
    error = null;
    _safeNotify();
    try {
      await apiClient.postJson(
        '/api/admin/registration-requests/$requestId/reject',
        bearerToken: session.token,
        body: {'reason': reason},
      );
      await loadAll();
    } on ApiError catch (e) {
      error = e.message;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      _safeNotify();
    }
  }

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
