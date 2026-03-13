import 'package:flutter/foundation.dart';

import '../../core/models/admin_user_models.dart';
import '../../core/models/unit_models.dart';
import '../../core/services/api_client_base.dart';
import '../../core/services/session_store.dart';

class AdminInternRowDto {
  AdminInternRowDto({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.unitId,
    required this.unitName,
    required this.mentorUserId,
    required this.mentorName,
    required this.schoolName,
    required this.schoolAddress,
    required this.internshipStart,
    required this.internshipEnd,
    required this.active,
  });

  final int userId;
  final String fullName;
  final String email;
  final int unitId;
  final String unitName;
  final int? mentorUserId;
  final String? mentorName;
  final String? schoolName;
  final String? schoolAddress;
  final String internshipStart;
  final String internshipEnd;
  final bool active;

  factory AdminInternRowDto.fromJson(Map<String, dynamic> json) {
    return AdminInternRowDto(
      userId: (json['user_id'] as num).toInt(),
      fullName: (json['full_name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      unitId: (json['unit_id'] as num).toInt(),
      unitName: (json['unit_name'] ?? '').toString(),
      mentorUserId: json['mentor_user_id'] == null ? null : (json['mentor_user_id'] as num).toInt(),
      mentorName: json['mentor_name']?.toString(),
      schoolName: json['school_name']?.toString(),
      schoolAddress: json['school_address']?.toString(),
      internshipStart: (json['internship_start'] ?? '').toString(),
      internshipEnd: (json['internship_end'] ?? '').toString(),
      active: (json['active'] as num?)?.toInt() == 1,
    );
  }
}

class AdminInternsViewModel extends ChangeNotifier {
  AdminInternsViewModel({required this.apiClient, required this.session});

  final ApiClient apiClient;
  final SessionStore session;

  bool loading = false;
  String? error;

  List<AdminInternRowDto> interns = const [];
  List<UnitDto> units = const [];
  List<MentorMiniDto> mentors = const [];

  Future<void> loadAll() async {
    if (!session.isAuthenticated) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final data = await apiClient.getJson('/api/admin/interns', bearerToken: session.token);
      if (data is! List) throw ApiError(code: 'BAD_RESPONSE', message: 'Format interns tidak valid.');
      interns = data.whereType<Map>().map((e) => AdminInternRowDto.fromJson(Map<String, dynamic>.from(e))).toList(growable: false);

      final unitsData = await apiClient.getJson('/api/units', bearerToken: session.token);
      if (unitsData is List) {
        units = unitsData.whereType<Map>().map((e) => UnitDto.fromJson(Map<String, dynamic>.from(e))).toList(growable: false);
      }
      final mentorsData = await apiClient.getJson('/api/admin/mentors', bearerToken: session.token);
      if (mentorsData is List) {
        mentors = mentorsData.whereType<Map>().map((e) => MentorMiniDto.fromJson(Map<String, dynamic>.from(e))).toList(growable: false);
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

  Future<String?> create({
    required String email,
    required String fullName,
    required int unitId,
    required int? mentorUserId,
    required String internshipStart,
    required String internshipEnd,
    required String schoolName,
    required String schoolAddress,
    required String password,
  }) async {
    if (!session.isAuthenticated) return null;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final data = await apiClient.postJson(
        '/api/admin/interns',
        bearerToken: session.token,
        body: {
          'email': email,
          'fullName': fullName,
          'unitId': unitId,
          'mentorUserId': mentorUserId,
          'internshipStart': internshipStart,
          'internshipEnd': internshipEnd,
          'schoolName': schoolName,
          'schoolAddress': schoolAddress,
          'password': password.trim().isEmpty ? null : password.trim(),
        },
      );
      await loadAll();
      if (data is Map) return (data['tempPassword'] ?? '').toString();
      return null;
    } on ApiError catch (e) {
      error = e.message;
      return null;
    } catch (e) {
      error = e.toString();
      return null;
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
      await apiClient.postJson(
        '/api/admin/interns/$userId/${activate ? 'activate' : 'deactivate'}',
        bearerToken: session.token,
      );
      await loadAll();
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
        '/api/admin/interns/$userId',
        bearerToken: session.token,
        body: {'confirm': 'HAPUS', 'force': force},
      );
      await loadAll();
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
