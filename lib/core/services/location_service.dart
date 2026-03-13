import 'dart:async';

import 'package:geolocator/geolocator.dart';

class LocationPoint {
  LocationPoint({required this.lat, required this.lon});

  final double lat;
  final double lon;
}

enum LocationErrorCode {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  unknown,
}

class LocationException implements Exception {
  LocationException({required this.code, required this.message});

  final LocationErrorCode code;
  final String message;

  @override
  String toString() => message;
}

class LocationService {
  Future<LocationPoint> getCurrentLocation() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw LocationException(
        code: LocationErrorCode.serviceDisabled,
        message: 'Layanan lokasi belum aktif.',
      );
    }

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied) {
      throw LocationException(
        code: LocationErrorCode.permissionDenied,
        message: 'Izin lokasi ditolak.',
      );
    }
    if (perm == LocationPermission.deniedForever) {
      throw LocationException(
        code: LocationErrorCode.permissionDeniedForever,
        message: 'Izin lokasi ditolak permanen.',
      );
    }

    try {
      // Paksa ambil posisi terbaru dengan akurasi setinggi mungkin (bukan cache).
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
        timeLimit: const Duration(seconds: 20),
      );
      return LocationPoint(lat: pos.latitude, lon: pos.longitude);
    } on TimeoutException {
      throw LocationException(
        code: LocationErrorCode.timeout,
        message: 'Lokasi belum terdeteksi (timeout).',
      );
    } catch (_) {
      throw LocationException(
        code: LocationErrorCode.unknown,
        message: 'Gagal mengambil lokasi saat ini.',
      );
    }
  }

  Future<bool> openAppSettings() {
    return Geolocator.openAppSettings();
  }

  Future<bool> openLocationSettings() {
    return Geolocator.openLocationSettings();
  }
}
