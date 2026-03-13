import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/models/attendance_models.dart';
import '../../core/services/api_client_base.dart';
import '../../core/services/session_store.dart';

class MentorDashboardViewModel extends ChangeNotifier {
  MentorDashboardViewModel({required this.apiClient, required this.session});

  final ApiClient apiClient;
  final SessionStore session;

  bool loading = false;
  bool refreshing = false;
  String? error;

  DateTime currentTime = DateTime.now();
  DateTime? lastUpdated;

  int totalInterns = 0;
  int activeInterns = 0;
  int totalUnits = 0;
  int pendingLeave = 0;

  RecapSummary todaySummary = RecapSummary(
    hadir: 0,
    terlambat: 0,
    izin: 0,
    sakit: 0,
    alpa: 0,
    checkoutMissing: 0,
  );

  Timer? _refreshTimer;
  Timer? _clockTimer;

  void start() {
    refresh();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      currentTime = DateTime.now();
      notifyListeners();
    });
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => refresh(silent: true),
    );
  }

  Future<void> refresh({bool silent = false}) async {
    if (!session.isAuthenticated) return;

    if (silent) {
      refreshing = true;
    } else {
      loading = true;
    }
    error = null;
    notifyListeners();

    try {
      final today = _formatDate(DateTime.now());
      final responses = await Future.wait<Object?>([
        apiClient.getJson('/api/mentor/interns', bearerToken: session.token),
        apiClient.getJson('/api/mentor/units', bearerToken: session.token),
        apiClient.getJson('/api/mentor/leave', bearerToken: session.token),
        apiClient.getJson(
          '/api/mentor/recap',
          bearerToken: session.token,
          query: {'dateFrom': today, 'dateTo': today},
        ),
      ]);

      final internsRaw = responses[0];
      final unitsRaw = responses[1];
      final leavesRaw = responses[2];
      final recapRaw = responses[3];

      final internList = internsRaw is List
          ? internsRaw.whereType<Map>().map(Map<String, dynamic>.from).toList()
          : const <Map<String, dynamic>>[];
      final unitList = unitsRaw is List
          ? unitsRaw.whereType<Map>().toList()
          : const [];
      final leaveList = leavesRaw is List
          ? leavesRaw.whereType<Map>().map(Map<String, dynamic>.from).toList()
          : const <Map<String, dynamic>>[];

      totalInterns = internList.length;
      activeInterns = internList.where((e) => e['active'] == true).length;
      totalUnits = unitList.length;
      pendingLeave = leaveList
          .where(
            (e) => (e['status'] ?? '').toString().toUpperCase() == 'PENDING',
          )
          .length;
      todaySummary = _parseSummary(recapRaw);
      lastUpdated = DateTime.now();
    } on ApiError catch (e) {
      error = e.message;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      refreshing = false;
      notifyListeners();
    }
  }

  RecapSummary _parseSummary(Object? payload) {
    if (payload is! Map) {
      return RecapSummary(
        hadir: 0,
        terlambat: 0,
        izin: 0,
        sakit: 0,
        alpa: 0,
        checkoutMissing: 0,
      );
    }
    final map = Map<String, dynamic>.from(payload);
    final summaryRaw = map['summary'];
    if (summaryRaw is! Map) {
      return RecapSummary(
        hadir: 0,
        terlambat: 0,
        izin: 0,
        sakit: 0,
        alpa: 0,
        checkoutMissing: 0,
      );
    }
    return RecapSummary.fromJson(Map<String, dynamic>.from(summaryRaw));
  }

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _clockTimer?.cancel();
    super.dispose();
  }
}
