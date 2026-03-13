import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../admin/admin_style.dart';
import '../home/app_drawer.dart';
import 'mentor_dashboard_view_model.dart';
import 'mentor_interns_manage_screen.dart';
import 'mentor_leave_screen.dart';
import 'mentor_recap_screen.dart';

class MentorDashboardScreen extends StatefulWidget {
  const MentorDashboardScreen({super.key});

  @override
  State<MentorDashboardScreen> createState() => _MentorDashboardScreenState();
}

class _MentorDashboardScreenState extends State<MentorDashboardScreen> {
  MentorDashboardViewModel? _vm;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_vm != null) return;
    final scope = AppScope.of(context);
    _vm = MentorDashboardViewModel(
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
    final user = AppScope.of(context).session.user;
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Pembimbing')),
      drawer: const AppDrawer(),
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) {
          final clock =
              '${vm.currentTime.hour.toString().padLeft(2, '0')}:${vm.currentTime.minute.toString().padLeft(2, '0')}:${vm.currentTime.second.toString().padLeft(2, '0')}';
          final updated = vm.lastUpdated == null
              ? '-'
              : '${vm.lastUpdated!.hour.toString().padLeft(2, '0')}:${vm.lastUpdated!.minute.toString().padLeft(2, '0')}:${vm.lastUpdated!.second.toString().padLeft(2, '0')}';

          return AdminPageBackground(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(
                MediaQuery.sizeOf(context).width < 640 ? 12 : 16,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1240),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DashboardReveal(
                        delay: const Duration(milliseconds: 40),
                        child: _MentorHeroPanel(
                          name: user?.fullName ?? '-',
                          email: user?.email ?? '-',
                          clock: clock,
                          updated: updated,
                          refreshing: vm.refreshing,
                        ),
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
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 30),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else ...[
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final cards = <_MentorStat>[
                              _MentorStat(
                                title: 'Intern Bimbingan',
                                value: '${vm.activeInterns}/${vm.totalInterns}',
                                subtitle: 'Intern aktif dari total terdaftar',
                                tag: 'Live',
                                icon: Icons.groups_rounded,
                                color: const Color(0xFF265DAD),
                              ),
                              _MentorStat(
                                title: 'Unit Aktif',
                                value: '${vm.totalUnits}',
                                subtitle: 'Unit penempatan intern bimbingan',
                                tag: 'Sinkron',
                                icon: Icons.account_balance_rounded,
                                color: const Color(0xFF6B5CC2),
                                animatedValue: vm.totalUnits,
                              ),
                              _MentorStat(
                                title: 'Approval Pending',
                                value: '${vm.pendingLeave}',
                                subtitle:
                                    'Pengajuan izin/sakit menunggu validasi',
                                tag: 'Realtime',
                                icon: Icons.pending_actions_rounded,
                                color: const Color(0xFFAA6B1E),
                                animatedValue: vm.pendingLeave,
                              ),
                              _MentorStat(
                                title: 'Absensi Hari Ini',
                                value:
                                    '${vm.todaySummary.hadir + vm.todaySummary.izin + vm.todaySummary.sakit + vm.todaySummary.alpa}',
                                subtitle:
                                    'Data absensi intern bimbingan hari ini',
                                tag: 'Live',
                                icon: Icons.fact_check_rounded,
                                color: const Color(0xFF12715C),
                                animatedValue:
                                    vm.todaySummary.hadir +
                                    vm.todaySummary.izin +
                                    vm.todaySummary.sakit +
                                    vm.todaySummary.alpa,
                              ),
                            ];
                            final width = constraints.maxWidth;
                            final isPhone = width < 640;
                            final isSmallPhone = width < 430;
                            final columns = width >= 1120
                                ? 4
                                : width >= 760
                                ? 2
                                : width >= 360
                                ? 2
                                : 1;
                            final aspectRatio = switch (columns) {
                              4 => 1.15,
                              2 when isPhone => isSmallPhone ? 0.98 : 1.08,
                              2 => 1.35,
                              _ => width < 460 ? 1.28 : 1.4,
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
                              itemBuilder: (context, i) => DashboardReveal(
                                delay: Duration(milliseconds: 120 + (i * 60)),
                                child: _MentorStatCard(
                                  stat: cards[i],
                                  compact: isPhone,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final wide = constraints.maxWidth >= 980;
                            final module = DashboardReveal(
                              delay: const Duration(milliseconds: 240),
                              child: _MentorModuleCard(
                                onInternTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const MentorInternsManageScreen(),
                                  ),
                                ),
                                onLeaveTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const MentorLeaveScreen(),
                                  ),
                                ),
                                onRecapTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const MentorRecapScreen(),
                                  ),
                                ),
                              ),
                            );

                            final status = DashboardReveal(
                              delay: const Duration(milliseconds: 290),
                              child: _MentorStatusCard(
                                hadir: vm.todaySummary.hadir,
                                izin: vm.todaySummary.izin,
                                sakit: vm.todaySummary.sakit,
                                alpa: vm.todaySummary.alpa,
                              ),
                            );

                            if (wide) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 3, child: module),
                                  const SizedBox(width: 12),
                                  Expanded(flex: 2, child: status),
                                ],
                              );
                            }
                            return Column(
                              children: [
                                module,
                                const SizedBox(height: 12),
                                status,
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
}

class _MentorHeroPanel extends StatelessWidget {
  const _MentorHeroPanel({
    required this.name,
    required this.email,
    required this.clock,
    required this.updated,
    required this.refreshing,
  });

  final String name;
  final String email;
  final String clock;
  final String updated;
  final bool refreshing;

  @override
  Widget build(BuildContext context) {
    return AdminSectionCard(
      padding: const EdgeInsets.all(0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 980;
          final isPhone = constraints.maxWidth < 640;
          if (compact) {
            return Column(
              children: [
                _left(isCompact: true, isPhone: isPhone),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: _right,
                ),
              ],
            );
          }
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: _left(isCompact: false, isPhone: false),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _right,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _left({required bool isCompact, required bool isPhone}) => Container(
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
          child: _PulseHeroIcon(
            icon: Icons.school_rounded,
            color: Colors.white,
            size: isPhone ? 30 : 34,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          isPhone ? 'Dashboard Pembimbing' : 'Dashboard Pembimbing, $name',
          style: TextStyle(
            color: Colors.white,
            fontSize: isPhone ? 26 : 31,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (isPhone) ...[
          const SizedBox(height: 6),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          'Pantau intern bimbingan, approval izin/sakit, dan rekap absensi dari satu dashboard.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.92),
            fontSize: isPhone ? 14 : 16,
            height: 1.35,
          ),
        ),
      ],
    ),
  );

  Widget get _right => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _QuickStatusTile(
        icon: Icons.email_rounded,
        label: 'Akun Mentor',
        value: email,
      ),
      const SizedBox(height: 10),
      _QuickStatusTile(
        icon: Icons.access_time_rounded,
        label: 'Jam Sekarang',
        value: clock,
      ),
      const SizedBox(height: 10),
      _QuickStatusTile(
        icon: refreshing ? Icons.sync_rounded : Icons.sync_alt_rounded,
        label: 'Sinkronisasi',
        value: refreshing ? 'Memperbarui' : 'Normal',
      ),
      const SizedBox(height: 10),
      _QuickStatusTile(
        icon: Icons.schedule_rounded,
        label: 'Update Terakhir',
        value: updated,
      ),
    ],
  );
}

