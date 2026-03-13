import 'package:flutter/foundation.dart';

import '../../core/models/unit_models.dart';
import '../../core/services/api_client_base.dart';
import '../../core/services/session_store.dart';

class PairingResult {
  PairingResult({required this.pairingCode, required this.expiresAt});

  final String pairingCode;
  final String expiresAt;
}

class AdminPairingViewModel extends ChangeNotifier {
  AdminPairingViewModel({required this.apiClient, required this.session});

  final ApiClient apiClient;
  final SessionStore session;

  bool loading = false;
  String? error;
  List<UnitDto> units = const [];
  PairingResult? last;

  Future<void> loadUnits() async {
    if (!session.isAuthenticated) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final data = await apiClient.getJson('/api/units', bearerToken: session.token);
      if (data is! List) throw ApiError(code: 'BAD_RESPONSE', message: 'Format units tidak valid.');
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

  Future<void> createPairing({required int unitId, required String deviceName}) async {
    if (!session.isAuthenticated) return;
    loading = true;
    error = null;
    last = null;
    notifyListeners();
    try {
      final data = await apiClient.postJson(
        '/api/admin/pairing/create',
        bearerToken: session.token,
        body: {'unitId': unitId, 'deviceName': deviceName},
      );
      if (data is! Map) throw ApiError(code: 'BAD_RESPONSE', message: 'Format pairing tidak valid.');
      final map = Map<String, dynamic>.from(data);
      last = PairingResult(
        pairingCode: (map['pairingCode'] ?? '').toString(),
        expiresAt: (map['expiresAt'] ?? '').toString(),
      );
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

