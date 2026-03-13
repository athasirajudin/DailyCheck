import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/services/api_client_base.dart';
import '../../core/services/session_store.dart';

class InternTodayState {
  InternTodayState({
    required this.date,
    required this.unitName,
    required this.status,
    required this.checkInAt,
    required this.checkOutAt,
    required this.checkoutMissing,
    required this.geofenceLat,
    required this.geofenceLon,
    required this.geofenceRadiusM,
    required this.checkinWindow,
    required this.checkoutWindow,
    required this.timezone,
    required this.isWorkday,
    this.currentLat,
    this.currentLon,
    this.distanceM,
  });

  final String date;
  final String unitName;
  final String? status;
  final String? checkInAt;
  final String? checkOutAt;
  final bool? checkoutMissing;
  final double geofenceLat;
  final double geofenceLon;
  final double geofenceRadiusM;
  final InternAvailability checkinWindow;
  final InternAvailability checkoutWindow;
  final String timezone;
  final bool isWorkday;
  final double? currentLat;
  final double? currentLon;
  final double? distanceM;
}

class InternAvailability {
  InternAvailability({
    required this.open,
    required this.opensAt,
    required this.closesAt,
  });

  final bool open;
  final String opensAt;
  final String closesAt;

  factory InternAvailability.fromJson(Map<String, dynamic> json) {
    return InternAvailability(
      open: json['open'] == true,
      opensAt: (json['opensAt'] ?? '').toString(),
      closesAt: (json['closesAt'] ?? '').toString(),
    );
  }
}

class InternTodayViewModel extends ChangeNotifier {
  InternTodayViewModel({required this.apiClient, required this.session});

  final ApiClient apiClient;
  final SessionStore session;

  bool loading = false;
  String? error;
  InternTodayState? state;
  double? currentLat;
  double? currentLon;
  double? distanceM;

  Timer? _timer;

  void start() {
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
  }

  Future<void> _refresh() async {
    if (!session.isAuthenticated) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final data = await apiClient.getJson(
        '/api/intern/today',
        bearerToken: session.token,
      );
      if (data is! Map) {
        throw ApiError(
          code: 'BAD_RESPONSE',
          message: 'Format data hari ini tidak valid.',
        );
      }
      final map = Map<String, dynamic>.from(data);
      final unit = map['unit'] as Map?;
      final attendance = map['attendance'];
      final availability = map['availability'] as Map?;
      state = InternTodayState(
        date: (map['date'] ?? '').toString(),
        unitName: (unit?['name'] ?? '').toString(),
        status: attendance is Map ? (attendance['status']?.toString()) : null,
        checkInAt: attendance is Map
            ? (attendance['checkInAt']?.toString())
            : null,
        checkOutAt: attendance is Map
            ? (attendance['checkOutAt']?.toString())
            : null,
        checkoutMissing: attendance is Map
            ? (attendance['checkoutMissing'] == true)
            : null,
        geofenceLat: (unit?['geofence']?['lat'] as num?)?.toDouble() ?? 0,
        geofenceLon: (unit?['geofence']?['lon'] as num?)?.toDouble() ?? 0,
        geofenceRadiusM:
            (unit?['geofence']?['radiusM'] as num?)?.toDouble() ?? 0,
        checkinWindow: InternAvailability.fromJson(
          Map<String, dynamic>.from((availability?['checkin'] as Map?) ?? {}),
        ),
        checkoutWindow: InternAvailability.fromJson(
          Map<String, dynamic>.from((availability?['checkout'] as Map?) ?? {}),
        ),
        timezone: (map['timezone'] ?? '').toString(),
        isWorkday: map['isWorkday'] == true,
        currentLat: currentLat,
        currentLon: currentLon,
        distanceM: distanceM,
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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
