import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import 'admin_style.dart';
import 'admin_schools_view_model.dart';

class AdminSchoolsScreen extends StatefulWidget {
  const AdminSchoolsScreen({super.key});

  @override
  State<AdminSchoolsScreen> createState() => _AdminSchoolsScreenState();
}

class _AdminSchoolsScreenState extends State<AdminSchoolsScreen> {
  AdminSchoolsViewModel? _vm;
  final TextEditingController _query = TextEditingController();
  final TextEditingController _from = TextEditingController();
  final TextEditingController _to = TextEditingController();
  _QuickPeriod? _selectedQuick = _QuickPeriod.all;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_vm != null) return;
    final scope = AppScope.of(context);
    _vm = AdminSchoolsViewModel(
      apiClient: scope.apiClient,
      session: scope.session,
    )..load();
  }

  @override
  void dispose() {
    _query.dispose();
    _from.dispose();
    _to.dispose();
    _vm?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = _vm!;
    return Scaffold(
      appBar: AppBar(title: const Text('Data Sekolah PKL')),
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) {
          final screenWidth = MediaQuery.sizeOf(context).width;
          final isPhone = screenWidth < 640;
          if (vm.loading && vm.schools.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return AdminPageBackground(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1260),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isPhone ? 10 : 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return AdminPageHeroPanel(
                            icon: Icons.account_balance_rounded,
                            title: 'Data Sekolah PKL',
                            subtitle:
                                'Cari sekolah, filter periode, dan lihat detail intern aktif per sekolah.',
                            compactBreakpoint: 760,
                            rightPanel: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AdminHeroInfoTile(
                                  icon: Icons.apartment_rounded,
                                  label: 'Sekolah',
                                  value: vm.schools.length.toString(),
                                  compact: isPhone,
                                ),
                                const SizedBox(height: 8),
                                AdminHeroInfoTile(
                                  icon: Icons.groups_2_rounded,
                                  label: 'Total Intern',
                                  value: vm.totalInterns.toString(),
                                  compact: isPhone,
                                ),
                                const SizedBox(height: 8),
                                AdminHeroInfoTile(
                                  icon: Icons.filter_alt_rounded,
                                  label: 'Filter Cepat',
                                  value: _selectedQuick == null
                                      ? 'Manual'
                                      : _quickLabel(_selectedQuick!),
                                  compact: isPhone,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      AdminSectionCard(
                        child: Column(
                          children: [
                            TextField(
                              controller: _query,
                              decoration: const InputDecoration(
                                labelText: 'Cari Sekolah',
                                hintText: 'Ketik nama sekolah',
                                prefixIcon: Icon(Icons.search),
                              ),
                              onChanged: vm.setQuery,
                            ),
                            const SizedBox(height: 12),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final compactFilters =
                                    constraints.maxWidth < 720;
                                final fromField = TextField(
                                  controller: _from
                                    ..text = _formatDate(vm.filterFrom),
                                  readOnly: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Periode Dari',
                                    hintText: 'YYYY-MM-DD',
                                    prefixIcon: Icon(Icons.date_range),
                                    suffixIcon: Icon(
                                      Icons.calendar_month_outlined,
                                    ),
                                  ),
                                  onTap: () => _pickDate(
                                    context: context,
                                    initial: vm.filterFrom,
                                    onPicked: vm.setFilterFrom,
                                  ),
                                );
                                final toField = TextField(
                                  controller: _to
                                    ..text = _formatDate(vm.filterTo),
                                  readOnly: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Periode Sampai',
                                    hintText: 'YYYY-MM-DD',
                                    prefixIcon: Icon(Icons.event),
                                    suffixIcon: Icon(
                                      Icons.calendar_month_outlined,
                                    ),
                                  ),
                                  onTap: () => _pickDate(
                                    context: context,
                                    initial: vm.filterTo,
                                    onPicked: vm.setFilterTo,
                                  ),
                                );
                                final resetButton = IconButton(
                                  tooltip: 'Reset periode',
                                  onPressed: () {
                                    vm.clearPeriodFilter();
                                    setState(
                                      () => _selectedQuick = _QuickPeriod.all,
                                    );
                                  },
                                  icon: const Icon(Icons.clear),
                                );

                                if (compactFilters) {
                                  return Column(
                                    children: [
                                      fromField,
                                      const SizedBox(height: 8),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(child: toField),
                                          const SizedBox(width: 8),
                                          resetButton,
                                        ],
                                      ),
                                    ],
                                  );
                                }

                                return Row(
                                  children: [
                                    Expanded(child: fromField),
                                    const SizedBox(width: 8),
                                    Expanded(child: toField),
                                    const SizedBox(width: 8),
                                    resetButton,
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ChoiceChip(
                                  label: const Text('Bulan ini'),
                                  selected:
                                      _selectedQuick == _QuickPeriod.thisMonth,
                                  onSelected: (_) => _applyQuickPeriod(
                                    vm,
                                    _QuickPeriod.thisMonth,
                                  ),
                                ),
                                ChoiceChip(
                                  label: const Text('3 bulan'),
                                  selected:
                                      _selectedQuick ==
                                      _QuickPeriod.last3Months,
                                  onSelected: (_) => _applyQuickPeriod(
                                    vm,
                                    _QuickPeriod.last3Months,
                                  ),
                                ),
                                ChoiceChip(
                                  label: const Text('Semua'),
                                  selected: _selectedQuick == _QuickPeriod.all,
                                  onSelected: (_) =>
                                      _applyQuickPeriod(vm, _QuickPeriod.all),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _SummaryChip(
                                  label: 'Sekolah',
                                  value: vm.schools.length.toString(),
                                ),
                                _SummaryChip(
                                  label: 'Total Intern',
                                  value: vm.totalInterns.toString(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (vm.error != null)
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            vm.error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      if (vm.schools.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 48),
                          child: Center(child: Text('Belum ada data sekolah.')),
                        )
                      else
                        ListView.builder(
                          padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
                          itemCount: vm.schools.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, i) {
                            final school = vm.schools[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: AdminSectionCard(
                                padding: EdgeInsets.zero,
                                child: ListTile(
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: isPhone ? 12 : 16,
                                    vertical: isPhone ? 2 : 4,
                                  ),
                                  title: Text(
                                    school.schoolName,
                                    maxLines: isPhone ? 2 : 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: isPhone ? 16 : null,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${school.interns.length} intern - ${school.activeCount} aktif - ${school.unitCounts.length} unit',
                                    maxLines: isPhone ? 2 : 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  leading: Container(
                                    width: isPhone ? 38 : 42,
                                    height: isPhone ? 38 : 42,
                                    decoration: BoxDecoration(
                                      color: adminBlue.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.account_balance_rounded,
                                      color: adminBlue,
                                    ),
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => _AdminSchoolDetailScreen(
                                        school: school,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '';
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '${value.year}-$m-$d';
  }

  Future<void> _pickDate({
    required BuildContext context,
    required DateTime? initial,
    required ValueChanged<DateTime?> onPicked,
  }) async {
    final now = DateTime.now();
    final picked = await showAdminDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2100, 12, 31),
    );
    if (picked == null) return;
    onPicked(picked);
    setState(() => _selectedQuick = null);
  }

  void _applyQuickPeriod(AdminSchoolsViewModel vm, _QuickPeriod period) {
    final now = DateTime.now();
    if (period == _QuickPeriod.all) {
      vm.clearPeriodFilter();
      setState(() => _selectedQuick = period);
      return;
    }

    if (period == _QuickPeriod.thisMonth) {
      final from = DateTime(now.year, now.month, 1);
      final to = DateTime(now.year, now.month + 1, 0);
      vm.setFilterFrom(from);
      vm.setFilterTo(to);
      setState(() => _selectedQuick = period);
      return;
    }

    final from = DateTime(now.year, now.month - 2, 1);
    final to = DateTime(now.year, now.month + 1, 0);
    vm.setFilterFrom(from);
    vm.setFilterTo(to);
    setState(() => _selectedQuick = period);
  }

  String _quickLabel(_QuickPeriod quick) {
    switch (quick) {
      case _QuickPeriod.thisMonth:
        return 'Bulan ini';
      case _QuickPeriod.last3Months:
        return '3 bulan';
      case _QuickPeriod.all:
        return 'Semua';
    }
  }
}

class _AdminSchoolDetailScreen extends StatelessWidget {
  const _AdminSchoolDetailScreen({required this.school});

  final SchoolInternGroup school;

  @override
  Widget build(BuildContext context) {
    final isPhone = MediaQuery.sizeOf(context).width < 640;
    final mentorCount = school.mentorCounts.length;
    final unitCount = school.unitCounts.length;
    return Scaffold(
      appBar: AppBar(title: Text(school.schoolName)),
      body: AdminPageBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1260),
            child: ListView(
              padding: EdgeInsets.all(isPhone ? 10 : 12),
              children: [
                DashboardReveal(
                  delay: const Duration(milliseconds: 40),
                  child: AdminPageHeroPanel(
                    icon: Icons.account_balance_rounded,
                    title: school.schoolName,
                    subtitle:
                        'Pantau intern PKL, unit penempatan, dan pembimbing yang terhubung ke sekolah ini.',
                    compactBreakpoint: 920,
                    rightPanel: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AdminHeroInfoTile(
                          icon: Icons.groups_2_rounded,
                          label: 'Intern',
                          value: school.interns.length.toString(),
                          compact: isPhone,
                        ),
                        const SizedBox(height: 8),
                        AdminHeroInfoTile(
                          icon: Icons.check_circle_rounded,
                          label: 'Aktif',
                          value: school.activeCount.toString(),
                          compact: isPhone,
                        ),
                        const SizedBox(height: 8),
                        AdminHeroInfoTile(
                          icon: Icons.apartment_rounded,
                          label: 'Unit Terlibat',
                          value: unitCount.toString(),
                          compact: isPhone,
                        ),
                        const SizedBox(height: 8),
                        AdminHeroInfoTile(
                          icon: Icons.support_agent_rounded,
                          label: 'Pembimbing',
                          value: mentorCount.toString(),
                          compact: isPhone,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ...List<Widget>.generate(school.interns.length, (index) {
                  final it = school.interns[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: DashboardReveal(
                      delay: Duration(milliseconds: 90 + (index * 40)),
                      offsetX: 8,
                      child: AdminSectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: isPhone ? 48 : 56,
                                  height: isPhone ? 48 : 56,
                                  decoration: BoxDecoration(
                                    color: adminBlue.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.school_rounded,
                                    color: adminBlue,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        it.fullName,
                                        style: TextStyle(
                                          fontSize: isPhone ? 18 : 20,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF1E2D44),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'NISN ${it.nisn}',
                                        style: const TextStyle(
                                          color: Color(0xFF657388),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _StatusBadge(active: it.active),
                                _UnitBadge(unitName: it.unitName),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(isPhone ? 12 : 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FBFF),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: const Color(0xFFDCE4F1),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Unit: ${it.unitName}',
                                    style: const TextStyle(
                                      color: Color(0xFF4E5A6D),
                                      height: 1.4,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Pembimbing: ${it.mentorName ?? '-'}',
                                    style: const TextStyle(
                                      color: Color(0xFF4E5A6D),
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Periode: ${it.internshipStart} s/d ${it.internshipEnd}',
                                    style: const TextStyle(
                                      color: Color(0xFF4E5A6D),
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5FC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFDCE3F1)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF2B3B54),
          fontSize: 14,
        ),
      ),
    );
  }
}

enum _QuickPeriod { thisMonth, last3Months, all }

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final tone = active ? Colors.green : Colors.red;
    return Chip(
      label: Text(active ? 'Aktif' : 'Nonaktif'),
      labelStyle: TextStyle(color: tone.shade800, fontWeight: FontWeight.w600),
      backgroundColor: tone.shade100,
      side: BorderSide(color: tone.shade300),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _UnitBadge extends StatelessWidget {
  const _UnitBadge({required this.unitName});

  final String unitName;

  static const List<MaterialColor> _palette = [
    Colors.blue,
    Colors.teal,
    Colors.orange,
    Colors.purple,
    Colors.indigo,
    Colors.brown,
    Colors.cyan,
    Colors.deepOrange,
  ];

  @override
  Widget build(BuildContext context) {
    final color =
        _palette[unitName.toUpperCase().hashCode.abs() % _palette.length];
    return Chip(
      label: Text(unitName),
      labelStyle: TextStyle(color: color.shade800, fontWeight: FontWeight.w600),
      backgroundColor: color.shade100,
      side: BorderSide(color: color.shade300),
      visualDensity: VisualDensity.compact,
    );
  }
}
