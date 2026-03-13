import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/ui/app_notice.dart';
import 'admin_settings_view_model.dart';
import 'admin_style.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  AdminSettingsViewModel? _vm;

  final _timezone = TextEditingController();
  final _workStart = TextEditingController();
  final _workEnd = TextEditingController();
  final _tolerance = TextEditingController();
  final _cutoff = TextEditingController();
  final _offlineThreshold = TextEditingController();
  final Set<int> _workdays = {1, 2, 3, 4, 5};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_vm != null) return;
    final scope = AppScope.of(context);
    _vm = AdminSettingsViewModel(
      apiClient: scope.apiClient,
      session: scope.session,
    );
    _vm!.load().then((_) {
      final s = _vm!.state;
      if (s == null) return;
      _timezone.text = s.timezone;
      _workStart.text = s.workStartTime;
      _workEnd.text = s.workEndTime;
      _tolerance.text = s.toleranceMinutes.toString();
      _cutoff.text = s.dayCutoffTime;
      _offlineThreshold.text = s.offlineThresholdSeconds.toString();
      _workdays
        ..clear()
        ..addAll(s.workdays);
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _vm?.dispose();
    _timezone.dispose();
    _workStart.dispose();
    _workEnd.dispose();
    _tolerance.dispose();
    _cutoff.dispose();
    _offlineThreshold.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = _vm!;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) {
          return AdminPageBackground(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1260),
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    const _SettingsHero(),
                    const SizedBox(height: 10),
                    if (vm.error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          vm.error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    AdminSectionCard(
                      child: Column(
                        children: [
                          if (vm.loading && vm.state == null)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: LinearProgressIndicator(),
                            ),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth >= 900;
                              if (!isWide) {
                                return Column(
                                  children: [
                                    _buildLeftColumn(vm),
                                    const SizedBox(height: 12),
                                    _buildRightColumn(vm),
                                    const SizedBox(height: 16),
                                    _buildWorkdaysSection(vm),
                                  ],
                                );
                              }
                              return Column(
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: _buildLeftColumn(vm)),
                                      const SizedBox(width: 12),
                                      Expanded(child: _buildRightColumn(vm)),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Center(
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            (constraints.maxWidth - 12) / 2,
                                      ),
                                      child: _buildWorkdaysSection(vm),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 48,
                            child: FilledButton.icon(
                              onPressed: vm.loading ? null : () => _save(vm),
                              icon: const Icon(Icons.save),
                              label: const Text('Simpan Settings'),
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
        },
      ),
    );
  }

  Widget _buildLeftColumn(AdminSettingsViewModel vm) {
    return Column(
      children: [
        TextField(
          controller: _timezone,
          decoration: const InputDecoration(labelText: 'Timezone'),
          enabled: !vm.loading,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _workStart,
          decoration: const InputDecoration(labelText: 'Jam Mulai (HH:MM:SS)'),
          enabled: !vm.loading,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _workEnd,
          decoration: const InputDecoration(
            labelText: 'Jam Selesai (HH:MM:SS)',
          ),
          enabled: !vm.loading,
        ),
      ],
    );
  }

  Widget _buildRightColumn(AdminSettingsViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _tolerance,
          decoration: const InputDecoration(labelText: 'Toleransi (menit)'),
          keyboardType: TextInputType.number,
          enabled: !vm.loading,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _cutoff,
          decoration: const InputDecoration(
            labelText: 'Batas Akhir Hari (HH:MM:SS)',
          ),
          enabled: !vm.loading,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _offlineThreshold,
          decoration: const InputDecoration(labelText: 'Batas Offline (detik)'),
          keyboardType: TextInputType.number,
          enabled: !vm.loading,
        ),
      ],
    );
  }

  Widget _buildWorkdaysSection(AdminSettingsViewModel vm) {
    return _WorkdaysPanel(
      selectedDays: _workdays,
      enabled: !vm.loading,
      onToggle: (day, selected) {
        setState(() {
          if (selected) {
            _workdays.add(day);
          } else {
            _workdays.remove(day);
          }
        });
      },
    );
  }

  Future<void> _save(AdminSettingsViewModel vm) async {
    final tol = int.tryParse(_tolerance.text.trim()) ?? 15;
    final offline = int.tryParse(_offlineThreshold.text.trim()) ?? 120;
    final s = AdminSettingsState(
      timezone: _timezone.text.trim().isEmpty
          ? 'Asia/Jakarta'
          : _timezone.text.trim(),
      workStartTime: _workStart.text.trim().isEmpty
          ? '09:00:00'
          : _workStart.text.trim(),
      workEndTime: _workEnd.text.trim().isEmpty
          ? '17:00:00'
          : _workEnd.text.trim(),
      toleranceMinutes: tol,
      dayCutoffTime: _cutoff.text.trim().isEmpty
          ? '23:59:59'
          : _cutoff.text.trim(),
      workdays: _workdays.toList()..sort(),
      offlineThresholdSeconds: offline,
    );
    await vm.save(s);
    if (!mounted) return;
    if (vm.error == null) {
      AppNotice.show(
        context,
        'Settings tersimpan.',
        type: AppNoticeType.success,
      );
    }
  }
}

