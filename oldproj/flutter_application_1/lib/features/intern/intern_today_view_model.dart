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
  });

  final String date;
  final String unitName;
  final String? status;
  final String? checkInAt;
  final String? checkOutAt;
  final bool? checkoutMissing;
}

class InternTodayViewModel extends ChangeNotifier {
  InternTodayViewModel({required this.apiClient, required this.session});

  final ApiClient apiClient;
  final SessionStore session;

  bool loading = false;
  String? error;
  InternTodayState? state;

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
      final data = await apiClient.getJson('/api/intern/today', bearerToken: session.token);
      if (data is! Map) {
        throw ApiError(code: 'BAD_RESPONSE', message: 'Format data hari ini tidak valid.');
      }
      final map = Map<String, dynamic>.from(data);
      final unit = map['unit'] as Map?;
      final attendance = map['attendance'];
      state = InternTodayState(
        date: (map['date'] ?? '').toString(),
        unitName: (unit?['name'] ?? '').toString(),
        status: attendance is Map ? (attendance['status']?.toString()) : null,
        checkInAt: attendance is Map ? (attendance['checkInAt']?.toString()) : null,
        checkOutAt: attendance is Map ? (attendance['checkOutAt']?.toString()) : null,
        checkoutMissing: attendance is Map ? (attendance['checkoutMissing'] == true) : null,
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

