import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/models/attendance_models.dart';
import '../../core/services/api_client_base.dart';
import '../../core/services/csv_exporter.dart';
import '../../core/ui/app_notice.dart';
import '../admin/admin_style.dart';
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
  bool _exporting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_vm != null) return;
    final scope = AppScope.of(context);
    _vm = MentorRecapViewModel.initial(
      apiClient: scope.apiClient,
      session: scope.session,
    )..start();
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
    _dateFromCtrl.text = vm.dateFrom;
    _dateToCtrl.text = vm.dateTo;
    return Scaffold(
      appBar: AppBar(title: const Text('Rekap Bimbingan')),
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) {
          final internCount = vm.items
              .map((e) => e.internName.trim())
              .where((e) => e.isNotEmpty)
              .toSet()
              .length;
          return AdminPageBackground(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1260),
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    DashboardReveal(
                      delay: const Duration(milliseconds: 40),
                      child: _MentorRecapHeader(
                        totalRecords: vm.items.length,
                        totalIntern: internCount,
                        dateFrom: vm.dateFrom,
                        dateTo: vm.dateTo,
                      ),
                    ),
                    const SizedBox(height: 10),
                    DashboardReveal(
                      delay: const Duration(milliseconds: 100),
                      child: AdminSectionCard(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final compact = constraints.maxWidth < 860;
                            final dateInputs = compact
                                ? Column(
                                    children: [
                                      _dateFromField(vm),
                                      const SizedBox(height: 10),
                                      _dateToField(vm),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      Expanded(child: _dateFromField(vm)),
                                      const SizedBox(width: 12),
                                      Expanded(child: _dateToField(vm)),
                                    ],
                                  );
                            final actions = compact
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: _exporting
                                            ? null
                                            : () => _showExportOptions(
                                                context,
                                                vm,
                                              ),
                                        icon: _exporting
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : const Icon(Icons.download),
                                        label: const Text('Export'),
                                      ),
                                      const SizedBox(height: 8),
                                      FilledButton.icon(
                                        onPressed: vm.loading
                                            ? null
                                            : () => vm.refresh(),
                                        icon: const Icon(Icons.search),
                                        label: const Text('Tampilkan'),
                                      ),
                                    ],
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: _exporting
                                            ? null
                                            : () => _showExportOptions(
                                                context,
                                                vm,
                                              ),
                                        icon: _exporting
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : const Icon(Icons.download),
                                        label: const Text('Export'),
                                      ),
                                      const SizedBox(width: 8),
                                      FilledButton.icon(
                                        onPressed: vm.loading
                                            ? null
                                            : () => vm.refresh(),
                                        icon: const Icon(Icons.search),
                                        label: const Text('Tampilkan'),
                                      ),
                                    ],
                                  );
                            return Column(
                              children: [
                                dateInputs,
                                const SizedBox(height: 12),
                                actions,
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    if (vm.error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          vm.error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    if (vm.summary != null) _SummaryBar(summary: vm.summary!),
                    const SizedBox(height: 10),
                    DashboardReveal(
                      delay: const Duration(milliseconds: 160),
                      child: AdminSectionCard(
                        padding: EdgeInsets.zero,
                        child: vm.loading && vm.items.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 48),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : vm.items.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Text('Belum ada data rekap.'),
                                ),
                              )
                            : ListView.separated(
                                itemCount: vm.items.length,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, i) => _RecapTile(
                                  item: vm.items[i],
                                  onOverride: () =>
                                      _override(context, vm, vm.items[i]),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _dateFromField(MentorRecapViewModel vm) {
    return TextField(
      controller: _dateFromCtrl,
      readOnly: true,
      decoration: const InputDecoration(
        labelText: 'Date From (YYYY-MM-DD)',
        suffixIcon: Icon(Icons.calendar_month_outlined),
      ),
      onTap: () => _pickDateFrom(context, vm),
    );
  }

  Widget _dateToField(MentorRecapViewModel vm) {
    return TextField(
      controller: _dateToCtrl,
      readOnly: true,
      decoration: const InputDecoration(
        labelText: 'Date To (YYYY-MM-DD)',
        suffixIcon: Icon(Icons.calendar_month_outlined),
      ),
      onTap: () => _pickDateTo(context, vm),
    );
  }

  Future<void> _pickDateFrom(
    BuildContext context,
    MentorRecapViewModel vm,
  ) async {
    final now = DateTime.now();
    final picked = await showAdminDatePicker(
      context: context,
      initialDate: _parseDate(vm.dateFrom) ?? now,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2100, 12, 31),
    );
    if (picked == null) return;
    final value = _formatDate(picked);
    _dateFromCtrl.text = value;
    vm.setDateFrom(value);
  }

  Future<void> _pickDateTo(
    BuildContext context,
    MentorRecapViewModel vm,
  ) async {
    final now = DateTime.now();
    final picked = await showAdminDatePicker(
      context: context,
      initialDate: _parseDate(vm.dateTo) ?? now,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2100, 12, 31),
    );
    if (picked == null) return;
    final value = _formatDate(picked);
    _dateToCtrl.text = value;
    vm.setDateTo(value);
  }

  DateTime? _parseDate(String value) {
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }

  String _formatDate(DateTime value) {
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '${value.year}-$m-$d';
  }

  Future<void> _override(
    BuildContext context,
    MentorRecapViewModel vm,
    RecapItem item,
  ) async {
    final res = await showDialog<_OverrideResult>(
      context: context,
      builder: (context) => _OverrideDialog(current: item.status),
    );
    if (res == null) return;
    await vm.overrideStatus(
      attendanceId: item.id,
      status: res.status,
      reason: res.reason,
    );
  }

  Future<void> _showExportOptions(
    BuildContext context,
    MentorRecapViewModel vm,
  ) async {
    final selectedFormat = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.table_view),
              title: const Text('Export CSV'),
              onTap: () => Navigator.of(context).pop('csv'),
            ),
            ListTile(
              leading: const Icon(Icons.grid_on),
              title: const Text('Export Excel'),
              onTap: () => Navigator.of(context).pop('xlsx'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted || selectedFormat == null) return;
    await _export(
      context,
      vm,
      format: selectedFormat,
      mimeType: selectedFormat == 'xlsx'
          ? 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
          : 'text/csv',
    );
  }

  Future<void> _export(
    BuildContext context,
    MentorRecapViewModel vm, {
    required String format,
    required String mimeType,
  }) async {
    setState(() => _exporting = true);
    try {
      final bytes = await vm.exportFile(format: format);
      final message = await exportFileBytes(
        bytes: bytes,
        filename: vm.exportFileName(format: format),
        mimeType: mimeType,
      );
      if (!context.mounted) return;
      AppNotice.show(context, message, type: AppNoticeType.success);
    } on ApiError catch (e) {
      if (!context.mounted) return;
      AppNotice.show(
        context,
        'Export gagal: ${e.message}',
        type: AppNoticeType.error,
      );
    } catch (e) {
      if (!context.mounted) return;
      AppNotice.show(context, 'Export gagal: $e', type: AppNoticeType.error);
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }
}