class _SettingsHero extends StatelessWidget {
  const _SettingsHero();

  @override
  Widget build(BuildContext context) {
    return const AdminPageHeroPanel(
      icon: Icons.settings_rounded,
      title: 'Konfigurasi Sistem',
      subtitle:
          'Atur timezone, jam kerja, toleransi, cutoff harian, dan threshold offline absensi.',
      rightPanel: _SettingsInfoCard(),
    );
  }
}

class _SettingsInfoCard extends StatelessWidget {
  const _SettingsInfoCard();

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 640;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminHeroInfoTile(
          icon: Icons.schedule_rounded,
          label: 'Format Waktu',
          value: 'HH:MM:SS',
          compact: compact,
        ),
        const SizedBox(height: 8),
        AdminHeroInfoTile(
          icon: Icons.calendar_today_rounded,
          label: 'Workdays',
          value: 'Pilih aktif',
          compact: compact,
        ),
        const SizedBox(height: 8),
        AdminHeroInfoTile(
          icon: Icons.wifi_tethering_error_rounded,
          label: 'Offline Threshold',
          value: 'Detik',
          compact: compact,
        ),
        const SizedBox(height: 8),
        AdminHeroInfoTile(
          icon: Icons.sync_alt_rounded,
          label: 'Sinkronisasi',
          value: 'Manual',
          compact: compact,
        ),
      ],
    );
  }
}

class _WorkdaysPanel extends StatelessWidget {
  const _WorkdaysPanel({
    required this.selectedDays,
    required this.enabled,
    required this.onToggle,
  });

  final Set<int> selectedDays;
  final bool enabled;
  final void Function(int day, bool selected) onToggle;

