import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/models/attendance_models.dart';
import '../../core/services/api_client_base.dart';
import '../../core/services/session_store.dart';

class MentorRecapViewModel extends ChangeNotifier {
  MentorRecapViewModel({required this.apiClient, required this.session})
    : dateFrom = _todayMinus(days: 7),
      dateTo = _today();

  final ApiClient apiClient;
  final SessionStore session;

  bool loading = false;
  String? error;

  String dateFrom;
  String dateTo;

  RecapSummary? summary;
  List<RecapItem> items = const [];

  Timer? _timer;

  MentorRecapViewModel.initial({required this.apiClient, required this.session})
    : dateFrom = _todayMinus(days: 7),
      dateTo = _today();

  static String _today() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static String _todayMinus({required int days}) {
    final d = DateTime.now().subtract(Duration(days: days));
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  void start() {
    refresh();
    _timer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => refresh(silent: true),
    );
  }

  void setDateFrom(String v) {
    dateFrom = v;
    notifyListeners();
  }

  void setDateTo(String v) {
    dateTo = v;
    notifyListeners();
  }

  Future<void> refresh({bool silent = false}) async {
    if (!session.isAuthenticated) return;
    if (!silent) {
      loading = true;
      notifyListeners();
    }
    error = null;
    try {
      final query = <String, String>{'dateFrom': dateFrom, 'dateTo': dateTo};
      final data = await apiClient.getJson(
        '/api/mentor/recap',
        bearerToken: session.token,
        query: query,
      );
      if (data is! Map) {
        throw ApiError(
          code: 'BAD_RESPONSE',
          message: 'Format rekap tidak valid.',
        );
      }
      final map = Map<String, dynamic>.from(data);
      final sum = map['summary'];
      final list = map['items'];
      if (sum is! Map || list is! List) {
        throw ApiError(code: 'BAD_RESPONSE', message: 'Rekap tidak lengkap.');
      }
      summary = RecapSummary.fromJson(Map<String, dynamic>.from(sum));
      items = list
          .whereType<Map>()
          .map((e) => RecapItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    } on ApiError catch (e) {
      error = e.message;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> overrideStatus({
    required int attendanceId,
    required String status,
    required String reason,
  }) async {
    if (!session.isAuthenticated) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      await apiClient.postJson(
        '/api/mentor/attendance/$attendanceId/override',
        bearerToken: session.token,
        body: {'status': status, 'reason': reason},
      );
      await refresh(silent: true);
    } on ApiError catch (e) {
      error = e.message;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<Uint8List> exportFile({required String format}) {
    final normalizedFormat = _normalizeFormat(format);
    final q = <String, String>{
      'format': normalizedFormat,
      'dateFrom': dateFrom,
      'dateTo': dateTo,
    };
    return apiClient.getBytes(
      '/api/mentor/recap/export',
      bearerToken: session.token,
      query: q,
    );
  }

  String exportFileName({required String format}) {
    final normalizedFormat = _normalizeFormat(format);
    final datePart = dateFrom == dateTo ? dateFrom : '${dateFrom}_$dateTo';
    return 'rekap_absen_bimbingan_$datePart.$normalizedFormat';
  }

  String _normalizeFormat(String format) {
    final f = format.trim().toLowerCase();
    if (f == 'xlsx') return 'xlsx';
    return 'csv';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
