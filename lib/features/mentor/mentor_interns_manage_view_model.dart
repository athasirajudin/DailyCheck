import 'package:flutter/foundation.dart';

import '../../core/models/leave_models.dart';
import '../../core/models/unit_models.dart';
import '../../core/services/api_client_base.dart';
import '../../core/services/session_store.dart';

class MentorInternsManageViewModel extends ChangeNotifier {
  MentorInternsManageViewModel({required this.apiClient, required this.session});

  final ApiClient apiClient;
  final SessionStore session;

  bool loading = false;
  String? error;
  List<InternDto> interns = const [];
  List<UnitDto> units = const [];

  Future<void> load() async {
    if (!session.isAuthenticated) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final data = await apiClient.getJson('/api/mentor/interns', bearerToken: session.token);
      if (data is! List) throw ApiError(code: 'BAD_RESPONSE', message: 'Format intern tidak valid.');
      interns = data.whereType<Map>().map((e) => InternDto.fromJson(Map<String, dynamic>.from(e))).toList(growable: false);

      final unitsData = await apiClient.getJson('/api/mentor/units', bearerToken: session.token);
      if (unitsData is List) {
        units = unitsData.whereType<Map>().map((e) => UnitDto.fromJson(Map<String, dynamic>.from(e))).toList(growable: false);
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

  Future<bool> update({
    required int userId,
    required String fullName,
    required String nisn,
    required String? gender,
    required int unitId,
    required String internshipStart,
    required String internshipEnd,
    required String schoolName,
    required String schoolAddress,
    required bool active,
  }) async {
    if (!session.isAuthenticated) return false;
    loading = true;
    error = null;
    notifyListeners();
    try {
      await apiClient.postJson(
          '/api/mentor/interns/$userId',
          bearerToken: session.token,
          body: {
            'fullName': fullName,
            'nisn': nisn,
            'gender': gender,
            'unitId': unitId,
            'internshipStart': internshipStart,
            'internshipEnd': internshipEnd,
            'schoolName': schoolName,
            'schoolAddress': schoolAddress,
            'active': active,
          },
        );
      await load();
      return true;
    } on ApiError catch (e) {
      error = e.message;
      return false;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
