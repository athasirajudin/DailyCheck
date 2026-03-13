import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../home/app_drawer.dart';
import 'admin_dashboard_view_model.dart';
import 'admin_style.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  AdminDashboardViewModel? _vm;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_vm != null) return;
    final scope = AppScope.of(context);
    _vm = AdminDashboardViewModel(
      apiClient: scope.apiClient,
      session: scope.session,
    )..start();
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
      appBar: AppBar(title: const Text('Dashboard Admin')),
      drawer: const AppDrawer(),
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) {
          return AdminPageBackground(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(
                MediaQuery.sizeOf(context).width < 640 ? 12 : 16,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DashboardReveal(
                        delay: const Duration(milliseconds: 40),
                        child: _HeroPanel(vm: vm),
                      ),
                      const SizedBox(height: 14),
                      if (vm.error != null)
                        DashboardReveal(
                          delay: const Duration(milliseconds: 80),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              vm.error!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      if (vm.loading)
                        const DashboardReveal(
                          delay: Duration(milliseconds: 90),
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 30),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        )
                      else ...[
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final cards = _buildStats(vm);
                            final width = constraints.maxWidth;
                            final isPhone = width < 640;
                            final isSmallPhone = width < 430;
                            final columns = width >= 1160
                                ? 4
                                : width >= 860
                                ? 2
                                : width >= 360
                                ? 2
                                : 1;
                            final aspectRatio = switch (columns) {
                              4 => 1.1,
                              2 when isPhone => isSmallPhone ? 0.82 : 0.9,
                              2 => 1.32,
                              _ => width < 460 ? 1.2 : 1.32,
                            };
                            return GridView.builder(
                              itemCount: cards.length,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columns,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: aspectRatio,
                                  ),
                              itemBuilder: (context, index) => DashboardReveal(
                                delay: Duration(
                                  milliseconds: 120 + (index * 55),
                                ),
                                child: _StatCard(
                                  metric: cards[index],
                                  compact: isPhone,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth >= 980) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: DashboardReveal(
                                      delay: const Duration(milliseconds: 230),
                                      child: _WeeklyTrendCard(
                                        points: vm.weeklyTrend,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 2,
                                    child: DashboardReveal(
                                      delay: const Duration(milliseconds: 280),
                                      child: _StatusBreakdownCard(
                                        hadir: vm.weekSummary.hadir,
                                        izin: vm.weekSummary.izin,
                                        sakit: vm.weekSummary.sakit,
                                        alpa: vm.weekSummary.alpa,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }
                            return Column(
                              children: [
                                DashboardReveal(
                                  delay: const Duration(milliseconds: 230),
                                  child: _WeeklyTrendCard(
                                    points: vm.weeklyTrend,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                DashboardReveal(
                                  delay: const Duration(milliseconds: 280),
                                  child: _StatusBreakdownCard(
                                    hadir: vm.weekSummary.hadir,
                                    izin: vm.weekSummary.izin,
                                    sakit: vm.weekSummary.sakit,
                                    alpa: vm.weekSummary.alpa,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 18),
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

  List<_DashboardStat> _buildStats(AdminDashboardViewModel vm) {
    final now = DateTime.now();
    final today = _formatDate(now);
    return <_DashboardStat>[
      _DashboardStat(
        title: 'Total User',
        value: '${vm.totalUsers}',
        subtitle: 'Total akun admin, mentor, dan intern',
        trendLabel: 'Live',
        icon: Icons.people_alt_rounded,
        color: const Color(0xFF265DAD),
        animatedValue: vm.totalUsers,
      ),
      _DashboardStat(
        title: 'User Aktif',
        value: '${vm.activeUsers}',
        subtitle: 'Akun yang sedang aktif',
        trendLabel: 'Live',
        icon: Icons.verified_user_rounded,
        color: const Color(0xFF12715C),
        animatedValue: vm.activeUsers,
      ),
      _DashboardStat(
        title: 'User Non Aktif',
        value: '${vm.nonActiveUsers}',
        subtitle: 'Akun intern yang dinonaktifkan',
        trendLabel: 'Live',
        icon: Icons.person_off_rounded,
        color: const Color(0xFFB24A48),
        animatedValue: vm.nonActiveUsers,
      ),
      _DashboardStat(
        title: 'Total Intern',
        value: '${vm.totalInterns}',
        subtitle: 'Total intern PKL yang terdaftar',
        trendLabel: 'Sinkron',
        icon: Icons.groups_rounded,
        color: const Color(0xFF7E57C2),
        animatedValue: vm.totalInterns,
      ),
      _DashboardStat(
        title: 'Absensi Mingguan',
        value:
            '${vm.weekSummary.hadir + vm.weekSummary.izin + vm.weekSummary.sakit + vm.weekSummary.alpa + vm.weekSummary.terlambat}',
        subtitle: 'Total data absensi 7 hari terakhir',
        trendLabel: 'Realtime',
        icon: Icons.calendar_view_week_rounded,
        color: const Color(0xFFB24A48),
        animatedValue:
            vm.weekSummary.hadir +
            vm.weekSummary.izin +
            vm.weekSummary.sakit +
            vm.weekSummary.alpa +
            vm.weekSummary.terlambat,
      ),
      _DashboardStat(
        title: 'Mentor & Unit',
        value: '${vm.totalMentors} mentor / ${vm.totalUnits} unit',
        subtitle: 'Kapasitas pembimbing dan penempatan intern',
        trendLabel: 'Sinkron',
        icon: Icons.school_rounded,
        color: const Color(0xFF6B5CC2),
      ),
      _DashboardStat(
        title: 'Status Hari Ini',
        value:
            '${vm.todaySummary.hadir + vm.todaySummary.izin + vm.todaySummary.sakit + vm.todaySummary.alpa} data',
        subtitle: 'Ringkasan absensi tanggal $today',
        trendLabel: 'Realtime',
        icon: Icons.fact_check_rounded,
        color: const Color(0xFF12715C),
        animatedValue:
            vm.todaySummary.hadir +
            vm.todaySummary.izin +
            vm.todaySummary.sakit +
            vm.todaySummary.alpa,
        animatedSuffix: ' data',
        statusItems: [
          _InlineStatus(
            'Hadir',
            vm.todaySummary.hadir,
            const Color(0xFF14735D),
          ),
          _InlineStatus('Izin', vm.todaySummary.izin, const Color(0xFF6B5CC2)),
          _InlineStatus(
            'Sakit',
            vm.todaySummary.sakit,
            const Color(0xFFAA6B1E),
          ),
          _InlineStatus('Alpa', vm.todaySummary.alpa, const Color(0xFFB24A48)),
        ],
      ),
      _DashboardStat(
        title: 'Sekolah Terlibat',
        value: '${vm.totalSchools}',
        subtitle: 'Sekolah dengan intern aktif/nonaktif saat ini',
        trendLabel: 'Live',
        icon: Icons.account_balance_rounded,
        color: const Color(0xFF9A6E1D),
        animatedValue: vm.totalSchools,
      ),
    ];
  }

  String _formatDate(DateTime value) {
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '${value.year}-$m-$d';
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.vm});

  final AdminDashboardViewModel vm;

  @override
  Widget build(BuildContext context) {
    return AdminSectionCard(
      padding: const EdgeInsets.all(0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 980;
          final isPhone = constraints.maxWidth < 640;
          return isCompact
              ? Column(
                  children: [
                    _leftPanel(isCompact: true, isPhone: isPhone),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                      child: _rightPanel(isPhone),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _leftPanel(isCompact: false, isPhone: false),
                    ),
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _rightPanel(false),
                      ),
                    ),
                  ],
                );
        },
      ),
    );
  }

  Widget _leftPanel({
    required bool isCompact,
    required bool isPhone,
  }) => Container(
    padding: EdgeInsets.all(isPhone ? 18 : 24),
    decoration: BoxDecoration(
      borderRadius: isCompact
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
          width: isPhone ? 56 : 64,
          height: isPhone ? 56 : 64,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.query_stats_rounded,
            color: Colors.white,
            size: isPhone ? 30 : 34,
          ),
        ),
        SizedBox(height: isPhone ? 12 : 16),
        Text(
          'Statistik Dashboard Admin',
          style: TextStyle(
            color: Colors.white,
            fontSize: isPhone ? 26 : 32,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Data pada dashboard ini otomatis diperbarui berkala. Gunakan drawer untuk akses Kelola Intern, Mentor, Sekolah, Unit, dan Rekap.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.92),
            fontSize: isPhone ? 14 : 16,
            height: 1.35,
          ),
        ),
      ],
    ),
  );

  Widget _rightPanel(bool isPhone) {
    final tileGap = isPhone ? 8.0 : 10.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _QuickStatusTile(
          icon: Icons.menu_open_rounded,
          label: 'Navigasi',
          value: 'Drawer Aktif',
        ),
        SizedBox(height: tileGap),
        _QuickStatusTile(
          icon: Icons.access_time_rounded,
          label: 'Jam Sekarang',
          value: clockNow,
        ),
        SizedBox(height: tileGap),
        _QuickStatusTile(
          icon: vm.refreshing ? Icons.sync_rounded : Icons.sync_alt_rounded,
          label: 'Sinkronisasi',
          value: vm.refreshing ? 'Memperbarui' : 'Normal',
        ),
        SizedBox(height: tileGap),
        _QuickStatusTile(
          icon: Icons.schedule_rounded,
          label: 'Update Terakhir',
          value: updatedLabel,
        ),
      ],
    );
  }

  String get updatedLabel {
    final updatedAt = vm.lastUpdated;
    return updatedAt == null
        ? '-'
        : '${updatedAt.hour.toString().padLeft(2, '0')}:${updatedAt.minute.toString().padLeft(2, '0')}:${updatedAt.second.toString().padLeft(2, '0')}';
  }

  String get clockNow =>
      '${vm.currentTime.hour.toString().padLeft(2, '0')}:${vm.currentTime.minute.toString().padLeft(2, '0')}:${vm.currentTime.second.toString().padLeft(2, '0')}';
}

class _DashboardStat {
  const _DashboardStat({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.trendLabel,
    required this.icon,
    required this.color,
    this.statusItems,
    this.animatedValue,
    this.animatedSuffix = '',
  });

  final String title;
  final String value;
  final String subtitle;
  final String trendLabel;
  final IconData icon;
  final Color color;
  final List<_InlineStatus>? statusItems;
  final int? animatedValue;
  final String animatedSuffix;
}

class _StatCard extends StatefulWidget {
  const _StatCard({required this.metric, required this.compact});

  final _DashboardStat metric;
  final bool compact;

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final metric = widget.metric;
    final hasStatusChips = metric.statusItems?.isNotEmpty ?? false;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isPhone = widget.compact;
    final isSmallPhone = screenWidth < 430;
    final targetScale = _hovered ? 1.012 : 1.0;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        scale: targetScale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, _hovered ? -2 : 0, 0),
          child: AdminSectionCard(
            padding: EdgeInsets.all(isPhone ? 14 : 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final narrowCard = constraints.maxWidth < 190;
                final chipCompact = narrowCard || isPhone;
                final titleFontSize = narrowCard
                    ? 14.5
                    : (isPhone ? 16.0 : 18.0);
                final valueFontSize = narrowCard
                    ? (isSmallPhone ? 18.0 : 20.0)
                    : hasStatusChips
                    ? (isPhone ? 20.0 : 26.0)
                    : (isPhone ? 24.0 : 28.0);
                final subtitleFontSize = narrowCard ? 11.0 : 13.0;
                final subtitleLines = hasStatusChips
                    ? (isPhone ? 1 : 2)
                    : (narrowCard ? 3 : (isPhone ? 3 : 2));
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: narrowCard ? 40 : 48,
                          height: narrowCard ? 40 : 48,
                          decoration: BoxDecoration(
                            color: metric.color.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(
                              narrowCard ? 12 : 14,
                            ),
                          ),
                          child: Icon(
                            metric.icon,
                            color: metric.color,
                            size: narrowCard ? 22 : 26,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: narrowCard ? 8 : 10,
                            vertical: narrowCard ? 4 : 5,
                          ),
                          decoration: BoxDecoration(
                            color: metric.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            metric.trendLabel,
                            style: TextStyle(
                              color: metric.color,
                              fontWeight: FontWeight.w700,
                              fontSize: chipCompact ? 9.5 : 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: hasStatusChips ? 8 : 12),
                    Text(
                      metric.title,
                      maxLines: hasStatusChips && isPhone ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E2D44),
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (metric.animatedValue != null)
                      _AnimatedCountText(
                        value: metric.animatedValue!,
                        suffix: metric.animatedSuffix,
                        color: metric.color,
                        fontSize: valueFontSize,
                      )
                    else
                      Text(
                        metric.value,
                        maxLines: narrowCard ? 3 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: valueFontSize,
                          fontWeight: FontWeight.w900,
                          color: metric.color,
                          height: 1.0,
                        ),
                      ),
                    if (hasStatusChips) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: metric.statusItems!
                            .map(
                              (item) => _InlineStatusChip(
                                item: item,
                                compact: chipCompact,
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    SizedBox(height: hasStatusChips ? 4 : 8),
                    Text(
                      metric.subtitle,
                      maxLines: subtitleLines,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: subtitleFontSize,
                        color: const Color(0xFF5A6372),
                        height: 1.3,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedCountText extends StatelessWidget {
  const _AnimatedCountText({
    required this.value,
    required this.suffix,
    required this.color,
    required this.fontSize,
  });

  final int value;
  final String suffix;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (context, animated, _) {
        final text = '${animated.round()}$suffix';
        return Text(
          text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        );
      },
    );
  }
}

class _InlineStatus {
  const _InlineStatus(this.label, this.count, this.color);

  final String label;
  final int count;
  final Color color;
}

class _InlineStatusChip extends StatelessWidget {
  const _InlineStatusChip({required this.item, this.compact = false});

  final _InlineStatus item;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: item.color.withValues(alpha: 0.36)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item.label,
            style: TextStyle(
              color: item.color,
              fontWeight: FontWeight.w700,
              fontSize: compact ? 10 : 12,
            ),
          ),
          SizedBox(width: compact ? 4 : 6),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 5 : 7,
              vertical: compact ? 1.5 : 2,
            ),
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${item.count}',
              style: TextStyle(
                color: item.color,
                fontWeight: FontWeight.w900,
                fontSize: compact ? 10 : 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyTrendCard extends StatelessWidget {
  const _WeeklyTrendCard({required this.points});

  final List<AdminDailyTrendPoint> points;

  @override
  Widget build(BuildContext context) {
    final values = points.map((p) => p.hadirPercent).toList();
    final maxValue = values.isEmpty
        ? 100.0
        : values.reduce((a, b) => a > b ? a : b).clamp(1.0, 100.0);

    return AdminSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.show_chart_rounded, color: adminNavy),
              SizedBox(width: 8),
              Text(
                'Tren Kehadiran 7 Hari',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: Color(0xFF1E2D44),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Persentase hadir per hari berdasarkan data absensi aktual.',
            style: TextStyle(color: Color(0xFF5D6677), fontSize: 13),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 170,
            child: points.isEmpty
                ? const Center(child: Text('Belum ada data mingguan.'))
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(points.length, (i) {
                      final point = points[i];
                      final ratio = maxValue == 0
                          ? 0.0
                          : point.hadirPercent / maxValue;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                '${point.hadirPercent.toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  color: Color(0xFF445062),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 6),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 350),
                                height: 30 + (ratio * 90),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      adminNavy.withValues(alpha: 0.95),
                                      adminBlue.withValues(alpha: 0.85),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                point.label,
                                style: const TextStyle(
                                  color: Color(0xFF5A6577),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatusBreakdownCard extends StatelessWidget {
  const _StatusBreakdownCard({
    required this.hadir,
    required this.izin,
    required this.sakit,
    required this.alpa,
  });

  final int hadir;
  final int izin;
  final int sakit;
  final int alpa;

  @override
  Widget build(BuildContext context) {
    final items = <_StatusItem>[
      _StatusItem('Hadir', hadir, const Color(0xFF14735D)),
      _StatusItem('Izin', izin, const Color(0xFF6B5CC2)),
      _StatusItem('Sakit', sakit, const Color(0xFFAA6B1E)),
      _StatusItem('Alpa', alpa, const Color(0xFFB24A48)),
    ];
    final total = items.fold<int>(0, (sum, item) => sum + item.value);
    return AdminSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pie_chart_rounded, color: adminNavy),
              SizedBox(width: 8),
              Text(
                'Komposisi Status Mingguan',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: Color(0xFF1E2D44),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Ringkasan status absensi dari 7 hari terakhir.',
            style: TextStyle(color: Color(0xFF5D6677), fontSize: 13),
          ),
          const SizedBox(height: 18),
          Container(
            height: 18,
            decoration: BoxDecoration(
              color: const Color(0xFFE6ECF6),
              borderRadius: BorderRadius.circular(999),
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
              children: items
                  .map(
                    (e) => Expanded(
                      flex: e.value == 0 ? 1 : e.value,
                      child: Container(
                        color: e.value == 0
                            ? e.color.withValues(alpha: 0.20)
                            : e.color,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          ...items.map((e) {
            final percent = total == 0 ? 0 : (e.value / total) * 100;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: e.color,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      e.label,
                      style: const TextStyle(
                        color: Color(0xFF2B3444),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${e.value} (${percent.toStringAsFixed(0)}%)',
                    style: TextStyle(
                      color: e.color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _StatusItem {
  const _StatusItem(this.label, this.value, this.color);

  final String label;
  final int value;
  final Color color;
}

class _QuickStatusTile extends StatelessWidget {
  const _QuickStatusTile({
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6FC),
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
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E2D44),
            ),
          ),
        ],
      ),
    );
  }
}
