import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/models/attendance_models.dart';
import '../../core/models/leave_models.dart';
import '../../core/services/api_client_base.dart';
import '../../core/services/session_store.dart';

class AdminRecapViewModel extends ChangeNotifier {
  AdminRecapViewModel({required this.apiClient, required this.session})
      : dateFrom = _todayMinus(days: 7),
        dateTo = _today();

  final ApiClient apiClient;
  final SessionStore session;

  bool loading = false;
  String? error;

  List<InternDto> interns = const [];
  int? selectedInternUserId;
  List<String> schools = const [];
  String? selectedSchoolName;

  String dateFrom;
  String dateTo;

  RecapSummary? summary;
  List<RecapItem> items = const [];

  Timer? _timer;

  static String _today() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static String _todayMinus({required int days}) {
    final d = DateTime.now().subtract(Duration(days: days));
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  void start() {
    _loadInterns();
    refresh();
    _timer = Timer.periodic(const Duration(seconds: 12), (_) => refresh(silent: true));
  }

  Future<void> _loadInterns() async {
    if (!session.isAuthenticated) return;
    try {
      final data = await apiClient.getJson('/api/mentor/interns', bearerToken: session.token);
      if (data is! List) return;
      interns = data.whereType<Map>().map((e) => InternDto.fromJson(Map<String, dynamic>.from(e))).toList();
      schools = interns
          .map((item) => item.schoolName?.trim() ?? '')
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      notifyListeners();
    } catch (_) {}
  }

  void setDateFrom(String v) {
    dateFrom = v;
    notifyListeners();
  }

  void setDateTo(String v) {
    dateTo = v;
    notifyListeners();
  }

  void setSelectedIntern(int? userId) {
    selectedInternUserId = userId;
    refresh();
  }

  void setSelectedSchool(String? schoolName) {
    selectedSchoolName = schoolName;
    refresh();
  }

  Future<void> refresh({bool silent = false}) async {
    if (!session.isAuthenticated) return;
    if (!silent) {
      loading = true;
      notifyListeners();
    }
    error = null;
    try {
      final query = <String, String>{
        'dateFrom': dateFrom,
        'dateTo': dateTo,
        if (selectedInternUserId != null) 'internUserId': selectedInternUserId.toString(),
        if (selectedSchoolName != null && selectedSchoolName!.trim().isNotEmpty) 'schoolName': selectedSchoolName!,
      };
      final data = await apiClient.getJson('/api/admin/recap', bearerToken: session.token, query: query);
      if (data is! Map) throw ApiError(code: 'BAD_RESPONSE', message: 'Format rekap tidak valid.');
      final map = Map<String, dynamic>.from(data);
      final sum = map['summary'];
      final list = map['items'];
      if (sum is! Map || list is! List) throw ApiError(code: 'BAD_RESPONSE', message: 'Rekap tidak lengkap.');
      summary = RecapSummary.fromJson(Map<String, dynamic>.from(sum));
      items = list.whereType<Map>().map((e) => RecapItem.fromJson(Map<String, dynamic>.from(e))).toList(growable: false);
    } on ApiError catch (e) {
      error = e.message;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  String exportUrl() {
    final base = apiClient.baseUrl.endsWith('/') ? apiClient.baseUrl.substring(0, apiClient.baseUrl.length - 1) : apiClient.baseUrl;
    final q = <String, String>{
      'format': 'csv',
      'dateFrom': dateFrom,
      'dateTo': dateTo,
      if (selectedSchoolName != null && selectedSchoolName!.trim().isNotEmpty) 'schoolName': selectedSchoolName!,
    };
    final uri = Uri.parse('$base/api/admin/recap/export').replace(queryParameters: q);
    return uri.toString();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
