import 'package:geolocator/geolocator.dart';

class LocationPoint {
  LocationPoint({required this.lat, required this.lon});

  final double lat;
  final double lon;
}

class LocationService {
  Future<LocationPoint> getCurrentLocation() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw Exception('Location service tidak aktif.');
    }

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied) {
      throw Exception('Izin lokasi ditolak.');
    }
    if (perm == LocationPermission.deniedForever) {
      throw Exception('Izin lokasi ditolak permanen. Buka Settings untuk mengaktifkan.');
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 15),
    );
    return LocationPoint(lat: pos.latitude, lon: pos.longitude);
  }
}

