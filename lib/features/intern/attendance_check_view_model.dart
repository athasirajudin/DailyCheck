import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../core/models/attendance_models.dart';
import '../../core/services/api_client_base.dart';
import '../../core/services/location_service.dart';
import '../../core/services/session_store.dart';

enum AttendanceAction { checkin, checkout }

enum LocationUiIssue {
  none,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  unknown,
}

class AttendanceCheckResult {
  AttendanceCheckResult({required this.attendance, required this.status});

  final AttendanceDto attendance;
  final String status;
}

class GeofenceArea {
  GeofenceArea({required this.lat, required this.lon, required this.radiusM});

  final double lat;
  final double lon;
  final double radiusM;
}

class AvailabilityWindow {
  AvailabilityWindow({
    required this.open,
    required this.opensAt,
    required this.closesAt,
  });

  final bool open;
  final String opensAt;
  final String closesAt;

  factory AvailabilityWindow.fromJson(Map<String, dynamic> json) {
    return AvailabilityWindow(
      open: json['open'] == true,
      opensAt: (json['opensAt'] ?? '').toString(),
      closesAt: (json['closesAt'] ?? '').toString(),
    );
  }
}

class AttendanceCheckMeta {
  AttendanceCheckMeta({
    required this.date,
    required this.unitName,
    required this.geofence,
    required this.checkinWindow,
    required this.checkoutWindow,
    required this.attendance,
    required this.serverTime,
    required this.timezone,
    required this.isWorkday,
  });

  final String date;
  final String unitName;
  final GeofenceArea geofence;
  final AvailabilityWindow checkinWindow;
  final AvailabilityWindow checkoutWindow;
  final AttendanceDto? attendance;
  final String serverTime;
  final String timezone;
  final bool isWorkday;

  AttendanceCheckMeta copyWith({AttendanceDto? attendance}) {
    return AttendanceCheckMeta(
      date: date,
      unitName: unitName,
      geofence: geofence,
      checkinWindow: checkinWindow,
      checkoutWindow: checkoutWindow,
      attendance: attendance ?? this.attendance,
      serverTime: serverTime,
      timezone: timezone,
      isWorkday: isWorkday,
    );
  }

  factory AttendanceCheckMeta.fromJson(Map<String, dynamic> json) {
    final unit = json['unit'] as Map?;
    final availability = json['availability'] as Map?;
    final attendance = json['attendance'];
    return AttendanceCheckMeta(
      date: (json['date'] ?? '').toString(),
      unitName: (unit?['name'] ?? '').toString(),
      geofence: GeofenceArea(
        lat: (unit?['geofence']?['lat'] as num?)?.toDouble() ?? 0.0,
        lon: (unit?['geofence']?['lon'] as num?)?.toDouble() ?? 0.0,
        radiusM: (unit?['geofence']?['radiusM'] as num?)?.toDouble() ?? 0.0,
      ),
      checkinWindow: AvailabilityWindow.fromJson(
        Map<String, dynamic>.from((availability?['checkin'] as Map?) ?? {}),
      ),
      checkoutWindow: AvailabilityWindow.fromJson(
        Map<String, dynamic>.from((availability?['checkout'] as Map?) ?? {}),
      ),
      attendance: attendance is Map
          ? AttendanceDto.fromJson(Map<String, dynamic>.from(attendance))
          : null,
      serverTime: (json['serverTime'] ?? '').toString(),
      timezone: (json['timezone'] ?? '').toString(),
      isWorkday: json['isWorkday'] == true,
    );
  }
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

  AttendanceCheckMeta? meta;
  LocationPoint? currentLocation;
  double? distanceM;
  bool insideRadius = false;
  bool refreshing = false;
  Timer? _locTimer;
  bool loading = false;
  String? error;
  String? locationError;
  LocationUiIssue locationIssue = LocationUiIssue.none;
  AttendanceCheckResult? lastResult;

