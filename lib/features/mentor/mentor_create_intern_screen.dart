import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/models/unit_models.dart';
import '../../core/services/api_client_base.dart';
import '../../core/models/public_school_models.dart';

class MentorCreateInternScreen extends StatefulWidget {
  const MentorCreateInternScreen({super.key});

  @override
  State<MentorCreateInternScreen> createState() => _MentorCreateInternScreenState();
}

class _MentorCreateInternScreenState extends State<MentorCreateInternScreen> {
  final name = TextEditingController();
  final nisn = TextEditingController();
  final schoolName = TextEditingController();
  final schoolAddress = TextEditingController();
  final start = TextEditingController();
  final end = TextEditingController();
  final password = TextEditingController();

  List<UnitDto> units = const [];
  UnitDto? unit;
  String? error;
  String? tempPassword;
  String schoolQuery = '';
  bool loading = false;
  bool schoolLoading = false;
  List<PublicSchoolDto> schools = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (units.isNotEmpty) return;
    _loadUnits();
    final now = DateTime.now();
    final today = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    start.text = today;
    end.text = today;
  }

  Future<void> _loadUnits() async {
    final scope = AppScope.of(context);
    try {
      final data = await scope.apiClient.getJson('/api/units', bearerToken: scope.session.token);
      if (data is List) {
        setState(() {
          units = data.whereType<Map>().map((e) => UnitDto.fromJson(Map<String, dynamic>.from(e))).toList();
          unit = units.isNotEmpty ? units.first : null;
        });
      }
    } catch (_) {}
  }

  Future<void> _searchSchools({String query = '', StateSetter? refresh}) async {
    void update(VoidCallback fn) {
      if (mounted) setState(fn);
      if (refresh != null) refresh(fn);
    }

    update(() {
      schoolQuery = query.trim();
      schoolLoading = true;
      schools = const []; // kosongkan agar hasil lama hilang saat fetch baru
    });
    final scope = AppScope.of(context);
    try {
      final path = '/api/public/schools?q=${Uri.encodeComponent(query)}&level=SMK&limit=40';
      final data = await scope.apiClient.getJson(path);
      final list = data is List
          ? data
          : (data is Map && data['data'] is List)
              ? data['data'] as List
              : <dynamic>[];
      final qUpper = schoolQuery.toUpperCase();
      final mapped = list
          .whereType<Map>()
          .map((e) => PublicSchoolDto.fromJson(Map<String, dynamic>.from(e)))
          .where((s) {
        if (qUpper.isEmpty) return true;
        final hay = '${s.name} ${s.city ?? ''} ${s.npsn ?? ''}'.toUpperCase();
        return hay.contains(qUpper);
      }).toList();
      // debug log
      // ignore: avoid_print
      print('School search query="$query" raw=${list.length} mapped=${mapped.length}');
      update(() {
        schools = mapped;
      });
    } catch (_) {
      update(() => schools = const []);
    } finally {
      update(() => schoolLoading = false);
    }
  }

  @override
  void dispose() {
    name.dispose();
    nisn.dispose();
    schoolName.dispose();
    schoolAddress.dispose();
    start.dispose();
    end.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftarkan Intern')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 360, maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (error != null) Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                if (tempPassword != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SelectableText('Berhasil. Password sementara:\n$tempPassword'),
                  ),
                TextField(controller: nisn, decoration: const InputDecoration(labelText: 'NISN'), enabled: !loading),
                const SizedBox(height: 12),
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Nama'), enabled: !loading),
                const SizedBox(height: 12),
                TextField(
                  controller: schoolName,
                  decoration: const InputDecoration(labelText: 'Asal Sekolah'),
                  enabled: !loading,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: loading || schoolLoading ? null : () => _pickSchool(),
                      icon: const Icon(Icons.search),
                      label: const Text('Cari SMK'),
                    ),
                    const SizedBox(width: 8),
                    if (schools.isNotEmpty)
                      Expanded(
                        child: Text(
                          schools.isEmpty ? '' : 'Hasil: ${schools.length}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: schoolAddress,
                  decoration: const InputDecoration(labelText: 'Alamat Sekolah (opsional)'),
                  minLines: 2,
                  maxLines: 3,
                  enabled: !loading,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<UnitDto>(
                  initialValue: unit,
                  decoration: const InputDecoration(labelText: 'Unit'),
                  items: units.map((u) => DropdownMenuItem(value: u, child: Text(u.name))).toList(),
                  onChanged: loading ? null : (v) => setState(() => unit = v),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextField(controller: start, decoration: const InputDecoration(labelText: 'Mulai'), enabled: !loading)),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: end, decoration: const InputDecoration(labelText: 'Selesai'), enabled: !loading)),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: password,
                  decoration: const InputDecoration(labelText: 'Password sementara (kosong = auto)'),
                  enabled: !loading,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: loading || unit == null ? null : _submit,
                    child: loading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Buat Akun Intern'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final scope = AppScope.of(context);
    setState(() {
      loading = true;
      error = null;
      tempPassword = null;
    });
    try {
      final data = await scope.apiClient.postJson(
        '/api/mentor/interns',
        bearerToken: scope.session.token,
        body: {
          'fullName': name.text.trim(),
          'nisn': nisn.text.trim(),
          'unitId': unit!.id,
          'internshipStart': start.text.trim(),
          'internshipEnd': end.text.trim(),
          'schoolName': schoolName.text.trim(),
          'schoolAddress': schoolAddress.text.trim(),
          'password': password.text.trim().isEmpty ? null : password.text.trim(),
        },
      );
      if (data is! Map) throw ApiError(code: 'BAD_RESPONSE', message: 'Response tidak valid.');
      setState(() => tempPassword = (data['tempPassword'] ?? '').toString());
    } on ApiError catch (e) {
      setState(() => error = e.message);
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _pickSchool() async {
    await _searchSchools();
    if (!mounted) return;
    final query = TextEditingController();
    final picked = await showDialog<PublicSchoolDto>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, dialogSetState) => AlertDialog(
          title: const Text('Pilih Sekolah (SMK)'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: query,
                        decoration: const InputDecoration(labelText: 'Cari nama / kota / NPSN'),
                        onSubmitted: (v) => _searchSchools(query: v, refresh: dialogSetState),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => _searchSchools(query: query.text.trim(), refresh: dialogSetState),
                      child: const Text('Cari'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 320,
                  child: schoolLoading
                      ? const Center(child: CircularProgressIndicator())
                      : () {
                          final qUpper = schoolQuery.toUpperCase();
                          final results = List<PublicSchoolDto>.from(schools.where((s) {
                            if (qUpper.isEmpty) return true;
                            final hay = '${s.name} ${s.city ?? ''} ${s.npsn ?? ''}'.toUpperCase();
                            return hay.contains(qUpper);
                          }));
                          if (results.isEmpty) return const Center(child: Text('Tidak ada hasil'));
                          return ListView.separated(
                            itemCount: results.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final s = results[i];
                              final subtitle = [
                                if (s.npsn != null && s.npsn!.isNotEmpty) 'NPSN ${s.npsn}',
                                if (s.city != null && s.city!.isNotEmpty) s.city!,
                              ].join(' • ');
                              return ListTile(
                                title: Text(s.name),
                                subtitle: subtitle.isEmpty ? null : Text(subtitle),
                                onTap: () => Navigator.of(context).pop(s),
                              );
                            },
                          );
                        }(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Tutup')),
          ],
        ),
      ),
    );
    query.dispose();
    if (picked != null) {
      setState(() {
        schoolName.text = picked.name;
        schoolAddress.text = picked.address ?? '';
      });
    }
  }

}
