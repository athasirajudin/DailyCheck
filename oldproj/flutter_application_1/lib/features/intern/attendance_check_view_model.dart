import 'package:flutter/foundation.dart';

import '../../core/models/attendance_models.dart';
import '../../core/services/api_client_base.dart';
import '../../core/services/location_service.dart';
import '../../core/services/session_store.dart';

enum AttendanceAction { checkin, checkout }

class AttendanceCheckResult {
  AttendanceCheckResult({required this.attendance, required this.status});

  final AttendanceDto attendance;
  final String status;
}

class AttendanceCheckViewModel extends ChangeNotifier {
  AttendanceCheckViewModel({
    required this.apiClient,
    required this.session,
    required this.location,
  });

  final ApiClient apiClient;
  final SessionStore session;
  final LocationService location;

  bool loading = false;
  String? error;
  AttendanceCheckResult? lastResult;

  Future<void> submit({
    required AttendanceAction action,
    required String qrToken,
  }) async {
    if (!session.isAuthenticated) {
      error = 'Belum login.';
      notifyListeners();
      return;
    }
    if (qrToken.trim().isEmpty) {
      error = 'QR token kosong.';
      notifyListeners();
      return;
    }

    loading = true;
    error = null;
    lastResult = null;
    notifyListeners();

    try {
      final point = await location.getCurrentLocation();
      final data = await apiClient.postJson(
        '/api/attendance/check',
        bearerToken: session.token,
        body: {
          'action': action == AttendanceAction.checkin ? 'checkin' : 'checkout',
          'qrToken': qrToken.trim(),
          'lat': point.lat,
          'lon': point.lon,
        },
      );
      if (data is! Map) {
        throw ApiError(code: 'BAD_RESPONSE', message: 'Format response absensi tidak valid.');
      }
      final map = Map<String, dynamic>.from(data);
      final attendanceJson = map['attendance'];
      if (attendanceJson is! Map) {
        throw ApiError(code: 'BAD_RESPONSE', message: 'Attendance tidak ada.');
      }
      final att = AttendanceDto.fromJson(Map<String, dynamic>.from(attendanceJson));
      lastResult = AttendanceCheckResult(attendance: att, status: (map['result']?['status'] ?? att.status).toString());
    } on ApiError catch (e) {
      if (e.code == 'OUT_OF_AREA' && e.extra is Map) {
        final extra = Map<String, dynamic>.from(e.extra as Map);
        final distance = (extra['distanceM'] as num?)?.toDouble();
        final radius = (extra['radiusM'] as num?)?.toDouble();
        if (distance != null && radius != null) {
          final distanceText = distance.toStringAsFixed(1);
          final radiusText = radius.toStringAsFixed(0);
          error =
              'Di luar area geofence. Jarak kamu $distanceText m dari titik unit (batas $radiusText m).';
        } else {
          error = e.message;
        }
      } else {
        error = e.message;
      }
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
