import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/services/api_client_base.dart';
import '../../core/services/session_store.dart';

class DeviceDto {
  DeviceDto({
    required this.id,
    required this.unitId,
    required this.unitName,
    required this.name,
    required this.lastSeenAt,
    required this.online,
  });

  final int id;
  final int unitId;
  final String unitName;
  final String name;
  final String? lastSeenAt;
  final bool online;

  factory DeviceDto.fromJson(Map<String, dynamic> json) {
    return DeviceDto(
      id: (json['id'] as num).toInt(),
      unitId: (json['unitId'] as num).toInt(),
      unitName: (json['unitName'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      lastSeenAt: json['lastSeenAt']?.toString(),
      online: json['online'] == true,
    );
  }
}

class AdminDevicesViewModel extends ChangeNotifier {
  AdminDevicesViewModel({required this.apiClient, required this.session});

  final ApiClient apiClient;
  final SessionStore session;

  bool loading = false;
  String? error;
  List<DeviceDto> devices = const [];
  Timer? _timer;

  void start() {
    refresh();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => refresh(silent: true));
  }

  Future<void> refresh({bool silent = false}) async {
    if (!session.isAuthenticated) return;
    if (!silent) {
      loading = true;
      notifyListeners();
    }
    error = null;
    try {
      final data = await apiClient.getJson('/api/admin/devices', bearerToken: session.token);
      if (data is! List) throw ApiError(code: 'BAD_RESPONSE', message: 'Format devices tidak valid.');
      devices = data.whereType<Map>().map((e) => DeviceDto.fromJson(Map<String, dynamic>.from(e))).toList(growable: false);
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

