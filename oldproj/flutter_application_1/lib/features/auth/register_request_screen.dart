import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/models/public_school_models.dart';
import '../../core/models/public_unit_models.dart';
import 'register_request_view_model.dart';

class RegisterRequestScreen extends StatefulWidget {
  const RegisterRequestScreen({super.key});

  @override
  State<RegisterRequestScreen> createState() => _RegisterRequestScreenState();
}

class _RegisterRequestScreenState extends State<RegisterRequestScreen> {
  RegisterRequestViewModel? _vm;

  final _email = TextEditingController();
  final _name = TextEditingController();
  final _schoolName = TextEditingController();
  final _schoolAddress = TextEditingController();
  final _start = TextEditingController();
  final _end = TextEditingController();
  final _notes = TextEditingController();
  PublicUnitDto? _unit;
  PublicSchoolDto? _selectedSchool;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_vm != null) return;
    final scope = AppScope.of(context);
    _vm = RegisterRequestViewModel(apiClient: scope.apiClient);
    _vm!.loadUnits().then((_) {
      if (!mounted) return;
      setState(() {
        _unit = _vm!.units.isNotEmpty ? _vm!.units.first : null;
      });
    });
    _vm!.searchSchools();
    final now = DateTime.now();
    final today = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    _start.text = today;
    _end.text = today;
  }

  @override
  void dispose() {
    _vm?.dispose();
    _email.dispose();
    _name.dispose();
    _schoolName.dispose();
    _schoolAddress.dispose();
    _start.dispose();
    _end.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = _vm!;
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar PKL (Request)')),
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Isi data, lalu admin akan approve (status PENDING).'),
              const SizedBox(height: 12),
              if (vm.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(vm.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
              if (vm.submitted)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Request terkirim. ID: ${vm.requestId ?? '-'} (PENDING)',
                    style: const TextStyle(color: Colors.green),
                  ),
                ),
              TextField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email'),
                enabled: !vm.loading,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                enabled: !vm.loading,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _schoolName,
                decoration: const InputDecoration(labelText: 'Asal Sekolah'),
                enabled: !vm.loading,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: vm.loading || vm.schoolLoading ? null : () => _pickSchool(vm),
                      icon: const Icon(Icons.search),
                      label: const Text('Cari SMK'),
                    ),
                    if (_selectedSchool != null)
                      Chip(
                        label: Text(
                          _selectedSchool!.city == null || _selectedSchool!.city!.trim().isEmpty
                              ? _selectedSchool!.name
                              : '${_selectedSchool!.name} (${_selectedSchool!.city})',
                        ),
                      ),
                  ],
                ),
              ),
              if (vm.schoolError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    vm.schoolError!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: _schoolAddress,
                decoration: const InputDecoration(labelText: 'Alamat Sekolah (opsional)'),
                minLines: 2,
                maxLines: 3,
                enabled: !vm.loading,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<PublicUnitDto>(
                initialValue: _unit,
                decoration: const InputDecoration(labelText: 'Unit'),
                items: vm.units.map((u) => DropdownMenuItem(value: u, child: Text('${u.id} • ${u.name}'))).toList(),
                onChanged: vm.loading ? null : (v) => setState(() => _unit = v),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _start,
                      decoration: const InputDecoration(labelText: 'Mulai (YYYY-MM-DD)'),
                      enabled: !vm.loading,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _end,
                      decoration: const InputDecoration(labelText: 'Selesai (YYYY-MM-DD)'),
                      enabled: !vm.loading,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notes,
                decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
                minLines: 2,
                maxLines: 4,
                enabled: !vm.loading,
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: vm.loading || _unit == null
                      ? null
                      : () => vm.submit(
                            email: _email.text.trim(),
                            fullName: _name.text.trim(),
                            unitId: _unit!.id,
                            internshipStart: _start.text.trim(),
                            internshipEnd: _end.text.trim(),
                            schoolName: _schoolName.text.trim(),
                            schoolAddress: _schoolAddress.text.trim(),
                            notes: _notes.text.trim(),
                            schoolId: _selectedSchool?.id,
                          ),
                  child: vm.loading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Kirim Request'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _pickSchool(RegisterRequestViewModel vm) async {
    final queryController = TextEditingController();
    await vm.searchSchools();
    if (!mounted) {
      queryController.dispose();
      return;
    }

    final picked = await showDialog<PublicSchoolDto>(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
                      controller: queryController,
                      decoration: const InputDecoration(
                        labelText: 'Cari nama / kota / NPSN',
                      ),
                      onSubmitted: (value) => vm.searchSchools(query: value.trim()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => vm.searchSchools(query: queryController.text.trim()),
                    child: const Text('Cari'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 320,
                child: ListenableBuilder(
                  listenable: vm,
                  builder: (context, _) {
                    if (vm.schoolLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (vm.schools.isEmpty) {
                      return const Center(
                        child: Text('Sekolah tidak ditemukan.\nCoba kata kunci lain.'),
                      );
                    }
                    return ListView.separated(
                      itemCount: vm.schools.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final school = vm.schools[index];
                        final subtitleParts = <String>[
                          if (school.npsn != null && school.npsn!.trim().isNotEmpty) 'NPSN ${school.npsn}',
                          if (school.city != null && school.city!.trim().isNotEmpty) school.city!,
                        ];
                        return ListTile(
                          title: Text(school.name),
                          subtitle: subtitleParts.isEmpty ? null : Text(subtitleParts.join(' • ')),
                          onTap: () => Navigator.of(dialogContext).pop(school),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
    queryController.dispose();

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _selectedSchool = picked;
      _schoolName.text = picked.name;
      if (_schoolAddress.text.trim().isEmpty && picked.address != null && picked.address!.trim().isNotEmpty) {
        _schoolAddress.text = picked.address!;
      }
    });
  }
}