  static const List<({String label, String shortLabel, int day})> _days = [
    (label: 'Senin', shortLabel: 'Mon', day: 1),
    (label: 'Selasa', shortLabel: 'Tue', day: 2),
    (label: 'Rabu', shortLabel: 'Wed', day: 3),
    (label: 'Kamis', shortLabel: 'Thu', day: 4),
    (label: 'Jumat', shortLabel: 'Fri', day: 5),
    (label: 'Sabtu', shortLabel: 'Sat', day: 6),
    (label: 'Minggu', shortLabel: 'Sun', day: 7),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isPhone = width < 640;
    final activeCount = selectedDays.length;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isPhone ? 14 : 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF7FAFF), Color(0xFFF0F5FD)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD9E2F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: isPhone ? 38 : 42,
                height: isPhone ? 38 : 42,
                decoration: BoxDecoration(
                  color: adminBlue.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calendar_today_rounded,
                  size: 20,
                  color: adminBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Workdays',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E2D44),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pilih hari kerja aktif untuk sistem absensi.',
                      style: TextStyle(
                        fontSize: isPhone ? 12 : 13,
                        color: const Color(0xFF5A6678),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: adminBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$activeCount aktif',
                  style: const TextStyle(
                    color: adminBlue,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              if (!isPhone) {
                return _StretchWorkdayRows(
                  rows: const [
                    [1, 2, 3, 4],
                    [5, 6, 7],
                  ],
                  days: _days,
                  selectedDays: selectedDays,
                  enabled: enabled,
                  compact: false,
                  onToggle: onToggle,
                );
              }
              if (constraints.maxWidth >= 360) {
                return _CenteredWorkdayRows(
                  rows: const [
                    [1, 2, 3],
                    [4, 5],
                    [6, 7],
                  ],
                  days: _days,
                  selectedDays: selectedDays,
                  enabled: enabled,
                  compact: true,
                  onToggle: onToggle,
                );
              }
              return _CenteredWorkdayRows(
                rows: const [
                  [1, 2],
                  [3, 4],
                  [5, 6],
                  [7],
                ],
                days: _days,
                selectedDays: selectedDays,
                enabled: enabled,
                compact: true,
                onToggle: onToggle,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StretchWorkdayRows extends StatelessWidget {
  const _StretchWorkdayRows({
    required this.rows,
    required this.days,
    required this.selectedDays,
    required this.enabled,
    required this.compact,
    required this.onToggle,
  });

  final List<List<int>> rows;
  final List<({String label, String shortLabel, int day})> days;
  final Set<int> selectedDays;
  final bool enabled;
  final bool compact;
  final void Function(int day, bool selected) onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) ...[
          Row(
            children: [
              for (
                var itemIndex = 0;
                itemIndex < rows[rowIndex].length;
                itemIndex++
              ) ...[
                Expanded(child: _buildTile(rows[rowIndex][itemIndex])),
                if (itemIndex != rows[rowIndex].length - 1)
                  const SizedBox(width: 10),
              ],
            ],
          ),
          if (rowIndex != rows.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildTile(int dayNumber) {
    final item = days.firstWhere((entry) => entry.day == dayNumber);
    return _WorkdayTile(
      label: compact ? item.shortLabel : item.label,
      day: item.day,
      width: double.infinity,
      selected: selectedDays.contains(item.day),
      enabled: enabled,
      onTap: () => onToggle(item.day, !selectedDays.contains(item.day)),
    );
  }
}

class _CenteredWorkdayRows extends StatelessWidget {
  const _CenteredWorkdayRows({
    required this.rows,
    required this.days,
    required this.selectedDays,
    required this.enabled,
    required this.compact,
    required this.onToggle,
  });

  final List<List<int>> rows;
  final List<({String label, String shortLabel, int day})> days;
  final Set<int> selectedDays;
  final bool enabled;
  final bool compact;
  final void Function(int day, bool selected) onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (
                var itemIndex = 0;
                itemIndex < rows[rowIndex].length;
                itemIndex++
              ) ...[
                _buildTile(rows[rowIndex][itemIndex]),
                if (itemIndex != rows[rowIndex].length - 1)
                  const SizedBox(width: 10),
              ],
            ],
          ),
          if (rowIndex != rows.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildTile(int dayNumber) {
    final item = days.firstWhere((entry) => entry.day == dayNumber);
    final tileWidth = compact ? 84.0 : 104.0;
    return _WorkdayTile(
      label: compact ? item.shortLabel : item.label,
      day: item.day,
      width: tileWidth,
      selected: selectedDays.contains(item.day),
      enabled: enabled,
      onTap: () => onToggle(item.day, !selectedDays.contains(item.day)),
    );
  }
}

class _WorkdayTile extends StatelessWidget {
  const _WorkdayTile({
    required this.label,
    required this.day,
    required this.width,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final int day;
  final double width;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final compact = width < 84;

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: width,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 12,
          vertical: compact ? 10 : 12,
        ),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE9F0FB) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? adminBlue.withValues(alpha: 0.42)
                : const Color(0xFFD5DFEE),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: adminBlue.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: selected
                    ? adminBlue.withValues(alpha: 0.14)
                    : const Color(0xFFF3F6FC),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                selected ? Icons.check_rounded : Icons.circle_outlined,
                size: 16,
                color: selected ? adminBlue : const Color(0xFF8A95A8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: compact ? 12.5 : 13.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF27364A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