class _MentorRecapHeader extends StatelessWidget {
  const _MentorRecapHeader({
    required this.totalRecords,
    required this.totalIntern,
    required this.dateFrom,
    required this.dateTo,
  });

  final int totalRecords;
  final int totalIntern;
  final String dateFrom;
  final String dateTo;

  @override
  Widget build(BuildContext context) {
    final isPhone = MediaQuery.sizeOf(context).width < 640;
    return AdminPageHeroPanel(
      icon: Icons.summarize_rounded,
      title: 'Rekap Bimbingan',
      subtitle:
          'Pantau dan export data rekap absensi intern bimbingan pada periode yang dipilih.',
      compactBreakpoint: 920,
      rightPanel: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeaderMetricTile(
            icon: Icons.badge_rounded,
            label: 'Total Data',
            value: totalRecords.toString(),
            compact: isPhone,
          ),
          const SizedBox(height: 8),
          _HeaderMetricTile(
            icon: Icons.groups_rounded,
            label: 'Intern Tercatat',
            value: totalIntern.toString(),
            compact: isPhone,
          ),
          const SizedBox(height: 8),
          _HeaderMetricTile(
            icon: Icons.date_range_rounded,
            label: 'Periode',
            value: '$dateFrom s/d $dateTo',
            compact: isPhone,
          ),
        ],
      ),
    );
  }
}

