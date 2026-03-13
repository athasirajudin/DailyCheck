import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/models/attendance_models.dart';
import '../../core/services/api_client_base.dart';
import '../../core/services/session_store.dart';

class AdminDailyTrendPoint {
  const AdminDailyTrendPoint({
    required this.date,
    required this.label,
    required this.total,
    required this.hadir,
  });

  final String date;
  final String label;
  final int total;
  final int hadir;

  double get hadirPercent {
    if (total <= 0) return 0;
    return (hadir / total) * 100;
  }
}

class AdminDashboardViewModel extends ChangeNotifier {
  AdminDashboardViewModel({required this.apiClient, required this.session});

  final ApiClient apiClient;
  final SessionStore session;

  bool loading = false;
  bool refreshing = false;
  String? error;
  DateTime? lastUpdated;
  DateTime currentTime = DateTime.now();

  int totalInterns = 0;
  int activeInterns = 0;
  int totalUsers = 0;
  int activeUsers = 0;
  int nonActiveUsers = 0;
  int totalMentors = 0;
  int totalUnits = 0;
  int totalSchools = 0;

  RecapSummary todaySummary = RecapSummary(
    hadir: 0,
    terlambat: 0,
    izin: 0,
    sakit: 0,
    alpa: 0,
    checkoutMissing: 0,
  );

  RecapSummary weekSummary = RecapSummary(
    hadir: 0,
    terlambat: 0,
    izin: 0,
    sakit: 0,
    alpa: 0,
    checkoutMissing: 0,
  );

  List<AdminDailyTrendPoint> weeklyTrend = const [];

  Timer? _timer;
  Timer? _clockTimer;

  void start() {
    refresh();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      currentTime = DateTime.now();
      notifyListeners();
    });
    _timer = Timer.periodic(
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
      final now = DateTime.now();
      final today = _formatDate(now);
      final weekStart = _formatDate(now.subtract(const Duration(days: 6)));

      final responses = await Future.wait<Object?>([
        apiClient.getJson('/api/admin/interns', bearerToken: session.token),
        apiClient.getJson('/api/admin/mentors', bearerToken: session.token),
        apiClient.getJson('/api/admin/user-stats', bearerToken: session.token),
        apiClient.getJson('/api/units', bearerToken: session.token),
        apiClient.getJson(
          '/api/admin/recap',
          bearerToken: session.token,
          query: {'dateFrom': today, 'dateTo': today},
        ),
        apiClient.getJson(
          '/api/admin/recap',
          bearerToken: session.token,
          query: {'dateFrom': weekStart, 'dateTo': today},
        ),
      ]);

      final internsRaw = responses[0];
      final mentorsRaw = responses[1];
      final userStatsRaw = responses[2];
      final unitsRaw = responses[3];
      final todayRecapRaw = responses[4];
      final weekRecapRaw = responses[5];

      final internList = internsRaw is List
          ? internsRaw.whereType<Map>().map(Map<String, dynamic>.from).toList()
          : const <Map<String, dynamic>>[];
      final mentorList = mentorsRaw is List
          ? mentorsRaw.whereType<Map>().toList()
          : const <Map<dynamic, dynamic>>[];
      final unitList = unitsRaw is List
          ? unitsRaw.whereType<Map>().toList()
          : const <Map<dynamic, dynamic>>[];

      totalInterns = internList.length;
      activeInterns = internList
          .where((it) => ((it['active'] as num?)?.toInt() ?? 0) == 1)
          .length;
      totalUsers = _toInt(_mapGet(userStatsRaw, 'totalUsers'));
      activeUsers = _toInt(_mapGet(userStatsRaw, 'activeUsers'));
      nonActiveUsers = _toInt(_mapGet(userStatsRaw, 'nonActiveUsers'));
      if (totalUsers <= 0) {
        totalUsers = totalInterns + mentorList.length;
      }
      if (activeUsers <= 0 && totalUsers > 0) {
        activeUsers = (activeInterns + mentorList.length)
            .clamp(0, totalUsers)
            .toInt();
      }
      if (nonActiveUsers <= 0 && totalUsers > 0) {
        nonActiveUsers = (totalUsers - activeUsers)
            .clamp(0, totalUsers)
            .toInt();
      }
      totalSchools = internList
          .map((it) => (it['school_name'] ?? '').toString().trim())
          .where((name) => name.isNotEmpty)
          .toSet()
          .length;
      totalMentors = mentorList.length;
      totalUnits = unitList.length;

      todaySummary = _parseSummary(todayRecapRaw);
      weekSummary = _parseSummary(weekRecapRaw);
      weeklyTrend = _buildWeeklyTrend(weekRecapRaw, now);

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

  List<AdminDailyTrendPoint> _buildWeeklyTrend(Object? payload, DateTime now) {
    final out = <AdminDailyTrendPoint>[];
    final baseDays = List<DateTime>.generate(
      7,
      (i) => DateTime(now.year, now.month, now.day - (6 - i)),
    );
    final byDate = <String, _DailyBucket>{
      for (final day in baseDays) _formatDate(day): _DailyBucket(),
    };

    if (payload is Map) {
      final map = Map<String, dynamic>.from(payload);
      final items = map['items'];
      if (items is List) {
        for (final raw in items.whereType<Map>()) {
          final item = Map<String, dynamic>.from(raw);
          final date = (item['date'] ?? '').toString();
          final status = (item['status'] ?? '').toString().toUpperCase();
          final bucket = byDate[date];
          if (bucket == null) continue;
          bucket.total += 1;
          if (status == 'HADIR') {
            bucket.hadir += 1;
          }
        }
      }
    }

    for (final day in baseDays) {
      final key = _formatDate(day);
      final bucket = byDate[key] ?? _DailyBucket();
      out.add(
        AdminDailyTrendPoint(
          date: key,
          label: _dayLabel(day.weekday),
          total: bucket.total,
          hadir: bucket.hadir,
        ),
      );
    }
    return out;
  }

  static String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  int _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  Object? _mapGet(Object? mapRaw, String key) {
    if (mapRaw is! Map) return null;
    return mapRaw[key];
  }

  String _dayLabel(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Sen';
      case DateTime.tuesday:
        return 'Sel';
      case DateTime.wednesday:
        return 'Rab';
      case DateTime.thursday:
        return 'Kam';
      case DateTime.friday:
        return 'Jum';
      case DateTime.saturday:
        return 'Sab';
      case DateTime.sunday:
        return 'Min';
      default:
        return '-';
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _clockTimer?.cancel();
    super.dispose();
  }
}

class _DailyBucket {
  int total = 0;
  int hadir = 0;
}
