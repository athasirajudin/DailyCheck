import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/models/attendance_models.dart';
import '../../core/services/api_client_base.dart';
import '../../core/services/csv_exporter.dart';
import '../../core/ui/app_notice.dart';
import 'admin_recap_view_model.dart';
import 'admin_style.dart';

class AdminRecapScreen extends StatefulWidget {
  const AdminRecapScreen({super.key});

  @override
  State<AdminRecapScreen> createState() => _AdminRecapScreenState();
}

class _AdminRecapScreenState extends State<AdminRecapScreen> {
  AdminRecapViewModel? _vm;
  final _dateFromCtrl = TextEditingController();
  final _dateToCtrl = TextEditingController();
  bool _exporting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_vm != null) return;
    final scope = AppScope.of(context);
    _vm = AdminRecapViewModel(
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
      appBar: AppBar(title: const Text('Rekap & Export')),
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) {
          final screenWidth = MediaQuery.sizeOf(context).width;
          final pagePadding = screenWidth < 640 ? 12.0 : 16.0;
          final totalIntern = vm.items
              .map((e) => e.internName.trim())
              .where((e) => e.isNotEmpty)
              .toSet()
              .length;
          return AdminPageBackground(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: ListView(
                  padding: EdgeInsets.all(pagePadding),
                  children: [
                    DashboardReveal(
                      delay: const Duration(milliseconds: 40),
                      child: _RecapHero(
                        totalRecords: vm.items.length,
                        totalIntern: totalIntern,
                        dateFrom: vm.dateFrom,
                        dateTo: vm.dateTo,
                        selectedInternLabel: _selectedInternLabel(vm),
                        selectedSchoolLabel: _selectedSchoolLabel(vm),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DashboardReveal(
                      delay: const Duration(milliseconds: 100),
                      child: _buildFiltersCard(vm),
                    ),
                    if (vm.error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: _ErrorBanner(message: vm.error!),
                      ),
                    if (vm.summary != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: _SummaryBar(summary: vm.summary!),
                      ),
                    const SizedBox(height: 12),
                    DashboardReveal(
                      delay: const Duration(milliseconds: 160),
                      child: AdminSectionCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _RecapListHeader(
                              totalRecords: vm.items.length,
                              loading: vm.loading,
                            ),
                            const Divider(height: 1),
                            if (vm.loading && vm.items.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 48),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else if (vm.items.isEmpty)
                              const _EmptyRecapState()
                            else
                              ListView.separated(
                                padding: const EdgeInsets.all(14),
                                itemCount: vm.items.length,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, i) =>
                                    _RecapTile(item: vm.items[i]),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: pagePadding),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFiltersCard(AdminRecapViewModel vm) {
    return AdminSectionCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 960;
          final actionsCompact = constraints.maxWidth < 720;
          final dateSection = compact
              ? Column(
                  children: [
                    _DateField(
                      controller: _dateFromCtrl,
                      label: 'Tanggal Mulai',
                      onTap: () => _pickDateFrom(context, vm),
                    ),
                    const SizedBox(height: 12),
                    _DateField(
                      controller: _dateToCtrl,
                      label: 'Tanggal Selesai',
                      onTap: () => _pickDateTo(context, vm),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _DateField(
                        controller: _dateFromCtrl,
                        label: 'Tanggal Mulai',
                        onTap: () => _pickDateFrom(context, vm),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DateField(
                        controller: _dateToCtrl,
                        label: 'Tanggal Selesai',
                        onTap: () => _pickDateTo(context, vm),
                      ),
                    ),
                  ],
                );
          final filterSection = compact
              ? Column(
                  children: [
                    _InternDropdown(vm: vm),
                    const SizedBox(height: 12),
                    _SchoolDropdown(vm: vm),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _InternDropdown(vm: vm)),
                    const SizedBox(width: 12),
                    Expanded(child: _SchoolDropdown(vm: vm)),
                  ],
                );
          final actionButtons = actionsCompact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _exporting
                          ? null
                          : () => _showExportOptions(vm),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                      icon: _exporting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download_rounded),
                      label: const Text('Export Rekap'),
                    ),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: vm.loading ? null : vm.refresh,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                      icon: const Icon(Icons.search_rounded),
                      label: const Text('Tampilkan Data'),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _exporting
                          ? null
                          : () => _showExportOptions(vm),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                      ),
                      icon: _exporting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.file_download_outlined),
                      label: const Text('Export'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: vm.loading ? null : vm.refresh,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 14,
                        ),
                      ),
                      icon: const Icon(Icons.auto_graph_rounded),
                      label: const Text('Tampilkan'),
                    ),
                  ],
                );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: adminNavy.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: adminNavy,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Filter Rekap',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E2D44),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Pilih periode, intern, dan sekolah untuk menampilkan rekap yang lebih terarah.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            color: Color(0xFF5B6678),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              AdminFormSection(
                title: 'Periode Rekap',
                icon: Icons.calendar_month_rounded,
                compact: compact,
                child: dateSection,
              ),
              const SizedBox(height: 12),
              AdminFormSection(
                title: 'Penyaring Data',
                icon: Icons.filter_alt_rounded,
                compact: compact,
                child: filterSection,
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _FilterHintChip(
                    icon: Icons.info_outline_rounded,
                    label: 'Rentang aktif',
                    value: '${vm.dateFrom} s/d ${vm.dateTo}',
                  ),
                  _FilterHintChip(
                    icon: Icons.person_search_rounded,
                    label: 'Intern',
                    value: _selectedInternLabel(vm),
                  ),
                  _FilterHintChip(
                    icon: Icons.apartment_rounded,
                    label: 'Sekolah',
                    value: _selectedSchoolLabel(vm),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              actionButtons,
            ],
          );
        },
      ),
    );
  }

  String _selectedInternLabel(AdminRecapViewModel vm) {
    final selectedId = vm.selectedInternUserId;
    if (selectedId == null) return 'Semua Intern';
    for (final intern in vm.interns) {
      if (intern.userId == selectedId) return intern.fullName;
    }
    return 'Intern Terpilih';
  }

  String _selectedSchoolLabel(AdminRecapViewModel vm) {
    final selected = vm.selectedSchoolName?.trim() ?? '';
    if (selected.isEmpty) return 'Semua Sekolah';
    return selected;
  }

  Future<void> _pickDateFrom(
    BuildContext context,
    AdminRecapViewModel vm,
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

  Future<void> _pickDateTo(BuildContext context, AdminRecapViewModel vm) async {
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

  Future<void> _showExportOptions(AdminRecapViewModel vm) async {
    _ExportScope scope = _ExportScope.all;
    String? selectedSchool =
        (vm.selectedSchoolName != null &&
            vm.selectedSchoolName!.trim().isNotEmpty)
        ? vm.selectedSchoolName
        : (vm.schools.isEmpty ? null : vm.schools.first);

    final selected = await showModalBottomSheet<_ExportChoice>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: AdminSectionCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: adminNavy.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.ios_share_rounded,
                          color: adminNavy,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pilih Jenis Export',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E2D44),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Export rekap keseluruhan atau per sekolah dalam format CSV maupun Excel.',
                              style: TextStyle(
                                color: Color(0xFF5B6678),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F9FF),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFDCE4F1)),
                    ),
                    child: Column(
                      children: [
                        _ExportScopeTile(
                          title: 'Rekap seluruh absensi',
                          subtitle:
                              'Semua data pada rentang tanggal yang dipilih.',
                          selected: scope == _ExportScope.all,
                          onTap: () =>
                              setModalState(() => scope = _ExportScope.all),
                        ),
                        const Divider(height: 1),
                        _ExportScopeTile(
                          title: 'Rekap absensi sekolah',
                          subtitle: 'Hanya data untuk satu sekolah tertentu.',
                          selected: scope == _ExportScope.school,
                          onTap: () =>
                              setModalState(() => scope = _ExportScope.school),
                        ),
                      ],
                    ),
                  ),
                  if (scope == _ExportScope.school) ...[
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: selectedSchool,
                      decoration: adminDialogFieldDecoration(
                        label: 'Pilih Sekolah',
                        prefixIcon: const Icon(Icons.apartment_rounded),
                      ),
                      items: vm.schools
                          .map(
                            (name) => DropdownMenuItem<String>(
                              value: name,
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setModalState(() => selectedSchool = v),
                    ),
                  ],
                  const SizedBox(height: 18),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 520;
                      if (compact) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Batal'),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton(
                              onPressed:
                                  scope == _ExportScope.school &&
                                      (selectedSchool == null ||
                                          selectedSchool!.isEmpty)
                                  ? null
                                  : () => Navigator.of(context).pop(
                                      _ExportChoice(
                                        format: 'csv',
                                        schoolName: scope == _ExportScope.school
                                            ? selectedSchool
                                            : null,
                                      ),
                                    ),
                              child: const Text('Export CSV'),
                            ),
                            const SizedBox(height: 10),
                            FilledButton(
                              onPressed:
                                  scope == _ExportScope.school &&
                                      (selectedSchool == null ||
                                          selectedSchool!.isEmpty)
                                  ? null
                                  : () => Navigator.of(context).pop(
                                      _ExportChoice(
                                        format: 'xlsx',
                                        schoolName: scope == _ExportScope.school
                                            ? selectedSchool
                                            : null,
                                      ),
                                    ),
                              child: const Text('Export Excel'),
                            ),
                          ],
                        );
                      }
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Batal'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed:
                                scope == _ExportScope.school &&
                                    (selectedSchool == null ||
                                        selectedSchool!.isEmpty)
                                ? null
                                : () => Navigator.of(context).pop(
                                    _ExportChoice(
                                      format: 'csv',
                                      schoolName: scope == _ExportScope.school
                                          ? selectedSchool
                                          : null,
                                    ),
                                  ),
                            child: const Text('Export CSV'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed:
                                scope == _ExportScope.school &&
                                    (selectedSchool == null ||
                                        selectedSchool!.isEmpty)
                                ? null
                                : () => Navigator.of(context).pop(
                                    _ExportChoice(
                                      format: 'xlsx',
                                      schoolName: scope == _ExportScope.school
                                          ? selectedSchool
                                          : null,
                                    ),
                                  ),
                            child: const Text('Export Excel'),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (!mounted || selected == null) return;
    await _export(
      vm,
      format: selected.format,
      schoolName: selected.schoolName,
      mimeType: selected.format == 'xlsx'
          ? 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
          : 'text/csv',
    );
  }

  Future<void> _export(
    AdminRecapViewModel vm, {
    required String format,
    String? schoolName,
    required String mimeType,
  }) async {
    setState(() => _exporting = true);
    try {
      final bytes = await vm.exportFile(format: format, schoolName: schoolName);
      final message = await exportFileBytes(
        bytes: bytes,
        filename: vm.exportFileName(format: format, schoolName: schoolName),
        mimeType: mimeType,
      );
      if (!mounted) return;
      AppNotice.show(context, message, type: AppNoticeType.success);
    } on ApiError catch (e) {
      if (!mounted) return;
      AppNotice.show(
        context,
        'Export gagal: ${e.message}',
        type: AppNoticeType.error,
      );
    } catch (e) {
      if (!mounted) return;
      AppNotice.show(context, 'Export gagal: $e', type: AppNoticeType.error);
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }
}

