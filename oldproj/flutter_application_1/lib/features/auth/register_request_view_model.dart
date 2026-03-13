import 'package:flutter/foundation.dart';

import '../../core/models/public_school_models.dart';
import '../../core/models/public_unit_models.dart';
import '../../core/services/api_client_base.dart';

class RegisterRequestViewModel extends ChangeNotifier {
  RegisterRequestViewModel({required this.apiClient});

  final ApiClient apiClient;

  bool loading = false;
  bool schoolLoading = false;
  String? error;
  String? schoolError;
  bool submitted = false;
  int? requestId;

  List<PublicUnitDto> units = const [];
  List<PublicSchoolDto> schools = const [];

  Future<void> loadUnits() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final data = await apiClient.getJson('/api/public/units');
      if (data is! List) throw ApiError(code: 'BAD_RESPONSE', message: 'Format unit tidak valid.');
      units = data.whereType<Map>().map((e) => PublicUnitDto.fromJson(Map<String, dynamic>.from(e))).toList(growable: false);
    } on ApiError catch (e) {
      error = e.message;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> searchSchools({String query = '', int limit = 40}) async {
    schoolLoading = true;
    schoolError = null;
    notifyListeners();
    try {
      final data = await apiClient.getJson(
        '/api/public/schools',
        query: {
          'q': query,
          'level': 'SMK',
          'limit': limit.toString(),
        },
      );
      if (data is! List) {
        throw ApiError(code: 'BAD_RESPONSE', message: 'Format sekolah tidak valid.');
      }
      schools = data
          .whereType<Map>()
          .map((e) => PublicSchoolDto.fromJson(Map<String, dynamic>.from(e)))
          .where((item) => item.name.trim().isNotEmpty)
          .toList(growable: false);
    } on ApiError catch (e) {
      schoolError = e.message;
    } catch (e) {
      schoolError = e.toString();
    } finally {
      schoolLoading = false;
      notifyListeners();
    }
  }

  Future<void> submit({
    required String email,
    required String fullName,
    required int unitId,
    required String internshipStart,
    required String internshipEnd,
    required String schoolName,
    required String schoolAddress,
    required String notes,
    String? schoolId,
  }) async {
    loading = true;
    error = null;
    submitted = false;
    requestId = null;
    notifyListeners();
    try {
      final data = await apiClient.postJson(
        '/api/register/request',
        body: {
          'email': email,
          'fullName': fullName,
          'unitId': unitId,
          'internshipStart': internshipStart,
          'internshipEnd': internshipEnd,
          'schoolName': schoolName,
          'schoolAddress': schoolAddress,
          'schoolId': schoolId,
          'notes': notes,
        },
      );
      if (data is! Map) throw ApiError(code: 'BAD_RESPONSE', message: 'Format response tidak valid.');
      requestId = (data['requestId'] as num?)?.toInt();
      submitted = true;
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
