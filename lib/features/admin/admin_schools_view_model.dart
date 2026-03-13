import 'package:flutter/foundation.dart';

import '../../core/services/api_client_base.dart';
import '../../core/services/session_store.dart';
import 'admin_interns_view_model.dart';

class SchoolInternGroup {
  SchoolInternGroup({
    required this.schoolName,
    required this.interns,
    required this.activeCount,
    required this.unitCounts,
    required this.mentorCounts,
  });

  final String schoolName;
  final List<AdminInternRowDto> interns;
  final int activeCount;
  final Map<String, int> unitCounts;
  final Map<String, int> mentorCounts;
}

class AdminSchoolsViewModel extends ChangeNotifier {
  AdminSchoolsViewModel({required this.apiClient, required this.session});

  final ApiClient apiClient;
  final SessionStore session;

  bool loading = false;
  String? error;
  String query = '';
  DateTime? filterFrom;
  DateTime? filterTo;
  List<AdminInternRowDto> _interns = const [];

  List<SchoolInternGroup> get schools {
    final visibleInterns = _interns
        .where(_matchesPeriodFilter)
        .toList(growable: false);
    final grouped = _buildGroups(visibleInterns);
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return grouped;
    }
    return grouped
        .where((s) => s.schoolName.toLowerCase().contains(q))
        .toList(growable: false);
  }

  int get totalInterns => schools.fold<int>(0, (p, s) => p + s.interns.length);

  Future<void> load() async {
    if (!session.isAuthenticated) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final data = await apiClient.getJson(
        '/api/admin/interns',
        bearerToken: session.token,
      );
      if (data is! List) {
        throw ApiError(
          code: 'BAD_RESPONSE',
          message: 'Format data tidak valid.',
        );
      }
      _interns = data
          .whereType<Map>()
          .map((e) => AdminInternRowDto.fromJson(Map<String, dynamic>.from(e)))
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

  void setQuery(String value) {
    query = value;
    notifyListeners();
  }

  void setFilterFrom(DateTime? value) {
    filterFrom = value;
    if (filterFrom != null &&
        filterTo != null &&
        filterFrom!.isAfter(filterTo!)) {
      filterTo = filterFrom;
    }
    notifyListeners();
  }

  void setFilterTo(DateTime? value) {
    filterTo = value;
    if (filterFrom != null &&
        filterTo != null &&
        filterTo!.isBefore(filterFrom!)) {
      filterFrom = filterTo;
    }
    notifyListeners();
  }

  void clearPeriodFilter() {
    filterFrom = null;
    filterTo = null;
    notifyListeners();
  }

  bool _matchesPeriodFilter(AdminInternRowDto it) {
    if (filterFrom == null && filterTo == null) {
      return true;
    }
    final start = _parseDate(it.internshipStart);
    final end = _parseDate(it.internshipEnd);
    if (start == null || end == null) {
      return true;
    }
    final rangeFrom = _dateOnly(filterFrom ?? filterTo!);
    final rangeTo = _dateOnly(filterTo ?? filterFrom!);
    final internFrom = _dateOnly(start);
    final internTo = _dateOnly(end);

    return !internTo.isBefore(rangeFrom) && !internFrom.isAfter(rangeTo);
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime? _parseDate(String raw) {
    if (raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw.trim());
  }

  static List<SchoolInternGroup> _buildGroups(List<AdminInternRowDto> interns) {
    final grouped = <String, List<AdminInternRowDto>>{};
    for (final it in interns) {
      final school = _normalizedSchoolName(it.schoolName);
      grouped.putIfAbsent(school, () => <AdminInternRowDto>[]).add(it);
    }

    final keys = grouped.keys.toList(growable: false)..sort();
    final result = <SchoolInternGroup>[];
    for (final school in keys) {
      final list = List<AdminInternRowDto>.from(grouped[school]!)
        ..sort(
          (a, b) =>
              a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
        );

      final unitCounts = <String, int>{};
      final mentorCounts = <String, int>{};
      var activeCount = 0;

      for (final it in list) {
        unitCounts[it.unitName] = (unitCounts[it.unitName] ?? 0) + 1;
        final mentor = (it.mentorName ?? '').trim().isEmpty
            ? '-'
            : it.mentorName!.trim();
        mentorCounts[mentor] = (mentorCounts[mentor] ?? 0) + 1;
        if (it.active) activeCount++;
      }

      result.add(
        SchoolInternGroup(
          schoolName: school,
          interns: list,
          activeCount: activeCount,
          unitCounts: unitCounts,
          mentorCounts: mentorCounts,
        ),
      );
    }

    return result;
  }

  static String _normalizedSchoolName(String? value) {
    final v = (value ?? '').trim();
    return v.isEmpty ? '(Sekolah belum diisi)' : v;
  }
}
