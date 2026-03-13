import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/models/attendance_models.dart';
import 'mentor_recap_view_model.dart';

class MentorRecapScreen extends StatefulWidget {
  const MentorRecapScreen({super.key});

  @override
  State<MentorRecapScreen> createState() => _MentorRecapScreenState();
}

class _MentorRecapScreenState extends State<MentorRecapScreen> {
  MentorRecapViewModel? _vm;
  final _dateFromCtrl = TextEditingController();
  final _dateToCtrl = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_vm != null) return;
    final scope = AppScope.of(context);
    _vm = MentorRecapViewModel.initial(apiClient: scope.apiClient, session: scope.session)..start();
    _dateFromCtrl.text = _vm!.dateFrom;
    _dateToCtrl.text = _vm!.dateTo;
  }

  @override
  void dispose() {
    _vm?.dispose();
    _dateFromCtrl.dispose();
    _dateToCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = _vm!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekap Bimbingan'),
        actions: [
          IconButton(onPressed: vm.loading ? null : () => vm.refresh(), icon: const Icon(Icons.refresh)),
        ],
      ),
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(labelText: 'Date From (YYYY-MM-DD)'),
                            controller: _dateFromCtrl,
                            onChanged: (v) {
                              vm.setDateFrom(v.trim());
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(labelText: 'Date To (YYYY-MM-DD)'),
                            controller: _dateToCtrl,
                            onChanged: (v) {
                              vm.setDateTo(v.trim());
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int?>(
                      initialValue: vm.selectedInternUserId,
                      decoration: const InputDecoration(labelText: 'Filter Intern (opsional)'),
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('Semua Intern')),
                        ...vm.interns.map(
                          (i) => DropdownMenuItem<int?>(
                            value: i.userId,
                            child: Text(i.fullName),
                          ),
                        ),
                      ],
                      onChanged: (v) => vm.setSelectedIntern(v),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      initialValue: vm.selectedSchoolName,
                      decoration: const InputDecoration(labelText: 'Filter Sekolah (opsional)'),
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text('Semua Sekolah')),
                        ...vm.schools.map(
                          (name) => DropdownMenuItem<String?>(
                            value: name,
                            child: Text(name),
                          ),
                        ),
                      ],
                      onChanged: (v) => vm.setSelectedSchool(v),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: vm.loading ? null : () => vm.refresh(),
                        icon: const Icon(Icons.search),
                        label: const Text('Tampilkan'),
                      ),
                    ),
                  ],
                ),
              ),
              if (vm.error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(vm.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
              if (vm.summary != null) _SummaryBar(summary: vm.summary!),
              const Divider(height: 1),
              Expanded(
                child: vm.loading && vm.items.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.separated(
                        itemCount: vm.items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) => _RecapTile(
                          item: vm.items[i],
                          onOverride: () => _override(context, vm, vm.items[i]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _override(BuildContext context, MentorRecapViewModel vm, RecapItem item) async {
    final res = await showDialog<_OverrideResult>(
      context: context,
      builder: (context) => _OverrideDialog(current: item.status),
    );
    if (res == null) return;
    await vm.overrideStatus(attendanceId: item.id, status: res.status, reason: res.reason);
  }
}

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({required this.summary});

  final RecapSummary summary;

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, int value) => Chip(label: Text('$label: $value'));
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          chip('HADIR', summary.hadir),
          const SizedBox(width: 8),
          chip('TERLAMBAT', summary.terlambat),
          const SizedBox(width: 8),
          chip('IZIN', summary.izin),
          const SizedBox(width: 8),
          chip('SAKIT', summary.sakit),
          const SizedBox(width: 8),
          chip('ALPA', summary.alpa),
          const SizedBox(width: 8),
          chip('CHECKOUT?', summary.checkoutMissing),
        ],
      ),
    );
  }
}

class _RecapTile extends StatelessWidget {
  const _RecapTile({required this.item, required this.onOverride});

  final RecapItem item;
  final VoidCallback onOverride;

  @override
  Widget build(BuildContext context) {
    final schoolLabel = (item.schoolName == null || item.schoolName!.trim().isEmpty) ? '-' : item.schoolName!;
    return ListTile(
      title: Text('${item.internName} - ${item.date}'),
      subtitle: Text(
        'Sekolah: $schoolLabel\nStatus: ${item.status} (by ${item.markedBy})\nIN: ${item.checkInAt ?? '-'} | OUT: ${item.checkOutAt ?? '-'}',
      ),
      trailing: IconButton(
        icon: const Icon(Icons.edit),
        onPressed: onOverride,
        tooltip: 'Override status',
      ),
      isThreeLine: true,
    );
  }
}

class _OverrideResult {
  _OverrideResult({required this.status, required this.reason});

  final String status;
  final String reason;
}

class _OverrideDialog extends StatefulWidget {
  const _OverrideDialog({required this.current});

  final String current;

  @override
  State<_OverrideDialog> createState() => _OverrideDialogState();
}

class _OverrideDialogState extends State<_OverrideDialog> {
  late String status = widget.current;
  final reason = TextEditingController();

  @override
  void dispose() {
    reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Override Status'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: status,
            decoration: const InputDecoration(labelText: 'Status baru'),
            items: const [
              DropdownMenuItem(value: 'HADIR', child: Text('HADIR')),
              DropdownMenuItem(value: 'TERLAMBAT', child: Text('TERLAMBAT')),
              DropdownMenuItem(value: 'ALPA', child: Text('ALPA')),
              DropdownMenuItem(value: 'IZIN', child: Text('IZIN')),
              DropdownMenuItem(value: 'SAKIT', child: Text('SAKIT')),
            ],
            onChanged: (v) => setState(() => status = v ?? status),
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
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Batal')),
        FilledButton(
          onPressed: () {
            final r = reason.text.trim();
            if (r.isEmpty) return;
            Navigator.of(context).pop(_OverrideResult(status: status, reason: r));
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
