import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/models/admin_user_models.dart';
import '../../core/models/unit_models.dart';
import 'admin_interns_view_model.dart';

class AdminInternsScreen extends StatefulWidget {
  const AdminInternsScreen({super.key});

  @override
  State<AdminInternsScreen> createState() => _AdminInternsScreenState();
}

class _AdminInternsScreenState extends State<AdminInternsScreen> {
  AdminInternsViewModel? _vm;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_vm != null) return;
    final scope = AppScope.of(context);
    _vm = AdminInternsViewModel(apiClient: scope.apiClient, session: scope.session)..loadAll();
  }

  @override
  void dispose() {
    _vm?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = _vm!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Intern (CRUD)'),
        actions: [
          IconButton(onPressed: vm.loading ? null : () => vm.loadAll(), icon: const Icon(Icons.refresh)),
          IconButton(onPressed: () => _create(context, vm), icon: const Icon(Icons.add)),
        ],
      ),
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) {
          if (vm.loading && vm.interns.isEmpty) return const Center(child: CircularProgressIndicator());
          return Column(
            children: [
              if (vm.error != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(vm.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
              Expanded(
                child: ListView.separated(
                  itemCount: vm.interns.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final it = vm.interns[i];
                    return ListTile(
                      title: Text(it.fullName),
                      subtitle: Text(
                        '${it.email}\n'
                        '${it.unitName} • ${it.internshipStart} → ${it.internshipEnd}\n'
                        'Sekolah: ${it.schoolName ?? '-'}\n'
                        'Mentor: ${it.mentorName ?? '-'}',
                      ),
                      isThreeLine: true,
                      onTap: () => _showDetail(context, it),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) async {
                          if (v == 'toggle') {
                            await vm.toggleActive(userId: it.userId, activate: !it.active);
                          } else if (v == 'delete') {
                            await _deletePermanently(context, vm, it);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'toggle',
                            child: Text(it.active ? 'Nonaktifkan' : 'Aktifkan'),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Hapus Permanen…'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showDetail(BuildContext context, AdminInternRowDto it) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(it.fullName),
        content: SelectableText(
          'Email: ${it.email}\n'
          'Unit: ${it.unitName}\n'
          'Mentor: ${it.mentorName ?? '-'}\n'
          'Periode: ${it.internshipStart} → ${it.internshipEnd}\n'
          'Aktif: ${it.active}\n'
          'Sekolah: ${it.schoolName ?? '-'}\n'
          'Alamat Sekolah: ${it.schoolAddress ?? '-'}',
        ),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Tutup'))],
      ),
    );
  }

  Future<void> _deletePermanently(BuildContext context, AdminInternsViewModel vm, AdminInternRowDto it) async {
    final res = await showDialog<_DeletePayload>(
      context: context,
      builder: (context) => _DeleteInternDialog(name: it.fullName),
    );
    if (res == null) return;
    await vm.deletePermanently(userId: it.userId, force: res.force);
    if (!context.mounted) return;
    if (vm.error == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Intern dihapus permanen.')));
    }
  }

  Future<void> _create(BuildContext context, AdminInternsViewModel vm) async {
    final res = await showDialog<_CreateInternPayload>(
      context: context,
      builder: (context) => _CreateInternDialog(units: vm.units, mentors: vm.mentors),
    );
    if (res == null) return;
    final temp = await vm.create(
      email: res.email,
      fullName: res.fullName,
      unitId: res.unitId,
      mentorUserId: res.mentorUserId,
      internshipStart: res.start,
      internshipEnd: res.end,
      schoolName: res.schoolName,
      schoolAddress: res.schoolAddress,
      password: res.password,
    );
    if (!mounted) return;
    if (temp != null && temp.isNotEmpty) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Intern dibuat'),
          content: SelectableText('Password sementara:\n\n$temp'),
          actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Tutup'))],
        ),
      );
    }
  }
}

class _CreateInternPayload {
  _CreateInternPayload({
    required this.email,
    required this.fullName,
    required this.unitId,
    required this.mentorUserId,
    required this.start,
    required this.end,
    required this.schoolName,
    required this.schoolAddress,
    required this.password,
  });

  final String email;
  final String fullName;
  final int unitId;
  final int? mentorUserId;
  final String start;
  final String end;
  final String schoolName;
  final String schoolAddress;
  final String password;
}

class _CreateInternDialog extends StatefulWidget {
  const _CreateInternDialog({required this.units, required this.mentors});

  final List<UnitDto> units;
  final List<MentorMiniDto> mentors;

  @override
  State<_CreateInternDialog> createState() => _CreateInternDialogState();
}

class _CreateInternDialogState extends State<_CreateInternDialog> {
  final email = TextEditingController();
  final name = TextEditingController();
  final schoolName = TextEditingController();
  final schoolAddress = TextEditingController();
  final start = TextEditingController();
  final end = TextEditingController();
  final password = TextEditingController();
  int? unitId;
  int? mentorUserId;

  @override
  void initState() {
    super.initState();
    if (widget.units.isNotEmpty) unitId = widget.units.first.id;
    final now = DateTime.now();
    final today = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    start.text = today;
    end.text = today;
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
    return AlertDialog(
      title: const Text('Tambah Intern'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 12),
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Nama')),
            const SizedBox(height: 12),
            TextField(controller: schoolName, decoration: const InputDecoration(labelText: 'Asal Sekolah')),
            const SizedBox(height: 12),
            TextField(
              controller: schoolAddress,
              decoration: const InputDecoration(labelText: 'Alamat Sekolah (opsional)'),
              minLines: 2,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: unitId,
              decoration: const InputDecoration(labelText: 'Unit'),
              items: widget.units.map((u) => DropdownMenuItem(value: u.id, child: Text(u.name))).toList(),
              onChanged: (v) => setState(() => unitId = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              initialValue: mentorUserId,
              decoration: const InputDecoration(labelText: 'Pembimbing (opsional)'),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('—')),
                ...widget.mentors.map((m) => DropdownMenuItem<int?>(value: m.id, child: Text(m.fullName))),
              ],
              onChanged: (v) => setState(() => mentorUserId = v),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextField(controller: start, decoration: const InputDecoration(labelText: 'Mulai'))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: end, decoration: const InputDecoration(labelText: 'Selesai'))),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: password,
              decoration: const InputDecoration(labelText: 'Password sementara (kosong = auto)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Batal')),
        FilledButton(
          onPressed: () {
            if (unitId == null) return;
            Navigator.of(context).pop(
              _CreateInternPayload(
                email: email.text.trim(),
                fullName: name.text.trim(),
                unitId: unitId!,
                mentorUserId: mentorUserId,
                start: start.text.trim(),
                end: end.text.trim(),
                schoolName: schoolName.text.trim(),
                schoolAddress: schoolAddress.text.trim(),
                password: password.text.trim(),
              ),
            );
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

class _DeletePayload {
  _DeletePayload({required this.force});

  final bool force;
}

class _DeleteInternDialog extends StatefulWidget {
  const _DeleteInternDialog({required this.name});

  final String name;

  @override
  State<_DeleteInternDialog> createState() => _DeleteInternDialogState();
}

class _DeleteInternDialogState extends State<_DeleteInternDialog> {
  final confirm = TextEditingController();
  bool force = false;

  @override
  void dispose() {
    confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Hapus Permanen'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'PERINGATAN KERAS:\n'
            'Hapus permanen akan menghapus akun intern dan (jika force) seluruh riwayat absensi/izin.\n\n'
            'Intern: ${widget.name}',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: confirm,
            decoration: const InputDecoration(labelText: 'Ketik HAPUS untuk konfirmasi'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            value: force,
            onChanged: (v) => setState(() => force = v ?? false),
            title: const Text('Force delete (hapus riwayat)'),
            subtitle: const Text('Jika intern punya riwayat, ini wajib untuk menghapus permanen.'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Batal')),
        FilledButton(
          onPressed: confirm.text.trim().toUpperCase() == 'HAPUS'
              ? () => Navigator.of(context).pop(_DeletePayload(force: force))
              : null,
          child: const Text('Hapus'),
        ),
      ],
    );
  }
}
