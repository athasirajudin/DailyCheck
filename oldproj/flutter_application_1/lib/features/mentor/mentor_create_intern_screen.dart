import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/models/unit_models.dart';
import '../../core/services/api_client_base.dart';

class MentorCreateInternScreen extends StatefulWidget {
  const MentorCreateInternScreen({super.key});

  @override
  State<MentorCreateInternScreen> createState() => _MentorCreateInternScreenState();
}

class _MentorCreateInternScreenState extends State<MentorCreateInternScreen> {
  final email = TextEditingController();
  final name = TextEditingController();
  final schoolName = TextEditingController();
  final schoolAddress = TextEditingController();
  final start = TextEditingController();
  final end = TextEditingController();
  final password = TextEditingController();

  List<UnitDto> units = const [];
  UnitDto? unit;
  String? error;
  String? tempPassword;
  bool loading = false;

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

  @override
  void dispose() {
    email.dispose();
    name.dispose();
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
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (error != null) Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                if (tempPassword != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SelectableText('Berhasil. Password sementara:\n$tempPassword'),
                  ),
                TextField(controller: email, decoration: const InputDecoration(labelText: 'Email'), enabled: !loading),
                const SizedBox(height: 12),
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Nama'), enabled: !loading),
                const SizedBox(height: 12),
                TextField(
                  controller: schoolName,
                  decoration: const InputDecoration(labelText: 'Asal Sekolah'),
                  enabled: !loading,
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
          'email': email.text.trim(),
          'fullName': name.text.trim(),
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
}
