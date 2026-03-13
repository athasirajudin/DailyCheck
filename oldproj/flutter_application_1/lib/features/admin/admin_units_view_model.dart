import 'package:flutter/foundation.dart';

import '../../core/models/unit_models.dart';
import '../../core/services/api_client_base.dart';
import '../../core/services/session_store.dart';

class AdminUnitsViewModel extends ChangeNotifier {
  AdminUnitsViewModel({required this.apiClient, required this.session});

  final ApiClient apiClient;
  final SessionStore session;

  bool loading = false;
  String? error;
  List<UnitDto> units = const [];

  Future<void> load() async {
    if (!session.isAuthenticated) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final data = await apiClient.getJson('/api/units', bearerToken: session.token);
      if (data is! List) throw ApiError(code: 'BAD_RESPONSE', message: 'Format unit tidak valid.');
      units = data.whereType<Map>().map((e) => UnitDto.fromJson(Map<String, dynamic>.from(e))).toList(growable: false);
    } on ApiError catch (e) {
      error = e.message;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> updateUnit(UnitDto unit) async {
    if (!session.isAuthenticated) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      await apiClient.postJson(
        '/api/admin/units/${unit.id}',
        bearerToken: session.token,
        body: {
          'name': unit.name,
          'geofenceLat': unit.geofenceLat,
          'geofenceLon': unit.geofenceLon,
          'geofenceRadiusM': unit.geofenceRadiusM,
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
}