class _MentorStat {
  const _MentorStat({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.tag,
    required this.icon,
    required this.color,
    this.animatedValue,
  });

  final String title;
  final String value;
  final String subtitle;
  final String tag;
  final IconData icon;
  final Color color;
  final int? animatedValue;
}

class _MentorStatCard extends StatefulWidget {
  const _MentorStatCard({required this.stat, required this.compact});

  final _MentorStat stat;
  final bool compact;

  @override
  State<_MentorStatCard> createState() => _MentorStatCardState();
}

class _MentorStatCardState extends State<_MentorStatCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final stat = widget.stat;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isPhone = widget.compact;
    final isSmallPhone = screenWidth < 430;
    final card = AdminSectionCard(
      padding: EdgeInsets.all(isPhone ? 14 : 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrowCard = constraints.maxWidth < 190;
          final titleFontSize = narrowCard ? 15.5 : (isPhone ? 16.5 : 18.0);
          final valueFontSize = narrowCard
              ? (isSmallPhone ? 20.0 : 22.0)
              : (isPhone ? 24.0 : 28.0);
          final subtitleLines = narrowCard ? 3 : (isPhone ? 3 : 2);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: narrowCard ? 40 : 48,
                    height: narrowCard ? 40 : 48,
                    decoration: BoxDecoration(
                      color: stat.color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(narrowCard ? 12 : 14),
                    ),
                    child: Icon(
                      stat.icon,
                      color: stat.color,
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
                      color: stat.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      stat.tag,
                      style: TextStyle(
                        color: stat.color,
                        fontWeight: FontWeight.w700,
                        fontSize: narrowCard ? 10 : 11,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: narrowCard ? 10 : 12),
              Text(
                stat.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E2D44),
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 6),
              stat.animatedValue == null
                  ? Text(
                      stat.value,
                      maxLines: narrowCard ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: valueFontSize,
                        fontWeight: FontWeight.w900,
                        color: stat.color,
                        height: 1.0,
                      ),
                    )
                  : _AnimatedValueText(
                      value: stat.animatedValue!,
                      color: stat.color,
                      fontSize: valueFontSize,
                    ),
              const SizedBox(height: 8),
              Text(
                stat.subtitle,
                maxLines: subtitleLines,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: narrowCard ? 12 : 13,
                  color: const Color(0xFF5A6372),
                  height: 1.3,
                ),
              ),
            ],
          );
        },
      ),
    );
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        scale: _hovering ? 1.01 : 1,
        child: card,
      ),
    );
  }
}

