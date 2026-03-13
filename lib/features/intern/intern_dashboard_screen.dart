import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../admin/admin_style.dart';
import '../home/app_drawer.dart';
import 'attendance_check_screen.dart';
import 'intern_today_screen.dart';
import 'leave_request_screen.dart';

class InternDashboardScreen extends StatelessWidget {
  const InternDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final name = scope.session.user?.fullName ?? '-';
    final email = scope.session.user?.email ?? '-';
    final now = DateTime.now();
    final dateLabel =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Intern')),
      drawer: const AppDrawer(),
      body: AdminPageBackground(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(
            MediaQuery.sizeOf(context).width < 640 ? 12 : 16,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DashboardReveal(
                    delay: const Duration(milliseconds: 40),
                    child: _InternHeroPanel(
                      name: name,
                      email: email,
                      dateLabel: dateLabel,
                    ),
                  ),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 940;
                      if (isWide) {
                        return Row(
                          children: [
                            Expanded(
                              child: DashboardReveal(
                                delay: const Duration(milliseconds: 110),
                                child: _ActionCard(
                                  icon: Icons.my_location_rounded,
                                  title: 'Check-in / Check-out (GPS)',
                                  subtitle:
                                      'Absensi otomatis validasi geofence dan radius.',
                                  tag: 'Realtime',
                                  color: const Color(0xFF14735D),
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const AttendanceCheckScreen(),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DashboardReveal(
                                delay: const Duration(milliseconds: 160),
                                child: _ActionCard(
                                  icon: Icons.note_add_rounded,
                                  title: 'Ajukan Izin / Sakit',
                                  subtitle:
                                      'Kirim request izin/sakit beserta lampiran jika diperlukan.',
                                  tag: 'Approval',
                                  color: const Color(0xFF6B5CC2),
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const LeaveRequestScreen(),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          DashboardReveal(
                            delay: const Duration(milliseconds: 110),
                            child: _ActionCard(
                              icon: Icons.my_location_rounded,
                              title: 'Check-in / Check-out (GPS)',
                              subtitle:
                                  'Absensi otomatis validasi geofence dan radius.',
                              tag: 'Realtime',
                              color: const Color(0xFF14735D),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const AttendanceCheckScreen(),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          DashboardReveal(
                            delay: const Duration(milliseconds: 160),
                            child: _ActionCard(
                              icon: Icons.note_add_rounded,
                              title: 'Ajukan Izin / Sakit',
                              subtitle:
                                  'Kirim request izin/sakit beserta lampiran jika diperlukan.',
                              tag: 'Approval',
                              color: const Color(0xFF6B5CC2),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const LeaveRequestScreen(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  DashboardReveal(
                    delay: const Duration(milliseconds: 210),
                    child: const AdminSectionCard(child: InternTodayScreen()),
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InternHeroPanel extends StatelessWidget {
  const _InternHeroPanel({
    required this.name,
    required this.email,
    required this.dateLabel,
  });

  final String name;
  final String email;
  final String dateLabel;

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
            icon: Icons.person_pin_circle,
            color: Colors.white,
            size: isPhone ? 30 : 34,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Selamat datang, $name',
          maxLines: isPhone ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: isPhone ? 26 : 30,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Lakukan check-in/check-out dan pantau status absensi harian dari dashboard ini.',
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
      _QuickInternTile(icon: Icons.badge_rounded, label: 'Akun', value: email),
      const SizedBox(height: 10),
      _QuickInternTile(
        icon: Icons.calendar_today_rounded,
        label: 'Tanggal',
        value: dateLabel,
      ),
      const SizedBox(height: 10),
      const _QuickInternTile(
        icon: Icons.gps_fixed_rounded,
        label: 'Metode Absensi',
        value: 'Tombol + GPS + Radius',
      ),
      const SizedBox(height: 10),
      const _QuickInternTile(
        icon: Icons.verified_rounded,
        label: 'Validasi',
        value: 'Geofence aktif',
      ),
    ],
  );
}

class _QuickInternTile extends StatelessWidget {
  const _QuickInternTile({
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

class _ActionCard extends StatefulWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String tag;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final isPhone = MediaQuery.sizeOf(context).width < 640;
    final card = AdminSectionCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: widget.onTap,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 560;
            final iconBox = Container(
              width: compact ? 48 : 52,
              height: compact ? 48 : 52,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(widget.icon, color: widget.color),
            );
            final title = Text(
              widget.title,
              maxLines: compact ? 2 : 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isPhone ? 17 : 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E2D44),
              ),
            );
            final subtitle = Text(
              widget.subtitle,
              maxLines: compact ? 3 : 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isPhone ? 12 : 13,
                color: const Color(0xFF5A6372),
                height: 1.35,
              ),
            );
            final tag = Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                widget.tag,
                style: TextStyle(
                  color: widget.color,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            );
            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      iconBox,
                      const SizedBox(width: 10),
                      Expanded(child: title),
                    ],
                  ),
                  const SizedBox(height: 8),
                  subtitle,
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      tag,
                      const Spacer(),
                      Icon(Icons.arrow_forward_rounded, color: widget.color),
                    ],
                  ),
                ],
              );
            }
            return Row(
              children: [
                iconBox,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [title, const SizedBox(height: 5), subtitle],
                  ),
                ),
                const SizedBox(width: 8),
                tag,
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, color: widget.color),
              ],
            );
          },
        ),
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
