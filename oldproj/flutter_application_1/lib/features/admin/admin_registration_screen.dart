import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/models/admin_user_models.dart';
import '../../core/models/registration_models.dart';
import '../../core/models/unit_models.dart';
import 'admin_registration_view_model.dart';

class AdminRegistrationScreen extends StatefulWidget {
  const AdminRegistrationScreen({super.key});

  @override
  State<AdminRegistrationScreen> createState() => _AdminRegistrationScreenState();
}

class _AdminRegistrationScreenState extends State<AdminRegistrationScreen> {
  AdminRegistrationViewModel? _vm;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_vm != null) return;
    final scope = AppScope.of(context);
    _vm = AdminRegistrationViewModel(apiClient: scope.apiClient, session: scope.session)..loadAll();
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
        title: const Text('Approval Pendaftaran (Request)'),
        actions: [
          IconButton(onPressed: vm.loading ? null : () => vm.loadAll(), icon: const Icon(Icons.refresh)),
        ],
      ),
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) {
          if (vm.loading && vm.pending.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              if (vm.error != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(vm.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
              Expanded(
                child: vm.pending.isEmpty
                    ? const Center(child: Text('Tidak ada request PENDING.'))
                    : ListView.separated(
                        itemCount: vm.pending.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) => _ReqTile(
                          item: vm.pending[i],
                          onApprove: () => _approve(context, vm, vm.pending[i]),
                          onReject: () => _reject(context, vm, vm.pending[i]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _reject(BuildContext context, AdminRegistrationViewModel vm, RegistrationRequestDto item) async {
    final reason = await _askReason(context, title: 'Reject Request', hint: 'Alasan reject (wajib)');
    if (reason == null) return;
    await vm.reject(requestId: item.id, reason: reason);
  }

  Future<void> _approve(BuildContext context, AdminRegistrationViewModel vm, RegistrationRequestDto item) async {
    final res = await showDialog<_ApprovePayload>(
      context: context,
      builder: (context) => _ApproveDialog(
        item: item,
        units: vm.units,
        mentors: vm.mentors,
      ),
    );
    if (res == null) return;
    final temp = await vm.approve(
      requestId: item.id,
      unitId: res.unitId,
      mentorUserId: res.mentorUserId,
      internshipStart: res.internshipStart,
      internshipEnd: res.internshipEnd,
      tempPassword: res.tempPassword,
      reason: res.reason,
    );
    if (!mounted) return;
    if (temp != null && temp.isNotEmpty) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Berhasil Approve'),
          content: SelectableText('Password sementara untuk intern:\n\n$temp'),
          actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Tutup'))],
        ),
      );
    }
  }

  Future<String?> _askReason(BuildContext context, {required String title, required String hint}) async {
    final c = TextEditingController();
    final res = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(controller: c, decoration: InputDecoration(labelText: hint), minLines: 2, maxLines: 4),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.of(context).pop(c.text.trim()), child: const Text('Simpan')),
        ],
      ),
    );
    c.dispose();
    if (res == null || res.trim().isEmpty) return null;
    return res.trim();
  }
}

class _ReqTile extends StatelessWidget {
  const _ReqTile({required this.item, required this.onApprove, required this.onReject});

  final RegistrationRequestDto item;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(item.fullName),
      subtitle: Text(
        '${item.email}\n'
        'Sekolah: ${item.schoolName ?? '-'}\n'
        '${item.unitName}\n'
        '${item.internshipStart} → ${item.internshipEnd}',
      ),
      isThreeLine: true,
      trailing: Wrap(
        spacing: 8,
        children: [
          IconButton(onPressed: onReject, icon: const Icon(Icons.close)),
          IconButton(onPressed: onApprove, icon: const Icon(Icons.check)),
        ],
      ),
    );
  }
}

class _ApprovePayload {
  _ApprovePayload({
    required this.unitId,
    required this.mentorUserId,
    required this.internshipStart,
    required this.internshipEnd,
    required this.tempPassword,
    required this.reason,
  });

  final int unitId;
  final int? mentorUserId;
  final String internshipStart;
  final String internshipEnd;
  final String tempPassword;
  final String reason;
}

class _ApproveDialog extends StatefulWidget {
  const _ApproveDialog({required this.item, required this.units, required this.mentors});

  final RegistrationRequestDto item;
  final List<UnitDto> units;
  final List<MentorMiniDto> mentors;

  @override
  State<_ApproveDialog> createState() => _ApproveDialogState();
}

class _ApproveDialogState extends State<_ApproveDialog> {
  late int unitId = widget.item.unitId;
  int? mentorUserId;
  late final TextEditingController start = TextEditingController(text: widget.item.internshipStart);
  late final TextEditingController end = TextEditingController(text: widget.item.internshipEnd);
  final TextEditingController tempPassword = TextEditingController();
  final TextEditingController reason = TextEditingController();

  @override
  void dispose() {
    start.dispose();
    end.dispose();
    tempPassword.dispose();
    reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Approve Request'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if ((widget.item.schoolName ?? '').isNotEmpty || (widget.item.schoolAddress ?? '').isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Sekolah: ${widget.item.schoolName ?? '-'}'),
              ),
              if ((widget.item.schoolAddress ?? '').isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Alamat: ${widget.item.schoolAddress}'),
                ),
              const SizedBox(height: 12),
            ],
            DropdownButtonFormField<int>(
              initialValue: unitId,
              decoration: const InputDecoration(labelText: 'Unit'),
              items: widget.units.map((u) => DropdownMenuItem(value: u.id, child: Text(u.name))).toList(),
              onChanged: (v) => setState(() => unitId = v ?? unitId),
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
              controller: tempPassword,
              decoration: const InputDecoration(labelText: 'Password sementara (kosong = auto)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reason,
              decoration: const InputDecoration(labelText: 'Alasan (wajib)'),
              minLines: 2,
              maxLines: 4,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Batal')),
        FilledButton(
          onPressed: () {
            final r = reason.text.trim();
            if (r.isEmpty) return;
            Navigator.of(context).pop(
              _ApprovePayload(
                unitId: unitId,
                mentorUserId: mentorUserId,
                internshipStart: start.text.trim(),
                internshipEnd: end.text.trim(),
                tempPassword: tempPassword.text.trim(),
                reason: r,
              ),
            );
          },
          child: const Text('Approve'),
        ),
      ],
    );
  }
}
