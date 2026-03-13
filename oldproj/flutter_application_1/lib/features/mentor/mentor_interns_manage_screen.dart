import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/models/leave_models.dart';
import 'mentor_interns_manage_view_model.dart';

class MentorInternsManageScreen extends StatefulWidget {
  const MentorInternsManageScreen({super.key});

  @override
  State<MentorInternsManageScreen> createState() => _MentorInternsManageScreenState();
}

class _MentorInternsManageScreenState extends State<MentorInternsManageScreen> {
  MentorInternsManageViewModel? _vm;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_vm != null) return;
    final scope = AppScope.of(context);
    _vm = MentorInternsManageViewModel(apiClient: scope.apiClient, session: scope.session)..load();
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
        title: const Text('Data Intern (Bimbingan)'),
        actions: [
          IconButton(onPressed: vm.loading ? null : () => vm.load(), icon: const Icon(Icons.refresh)),
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
                        'Sekolah: ${it.schoolName ?? '-'}',
                      ),
                      isThreeLine: true,
                      onTap: () => _detail(context, it),
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
                          const PopupMenuItem(value: 'delete', child: Text('Hapus Permanen…')),
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

  Future<void> _detail(BuildContext context, InternDto it) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(it.fullName),
        content: SelectableText(
          'Email: ${it.email}\n'
          'Unit: ${it.unitName}\n'
          'Periode: ${it.internshipStart} → ${it.internshipEnd}\n'
          'Aktif: ${it.active}\n'
          'Sekolah: ${it.schoolName ?? '-'}\n'
          'Alamat Sekolah: ${it.schoolAddress ?? '-'}',
        ),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Tutup'))],
      ),
    );
  }

  Future<void> _deletePermanently(BuildContext context, MentorInternsManageViewModel vm, InternDto it) async {
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