enum _ExportScope { all, school }

class _ExportChoice {
  const _ExportChoice({required this.format, this.schoolName});

  final String format;
  final String? schoolName;
}

class _ExportScopeTile extends StatelessWidget {
  const _ExportScopeTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? adminNavy.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? adminNavy : const Color(0xFFA4B0C4),
                  width: 2,
                ),
              ),
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: selected ? 10 : 0,
                  height: selected ? 10 : 0,
                  decoration: const BoxDecoration(
                    color: adminNavy,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E2D44),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF5B6678),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecapHero extends StatelessWidget {
  const _RecapHero({
    required this.totalRecords,
    required this.totalIntern,
    required this.dateFrom,
    required this.dateTo,
    required this.selectedInternLabel,
    required this.selectedSchoolLabel,
  });

  final int totalRecords;
  final int totalIntern;
  final String dateFrom;
  final String dateTo;
  final String selectedInternLabel;
  final String selectedSchoolLabel;

  @override
  Widget build(BuildContext context) {
    return AdminSectionCard(
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 960;
          final leftPanel = Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: compact
                  ? const BorderRadius.only(
                      topLeft: Radius.circular(22),
                      topRight: Radius.circular(22),
                    )
                  : const BorderRadius.only(
                      topLeft: Radius.circular(22),
                      bottomLeft: Radius.circular(22),
                    ),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [adminNavy, adminBlue],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.analytics_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Rekap Absensi Intern',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tampilan rekap dibuat untuk membaca data lebih cepat, tetap selaras dengan background admin, dan siap diexport ke CSV maupun Excel.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 14.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _HeroTagChip(
                      icon: Icons.date_range_rounded,
                      text: '$dateFrom s/d $dateTo',
                    ),
                    _HeroTagChip(
                      icon: Icons.person_outline_rounded,
                      text: selectedInternLabel,
                    ),
                    _HeroTagChip(
                      icon: Icons.apartment_rounded,
                      text: selectedSchoolLabel,
                    ),
                  ],
                ),
              ],
            ),
          );
          final rightPanel = Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _HeaderMetricTile(
                  icon: Icons.inventory_2_rounded,
                  label: 'Total Data',
                  value: totalRecords.toString(),
                ),
                const SizedBox(height: 10),
                _HeaderMetricTile(
                  icon: Icons.groups_rounded,
                  label: 'Intern Tercatat',
                  value: totalIntern.toString(),
                ),
                const SizedBox(height: 10),
                _HeaderMetricTile(
                  icon: Icons.date_range_rounded,
                  label: 'Periode',
                  value: '$dateFrom s/d $dateTo',
                ),
              ],
            ),
          );
          if (compact) {
            return Column(children: [leftPanel, rightPanel]);
          }
          return Row(
            children: [
              Expanded(flex: 3, child: leftPanel),
              Expanded(flex: 2, child: rightPanel),
            ],
          );
        },
      ),
    );
  }
}

