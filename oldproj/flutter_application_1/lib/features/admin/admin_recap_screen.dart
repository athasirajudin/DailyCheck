import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/models/attendance_models.dart';
import 'admin_recap_view_model.dart';

class AdminRecapScreen extends StatefulWidget {
  const AdminRecapScreen({super.key});

  @override
  State<AdminRecapScreen> createState() => _AdminRecapScreenState();
}

class _AdminRecapScreenState extends State<AdminRecapScreen> {
  AdminRecapViewModel? _vm;
  final _dateFromCtrl = TextEditingController();
  final _dateToCtrl = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_vm != null) return;
    final scope = AppScope.of(context);
    _vm = AdminRecapViewModel(apiClient: scope.apiClient, session: scope.session)..start();
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
        title: const Text('Rekap & Export'),
        actions: [
          IconButton(onPressed: vm.loading ? null : () => vm.refresh(), icon: const Icon(Icons.refresh)),
          IconButton(
            onPressed: () => _showExport(context, vm),
            icon: const Icon(Icons.download),
            tooltip: 'Export CSV',
          ),
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
                            controller: _dateFromCtrl,
                            decoration: const InputDecoration(labelText: 'Date From (YYYY-MM-DD)'),
                            onChanged: (v) => vm.setDateFrom(v.trim()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _dateToCtrl,
                            decoration: const InputDecoration(labelText: 'Date To (YYYY-MM-DD)'),
                            onChanged: (v) => vm.setDateTo(v.trim()),
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
                        ...vm.interns.map((i) => DropdownMenuItem<int?>(value: i.userId, child: Text(i.fullName))),
                      ],
                      onChanged: (v) => vm.setSelectedIntern(v),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      initialValue: vm.selectedSchoolName,
                      decoration: const InputDecoration(labelText: 'Filter Sekolah (opsional)'),
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text('Semua Sekolah')),
                        ...vm.schools.map((name) => DropdownMenuItem<String?>(value: name, child: Text(name))),
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
                        itemBuilder: (context, i) => _RecapTile(item: vm.items[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showExport(BuildContext context, AdminRecapViewModel vm) async {
    final url = vm.exportUrl();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export CSV'),
        content: SelectableText(
          'Buka URL ini di browser (token auth diperlukan; untuk sederhana export via browser desktop):\n\n$url',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Tutup')),
        ],
      ),
    );
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
  const _RecapTile({required this.item});

  final RecapItem item;

  @override
  Widget build(BuildContext context) {
    final schoolLabel = (item.schoolName == null || item.schoolName!.trim().isEmpty) ? '-' : item.schoolName!;
    return ListTile(
      title: Text('${item.internName} - ${item.date}'),
      subtitle: Text(
        'Sekolah: $schoolLabel\nStatus: ${item.status} (by ${item.markedBy})\nIN: ${item.checkInAt ?? '-'} | OUT: ${item.checkOutAt ?? '-'}',
      ),
      isThreeLine: true,
    );
  }
}