class _HeaderMetricTile extends StatelessWidget {
  const _HeaderMetricTile({
    required this.icon,
    required this.label,
    required this.value,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 9 : 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6FC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCE4F1)),
      ),
      child: Row(
        children: [
          Icon(icon, size: compact ? 17 : 18, color: adminNavy),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF596376),
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: compact ? 13 : 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E2D44),
              ),
            ),
          ),
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
    Widget chip(String label, int value) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6FC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFDCE4F1)),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: Color(0xFF425063),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(2, 12, 2, 0),
      child: Row(
        children: [
          chip('HADIR', summary.hadir),
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
    final isPhone = MediaQuery.sizeOf(context).width < 640;
    final schoolLabel =
        (item.schoolName == null || item.schoolName!.trim().isEmpty)
        ? '-'
        : item.schoolName!;
    final statusColor = switch (item.status) {
      'HADIR' => const Color(0xFF14735D),
      'IZIN' => const Color(0xFF6B5CC2),
      'SAKIT' => const Color(0xFFAA6B1E),
      'ALPA' => const Color(0xFFB24A48),
      _ => const Color(0xFF546177),
    };
    final statusChip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: statusColor.withValues(alpha: 0.28)),
      ),
      child: Text(
        item.status,
        style: TextStyle(
          color: statusColor,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.fact_check_rounded, color: statusColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.internName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Color(0xFF1E2D44),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.date,
                      style: const TextStyle(
                        color: Color(0xFF5B677A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isPhone)
                IconButton(
                  icon: const Icon(Icons.edit_rounded),
                  onPressed: onOverride,
                  tooltip: 'Override status',
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              statusChip,
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F7FC),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFDCE4F1)),
                ),
                child: Text(
                  'By ${item.markedBy}',
                  style: const TextStyle(
                    color: Color(0xFF556275),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              if (isPhone)
                IconButton(
                  icon: const Icon(Icons.edit_rounded),
                  onPressed: onOverride,
                  tooltip: 'Override status',
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Sekolah: $schoolLabel',
            style: const TextStyle(color: Color(0xFF4F5A6D), height: 1.4),
          ),
          const SizedBox(height: 4),
          Text(
            'IN: ${item.checkInAt ?? '-'} | OUT: ${item.checkOutAt ?? '-'}',
            style: const TextStyle(
              color: Color(0xFF4F5A6D),
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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
  static const List<String> _allowed = ['HADIR', 'ALPA', 'IZIN', 'SAKIT'];
  late String status;
  final reason = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Data lama bisa masih punya status TERLAMBAT; fallback ke HADIR agar dropdown valid.
    status = _allowed.contains(widget.current) ? widget.current : 'HADIR';
  }

  @override
  void dispose() {
    reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminFormDialogShell(
      title: 'Override Status',
      subtitle:
          'Perbarui status rekap dan simpan alasan perubahan untuk audit pembimbing.',
      icon: Icons.edit_calendar_rounded,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: status,
            decoration: adminDialogFieldDecoration(label: 'Status baru'),
            items: const [
              DropdownMenuItem(value: 'HADIR', child: Text('HADIR')),
              DropdownMenuItem(value: 'ALPA', child: Text('ALPA')),
              DropdownMenuItem(value: 'IZIN', child: Text('IZIN')),
              DropdownMenuItem(value: 'SAKIT', child: Text('SAKIT')),
            ],
            onChanged: (v) => setState(() => status = v ?? status),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: reason,
            decoration: adminDialogFieldDecoration(label: 'Alasan (wajib)'),
            minLines: 3,
            maxLines: 5,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            final r = reason.text.trim();
            if (r.isEmpty) return;
            Navigator.of(
              context,
            ).pop(_OverrideResult(status: status, reason: r));
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