class _HeaderMetricTile extends StatelessWidget {
  const _HeaderMetricTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCE4F1)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: adminNavy),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
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
              style: const TextStyle(
                fontSize: 14,
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

class _HeroTagChip extends StatelessWidget {
  const _HeroTagChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.controller,
    required this.label,
    required this.onTap,
  });

  final TextEditingController controller;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: true,
      decoration: adminDialogFieldDecoration(
        label: label,
        prefixIcon: const Icon(Icons.calendar_today_rounded),
        suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
      ),
      onTap: onTap,
    );
  }
}

class _InternDropdown extends StatelessWidget {
  const _InternDropdown({required this.vm});

  final AdminRecapViewModel vm;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int?>(
      initialValue: vm.selectedInternUserId,
      isExpanded: true,
      decoration: adminDialogFieldDecoration(
        label: 'Filter Intern (opsional)',
        prefixIcon: const Icon(Icons.person_search_rounded),
      ),
      items: [
        const DropdownMenuItem<int?>(
          value: null,
          child: Text(
            'Semua Intern',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        ...vm.interns.map(
          (i) => DropdownMenuItem<int?>(
            value: i.userId,
            child: Text(
              i.fullName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
      onChanged: (v) => vm.setSelectedIntern(v),
    );
  }
}

class _SchoolDropdown extends StatelessWidget {
  const _SchoolDropdown({required this.vm});

  final AdminRecapViewModel vm;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      initialValue: vm.selectedSchoolName,
      isExpanded: true,
      decoration: adminDialogFieldDecoration(
        label: 'Filter Sekolah (opsional)',
        prefixIcon: const Icon(Icons.apartment_rounded),
      ),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text(
            'Semua Sekolah',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        ...vm.schools.map(
          (name) => DropdownMenuItem<String?>(
            value: name,
            child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: (v) => vm.setSelectedSchool(v),
    );
  }
}

class _FilterHintChip extends StatelessWidget {
  const _FilterHintChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FD),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFDCE4F1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: adminNavy),
          const SizedBox(width: 7),
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF425063),
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240),
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF596376),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0C7BF)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFB24A48)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF8E3A39),
                fontWeight: FontWeight.w700,
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
    final items = <_SummaryItem>[
      _SummaryItem(
        label: 'Hadir',
        value: summary.hadir,
        icon: Icons.check_circle_rounded,
        color: const Color(0xFF14735D),
      ),
      _SummaryItem(
        label: 'Izin',
        value: summary.izin,
        icon: Icons.assignment_turned_in_rounded,
        color: const Color(0xFF6B5CC2),
      ),
      _SummaryItem(
        label: 'Sakit',
        value: summary.sakit,
        icon: Icons.healing_rounded,
        color: const Color(0xFFAA6B1E),
      ),
      _SummaryItem(
        label: 'Alpa',
        value: summary.alpa,
        icon: Icons.cancel_rounded,
        color: const Color(0xFFB24A48),
      ),
      _SummaryItem(
        label: 'Checkout',
        value: summary.checkoutMissing,
        icon: Icons.logout_rounded,
        color: const Color(0xFF546177),
      ),
      if (summary.terlambat > 0)
        _SummaryItem(
          label: 'Terlambat',
          value: summary.terlambat,
          icon: Icons.schedule_rounded,
          color: const Color(0xFF8B5A13),
        ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _SummaryChip(item: items[i]),
            if (i != items.length - 1) const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

class _SummaryItem {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.item});

  final _SummaryItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: item.color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(item.icon, color: item.color, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF5B6678),
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${item.value}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: item.color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecapListHeader extends StatelessWidget {
  const _RecapListHeader({required this.totalRecords, required this.loading});

  final int totalRecords;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF9FBFF), Color(0xFFF2F6FD)],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: adminNavy.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.receipt_long_rounded, color: adminNavy),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daftar Rekap Absensi',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E2D44),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Setiap kartu menampilkan sekolah, unit, status, pencatat, serta jam check-in dan check-out.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: Color(0xFF5B6678),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFDCE4F1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (loading) ...[
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  '$totalRecords data',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E2D44),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyRecapState extends StatelessWidget {
  const _EmptyRecapState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: adminNavy.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inbox_rounded,
                size: 38,
                color: adminNavy,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Belum ada data rekap',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E2D44),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Ubah rentang tanggal atau filter, lalu tekan tombol Tampilkan untuk memuat data.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF5B6678), height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecapTile extends StatelessWidget {
  const _RecapTile({required this.item});

  final RecapItem item;

  @override
  Widget build(BuildContext context) {
    final status = _statusPresentation(item.status, item.checkoutMissing);
    final schoolLabel =
        (item.schoolName == null || item.schoolName!.trim().isEmpty)
        ? '-'
        : item.schoolName!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: status.color.withValues(alpha: 0.18)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _RecapTileHeader(item: item, status: status),
                    const SizedBox(height: 12),
                    _RecapTileBody(
                      item: item,
                      schoolLabel: schoolLabel,
                      status: status,
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _RecapTileHeader(item: item, status: status),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _RecapTileBody(
                        item: item,
                        schoolLabel: schoolLabel,
                        status: status,
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _RecapTileHeader extends StatelessWidget {
  const _RecapTileHeader({required this.item, required this.status});

  final RecapItem item;
  final _StatusPresentation status;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: status.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(status.icon, color: status.color),
          ),
          const SizedBox(height: 12),
          Text(
            item.internName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E2D44),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.date,
            style: const TextStyle(
              color: Color(0xFF596376),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecapTileBody extends StatelessWidget {
  const _RecapTileBody({
    required this.item,
    required this.schoolLabel,
    required this.status,
  });

  final RecapItem item;
  final String schoolLabel;
  final _StatusPresentation status;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _StatusBadge(status: status),
            if (item.checkoutMissing)
              const _MiniBadge(
                label: 'Checkout belum ada',
                color: Color(0xFF8B5A13),
                icon: Icons.schedule_rounded,
              ),
            _MiniBadge(
              label: 'By ${item.markedBy}',
              color: const Color(0xFF546177),
              icon: Icons.edit_note_rounded,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _InfoPill(
              icon: Icons.school_rounded,
              label: 'Sekolah',
              value: schoolLabel,
            ),
            _InfoPill(
              icon: Icons.account_tree_rounded,
              label: 'Unit',
              value: item.unitName.trim().isEmpty ? '-' : item.unitName,
            ),
            _InfoPill(
              icon: Icons.login_rounded,
              label: 'Check In',
              value: item.checkInAt ?? '-',
            ),
            _InfoPill(
              icon: Icons.logout_rounded,
              label: 'Check Out',
              value: item.checkOutAt ?? '-',
            ),
          ],
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final _StatusPresentation status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: status.color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 16, color: status.color),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(color: status.color, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCE4F1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: adminNavy),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF5B6678),
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E2D44),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPresentation {
  const _StatusPresentation({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;
}

_StatusPresentation _statusPresentation(String value, bool checkoutMissing) {
  final status = value.trim().toUpperCase();
  if (checkoutMissing && status == 'HADIR') {
    return const _StatusPresentation(
      label: 'HADIR / MENUNGGU CHECKOUT',
      color: Color(0xFF8B5A13),
      icon: Icons.pending_actions_rounded,
    );
  }
  switch (status) {
    case 'HADIR':
      return const _StatusPresentation(
        label: 'HADIR',
        color: Color(0xFF14735D),
        icon: Icons.check_circle_rounded,
      );
    case 'IZIN':
      return const _StatusPresentation(
        label: 'IZIN',
        color: Color(0xFF6B5CC2),
        icon: Icons.assignment_turned_in_rounded,
      );
    case 'SAKIT':
      return const _StatusPresentation(
        label: 'SAKIT',
        color: Color(0xFFAA6B1E),
        icon: Icons.healing_rounded,
      );
    case 'ALPA':
      return const _StatusPresentation(
        label: 'ALPA',
        color: Color(0xFFB24A48),
        icon: Icons.cancel_rounded,
      );
    case 'TERLAMBAT':
      return const _StatusPresentation(
        label: 'TERLAMBAT',
        color: Color(0xFF8B5A13),
        icon: Icons.schedule_rounded,
      );
    default:
      return const _StatusPresentation(
        label: 'TIDAK DIKETAHUI',
        color: Color(0xFF546177),
        icon: Icons.help_outline_rounded,
      );
  }
}