  Future<void> refresh({bool withLocation = true}) async {
    if (!session.isAuthenticated) {
      error = 'Belum login.';
      notifyListeners();
      return;
    }
    _locTimer?.cancel();
    refreshing = true;
    error = null;
    locationError = null;
    locationIssue = LocationUiIssue.none;
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
      meta = AttendanceCheckMeta.fromJson(Map<String, dynamic>.from(data));
      if (withLocation) {
        await _updateLocation();
      }
      // auto-refresh lokasi setiap 5 detik agar tombol otomatis aktif ketika sudah dalam radius
      _locTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
        await _updateLocation();
        notifyListeners();
      });
    } on ApiError catch (e) {
      error = e.message;
    } catch (e) {
      error = e.toString();
    } finally {
      refreshing = false;
      notifyListeners();
    }
  }

  Future<void> _updateLocation() async {
    try {
      final point = await location.getCurrentLocation();
      currentLocation = point;
      locationError = null;
      locationIssue = LocationUiIssue.none;
      final m = meta;
      if (m != null) {
        distanceM = _haversine(
          point.lat,
          point.lon,
          m.geofence.lat,
          m.geofence.lon,
        );
        insideRadius = distanceM != null && distanceM! <= m.geofence.radiusM;
      }
    } catch (e) {
      insideRadius = false;
      distanceM = null;
      currentLocation = null;
      locationError = _mapLocationError(e);
      locationIssue = _mapLocationIssue(e);
    }
  }

  Future<void> refreshLocationOnly() async {
    await _updateLocation();
    notifyListeners();
  }

  @override
  void dispose() {
    _locTimer?.cancel();
    super.dispose();
  }

  bool get canCheckIn {
    final m = meta;
    if (loading || m == null) return false;
    if (!m.isWorkday) return false;
    if (m.attendance?.checkInAt != null) return false;
    if (locationError != null) return false;
    if (!insideRadius) return false;
    return true;
  }

  bool get canCheckOut {
    final m = meta;
    if (loading || m == null) return false;
    if (!m.isWorkday) return false;
    final att = m.attendance;
    if (att == null || att.checkInAt == null) return false;
    if (att.checkOutAt != null) return false;
    if (!m.checkoutWindow.open) return false;
    if (locationError != null) return false;
    if (!insideRadius) return false;
    return true;
  }

  String? get checkinBlockedReason {
    final m = meta;
    if (m == null) return 'Data absensi belum dimuat.';
    if (!m.isWorkday) return 'Hari ini bukan hari kerja / hari libur.';
    if (m.attendance?.checkInAt != null) return 'Kamu sudah check-in hari ini.';
    if (locationError != null) return locationError;
    if (!insideRadius) {
      final distText = distanceM == null
          ? 'belum terdeteksi'
          : '${distanceM!.toStringAsFixed(1)} m';
      return 'Di luar radius geofence (jarak $distText, batas ${m.geofence.radiusM.toStringAsFixed(0)} m).';
    }
    return null;
  }

  String? get checkoutBlockedReason {
    final m = meta;
    if (m == null) return 'Data absensi belum dimuat.';
    if (!m.isWorkday) return 'Hari ini bukan hari kerja / hari libur.';
    final att = m.attendance;
    if (att == null || att.checkInAt == null) return 'Belum check-in hari ini.';
    if (att.checkOutAt != null) return 'Kamu sudah check-out hari ini.';
    if (!m.checkoutWindow.open) {
      return 'Belum/diluar jam check-out (buka ${_hhmm(m.checkoutWindow.opensAt)} - ${_hhmm(m.checkoutWindow.closesAt)}).';
    }
    if (locationError != null) return locationError;
    if (!insideRadius) {
      final distText = distanceM == null
          ? 'belum terdeteksi'
          : '${distanceM!.toStringAsFixed(1)} m';
      return 'Di luar radius geofence (jarak $distText, batas ${m.geofence.radiusM.toStringAsFixed(0)} m).';
    }
    return null;
  }

  Future<void> submit({required AttendanceAction action}) async {
    if (!session.isAuthenticated) {
      error = 'Belum login.';
      notifyListeners();
      return;
    }

    loading = true;
    error = null;
    lastResult = null;
    notifyListeners();

    try {
      final point = await location.getCurrentLocation();
      currentLocation = point;
      locationError = null;
      locationIssue = LocationUiIssue.none;
      final m = meta;
      if (m != null) {
        distanceM = _haversine(
          point.lat,
          point.lon,
          m.geofence.lat,
          m.geofence.lon,
        );
        insideRadius = distanceM != null && distanceM! <= m.geofence.radiusM;
      }
      final data = await apiClient.postJson(
        '/api/attendance/check',
        bearerToken: session.token,
        body: {
          'action': action == AttendanceAction.checkin ? 'checkin' : 'checkout',
          'lat': point.lat,
          'lon': point.lon,
        },
      );
      if (data is! Map) {
        throw ApiError(
          code: 'BAD_RESPONSE',
          message: 'Format response absensi tidak valid.',
        );
      }
      final map = Map<String, dynamic>.from(data);
      final attendanceJson = map['attendance'];
      if (attendanceJson is! Map) {
        throw ApiError(code: 'BAD_RESPONSE', message: 'Attendance tidak ada.');
      }
      final att = AttendanceDto.fromJson(
        Map<String, dynamic>.from(attendanceJson),
      );
      lastResult = AttendanceCheckResult(
        attendance: att,
        status: (map['result']?['status'] ?? att.status).toString(),
      );
      if (meta != null) {
        meta = meta!.copyWith(attendance: att);
      }
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
      } else if ((e.code == 'CHECKIN_CLOSED' || e.code == 'CHECKOUT_CLOSED') &&
          e.extra is Map) {
        final extra = Map<String, dynamic>.from(e.extra as Map);
        final opens = extra['opensAt']?.toString();
        final closes = extra['closesAt']?.toString();
        if (opens != null && closes != null) {
          error = '${e.message} (buka ${_hhmm(opens)} - ${_hhmm(closes)}).';
        } else {
          error = e.message;
        }
      } else {
        error = e.message;
      }
    } on LocationException catch (e) {
      error = _mapLocationError(e);
      locationIssue = _mapLocationIssue(e);
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) *
            math.cos(_deg2rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  double _deg2rad(double deg) => deg * (math.pi / 180.0);

  String _hhmm(String ts) {
    if (ts.contains(' ')) {
      final parts = ts.split(' ');
      if (parts.length >= 2 && parts[1].length >= 5) {
        return parts[1].substring(0, 5);
      }
    }
    if (ts.length >= 5) return ts.substring(0, 5);
    return ts;
  }

  bool get canOpenLocationSettings {
    return locationIssue == LocationUiIssue.serviceDisabled;
  }

  bool get canOpenAppSettings {
    return locationIssue == LocationUiIssue.permissionDeniedForever;
  }

  Future<void> openSettingsForLocation() async {
    bool opened = false;
    if (canOpenLocationSettings) {
      opened = await location.openLocationSettings();
    } else if (canOpenAppSettings) {
      opened = await location.openAppSettings();
    }
    if (opened) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await refreshLocationOnly();
    }
  }

  LocationUiIssue _mapLocationIssue(Object e) {
    if (e is! LocationException) return LocationUiIssue.unknown;
    switch (e.code) {
      case LocationErrorCode.serviceDisabled:
        return LocationUiIssue.serviceDisabled;
      case LocationErrorCode.permissionDenied:
        return LocationUiIssue.permissionDenied;
      case LocationErrorCode.permissionDeniedForever:
        return LocationUiIssue.permissionDeniedForever;
      case LocationErrorCode.timeout:
        return LocationUiIssue.timeout;
      case LocationErrorCode.unknown:
        return LocationUiIssue.unknown;
    }
  }

  
  String _mapLocationError(Object e) {
    if (e is! LocationException) {
      return 'Gagal membaca lokasi saat ini. Coba lagi.';
    }
    switch (e.code) {
      case LocationErrorCode.serviceDisabled:
        return 'Layanan lokasi perangkat mati. Aktifkan GPS lalu cek lokasi lagi.';
      case LocationErrorCode.permissionDenied:
        return 'Izin lokasi ditolak. Berikan izin lokasi agar bisa absen.';
      case LocationErrorCode.permissionDeniedForever:
        return 'Izin lokasi ditolak permanen. Buka Settings dan aktifkan izin lokasi aplikasi.';
      case LocationErrorCode.timeout:
        return 'Lokasi belum terdeteksi. Pindah ke area terbuka lalu coba lagi.';
      case LocationErrorCode.unknown:
        return 'Gagal mengambil lokasi saat ini. Coba lagi.';
    }
  }
}