class _MentorModuleCard extends StatelessWidget {
  const _MentorModuleCard({
    required this.onInternTap,
    required this.onLeaveTap,
    required this.onRecapTap,
  });

  final VoidCallback onInternTap;
  final VoidCallback onLeaveTap;
  final VoidCallback onRecapTap;

  @override
  Widget build(BuildContext context) {
    return AdminSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.widgets_rounded, color: adminNavy),
              SizedBox(width: 8),
              Text(
                'Modul Pembimbing',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E2D44),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Akses modul inti untuk operasional pembimbing intern.',
            style: TextStyle(color: Color(0xFF5D6677), fontSize: 13),
          ),
          const SizedBox(height: 14),
          _ModuleTile(
            icon: Icons.badge_rounded,
            title: 'Data Intern',
            subtitle: 'Kelola intern yang dibimbing',
            color: const Color(0xFF265DAD),
            onTap: onInternTap,
          ),
          const SizedBox(height: 10),
          _ModuleTile(
            icon: Icons.event_available_rounded,
            title: 'Approval Izin/Sakit',
            subtitle: 'Validasi request intern',
            color: const Color(0xFFAA6B1E),
            onTap: onLeaveTap,
          ),
          const SizedBox(height: 10),
          _ModuleTile(
            icon: Icons.list_alt_rounded,
            title: 'Rekap Bimbingan',
            subtitle: 'Lihat rekap absensi intern bimbingan',
            color: const Color(0xFF12715C),
            onTap: onRecapTap,
          ),
        ],
      ),
    );
  }
}

class _ModuleTile extends StatefulWidget {
  const _ModuleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_ModuleTile> createState() => _ModuleTileState();
}

class _ModuleTileState extends State<_ModuleTile> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final isPhone = MediaQuery.sizeOf(context).width < 460;
    final tile = InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: widget.onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F8FD),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFDEE6F2)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(widget.icon, color: widget.color),
            ),
            SizedBox(width: isPhone ? 8 : 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: isPhone ? 15 : 16,
                      color: Color(0xFF1E2D44),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.subtitle,
                    maxLines: isPhone ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFF5A6372),
                      fontSize: isPhone ? 12 : 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isPhone
                  ? Icons.chevron_right_rounded
                  : Icons.arrow_forward_rounded,
              color: widget.color,
              size: isPhone ? 20 : 24,
            ),
          ],
        ),
      ),
    );
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        scale: _hovering ? 1.01 : 1,
        child: tile,
      ),
    );
  }
}

class _MentorStatusCard extends StatelessWidget {
  const _MentorStatusCard({
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
    final chips = <_StatusChip>[
      _StatusChip('Hadir', hadir, const Color(0xFF14735D)),
      _StatusChip('Izin', izin, const Color(0xFF6B5CC2)),
      _StatusChip('Sakit', sakit, const Color(0xFFAA6B1E)),
      _StatusChip('Alpa', alpa, const Color(0xFFB24A48)),
    ];
    return AdminSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.monitor_heart_rounded, color: adminNavy),
              SizedBox(width: 8),
              Text(
                'Status Hari Ini',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E2D44),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Ringkasan absensi intern bimbingan hari ini.',
            style: TextStyle(color: Color(0xFF5D6677), fontSize: 13),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: chips.map((e) => _StatusBadge(item: e)).toList(),
          ),
        ],
      ),
    );
  }
}

class _StatusChip {
  const _StatusChip(this.label, this.value, this.color);

  final String label;
  final int value;
  final Color color;
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.item});

  final _StatusChip item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: item.color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item.label,
            style: TextStyle(color: item.color, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 7),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(999),
            ),
            child: _AnimatedBadgeValue(value: item.value, color: item.color),
          ),
        ],
      ),
    );
  }
}

class _AnimatedValueText extends StatelessWidget {
  const _AnimatedValueText({
    required this.value,
    required this.color,
    required this.fontSize,
  });

  final int value;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, current, _) => Text(
        '${current.round()}',
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

class _AnimatedBadgeValue extends StatelessWidget {
  const _AnimatedBadgeValue({required this.value, required this.color});

  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (context, current, _) => Text(
        '${current.round()}',
        style: TextStyle(color: color, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _PulseHeroIcon extends StatefulWidget {
  const _PulseHeroIcon({
    required this.icon,
    required this.color,
    required this.size,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  State<_PulseHeroIcon> createState() => _PulseHeroIconState();
}

class _PulseHeroIconState extends State<_PulseHeroIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 1,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: Icon(widget.icon, color: widget.color, size: widget.size),
    );
  }
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
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.96, end: 1),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Container(
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
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E2D44),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
