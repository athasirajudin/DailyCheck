import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/services/api_client_base.dart';
import '../../core/services/session_store.dart';

class AdminSettingsState {
  AdminSettingsState({
    required this.timezone,
    required this.workStartTime,
    required this.workEndTime,
    required this.toleranceMinutes,
    required this.dayCutoffTime,
    required this.workdays,
    required this.offlineThresholdSeconds,
  });

  final String timezone;
  final String workStartTime;
  final String workEndTime;
  final int toleranceMinutes;
  final String dayCutoffTime;
  final List<int> workdays;
  final int offlineThresholdSeconds;

  factory AdminSettingsState.fromJson(Map<String, dynamic> json) {
    final workdaysRaw = json['workdays_json']?.toString();
    List<int> workdays = [1, 2, 3, 4, 5];
    if (workdaysRaw != null && workdaysRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(workdaysRaw);
        if (decoded is List) {
          workdays = decoded.whereType<num>().map((e) => e.toInt()).toList();
        }
      } catch (_) {}
    }
    return AdminSettingsState(
      timezone: (json['timezone'] ?? 'Asia/Jakarta').toString(),
      workStartTime: (json['work_start_time'] ?? '09:00:00').toString(),
      workEndTime: (json['work_end_time'] ?? '17:00:00').toString(),
      toleranceMinutes: (json['tolerance_minutes'] as num?)?.toInt() ?? 15,
      dayCutoffTime: (json['day_cutoff_time'] ?? '23:59:59').toString(),
      workdays: workdays,
      offlineThresholdSeconds: (json['offline_threshold_seconds'] as num?)?.toInt() ?? 120,
    );
  }
}

class AdminSettingsViewModel extends ChangeNotifier {
  AdminSettingsViewModel({required this.apiClient, required this.session});

  final ApiClient apiClient;
  final SessionStore session;

  bool loading = false;
  String? error;
  AdminSettingsState? state;

  Future<void> load() async {
    if (!session.isAuthenticated) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final data = await apiClient.getJson('/api/settings', bearerToken: session.token);
      if (data is! Map) throw ApiError(code: 'BAD_RESPONSE', message: 'Format settings tidak valid.');
      state = AdminSettingsState.fromJson(Map<String, dynamic>.from(data));
    } on ApiError catch (e) {
      error = e.message;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> save(AdminSettingsState s) async {
    if (!session.isAuthenticated) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      await apiClient.postJson(
        '/api/settings',
        bearerToken: session.token,
        body: {
          'timezone': s.timezone,
          'work_start_time': s.workStartTime,
          'work_end_time': s.workEndTime,
          'tolerance_minutes': s.toleranceMinutes,
          'day_cutoff_time': s.dayCutoffTime,
          'workdays': s.workdays,
          'offline_threshold_seconds': s.offlineThresholdSeconds,
        },
      );
      state = s;
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
