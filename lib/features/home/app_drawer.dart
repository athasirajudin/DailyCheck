import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/models/app_user.dart';
import '../admin/admin_interns_screen.dart';
import '../admin/admin_mentors_screen.dart';
import '../admin/admin_recap_screen.dart';
import '../admin/admin_schools_screen.dart';
import '../admin/admin_settings_screen.dart';
import '../admin/admin_style.dart';
import '../admin/admin_units_screen.dart';
import '../intern/attendance_check_screen.dart';
import '../intern/leave_request_screen.dart';
import '../mentor/mentor_leave_screen.dart';
import '../mentor/mentor_interns_manage_screen.dart';
import '../mentor/mentor_recap_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final user = scope.session.user!;
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF4F7FC), Color(0xFFE7EEF8)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _DrawerHeaderCard(user: user),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  children: _buildAnimatedMenuItems(context, user),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                child: DashboardReveal(
                  delay: const Duration(milliseconds: 420),
                  child: _AnimatedDrawerItem(
                    icon: Icons.logout_rounded,
                    title: 'Logout',
                    onTap: () {
                      scope.session.clear();
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAnimatedMenuItems(BuildContext context, AppUser user) {
    final items = <_DrawerMenuItemData>[
      if (user.role == UserRole.intern) ...[
        _DrawerMenuItemData(
          icon: Icons.my_location_rounded,
          title: 'Check-in/Out (GPS)',
          onTap: () {
            Navigator.of(context).pop();
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AttendanceCheckScreen()),
            );
          },
        ),
        _DrawerMenuItemData(
          icon: Icons.note_add_rounded,
          title: 'Ajukan Izin/Sakit',
          onTap: () {
            Navigator.of(context).pop();
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LeaveRequestScreen()),
            );
          },
        ),
      ],
      if (user.role == UserRole.pembimbing) ...[
        _DrawerMenuItemData(
          icon: Icons.badge_rounded,
          title: 'Data Intern',
          onTap: () {
            Navigator.of(context).pop();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const MentorInternsManageScreen(),
              ),
            );
          },
        ),
        _DrawerMenuItemData(
          icon: Icons.event_available_rounded,
          title: 'Approval Izin/Sakit',
          onTap: () {
            Navigator.of(context).pop();
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MentorLeaveScreen()),
            );
          },
        ),
        _DrawerMenuItemData(
          icon: Icons.list_alt_rounded,
          title: 'Rekap Bimbingan',
          onTap: () {
            Navigator.of(context).pop();
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MentorRecapScreen()),
            );
          },
        ),
      ],
      if (user.role == UserRole.admin) ...[
        _DrawerMenuItemData(
          icon: Icons.people_rounded,
          title: 'Kelola Intern',
          onTap: () {
            Navigator.of(context).pop();
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AdminInternsScreen()),
            );
          },
        ),
        _DrawerMenuItemData(
          icon: Icons.school_rounded,
          title: 'Kelola Mentor',
          onTap: () {
            Navigator.of(context).pop();
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AdminMentorsScreen()),
            );
          },
        ),
        _DrawerMenuItemData(
          icon: Icons.account_balance_rounded,
          title: 'Data Sekolah PKL',
          onTap: () {
            Navigator.of(context).pop();
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AdminSchoolsScreen()),
            );
          },
        ),
        _DrawerMenuItemData(
          icon: Icons.settings_rounded,
          title: 'Settings',
          onTap: () {
            Navigator.of(context).pop();
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AdminSettingsScreen()),
            );
          },
        ),
        _DrawerMenuItemData(
          icon: Icons.place_rounded,
          title: 'Unit & Geofence',
          onTap: () {
            Navigator.of(context).pop();
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const AdminUnitsScreen()));
          },
        ),
        _DrawerMenuItemData(
          icon: Icons.analytics_rounded,
          title: 'Rekap & Export',
          onTap: () {
            Navigator.of(context).pop();
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const AdminRecapScreen()));
          },
        ),
      ],
    ];
    return List<Widget>.generate(items.length, (index) {
      final item = items[index];
      return DashboardReveal(
        delay: Duration(milliseconds: 120 + (index * 45)),
        child: _AnimatedDrawerItem(
          icon: item.icon,
          title: item.title,
          onTap: item.onTap,
        ),
      );
    });
  }
}

class _DrawerBadgeIcon extends StatefulWidget {
  const _DrawerBadgeIcon();

  @override
  State<_DrawerBadgeIcon> createState() => _DrawerBadgeIconState();
}

class _DrawerBadgeIconState extends State<_DrawerBadgeIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _scale = Tween<double>(
      begin: 0.94,
      end: 1.0,
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
      scale: _scale,
      child: const Icon(Icons.verified_user_rounded, color: Colors.white),
    );
  }
}

class _DrawerMenuItemData {
  const _DrawerMenuItemData({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
}

class _DrawerHeaderCard extends StatefulWidget {
  const _DrawerHeaderCard({required this.user});

  final AppUser user;

  @override
  State<_DrawerHeaderCard> createState() => _DrawerHeaderCardState();
}

class _DrawerHeaderCardState extends State<_DrawerHeaderCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          scale: _pressed ? 0.985 : 1,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [adminNavy, adminBlue],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const _DrawerBadgeIcon(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          userRoleToApi(widget.user.role),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedDrawerItem extends StatefulWidget {
  const _AnimatedDrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  State<_AnimatedDrawerItem> createState() => _AnimatedDrawerItemState();
}

class _AnimatedDrawerItemState extends State<_AnimatedDrawerItem> {
  bool _pressed = false;
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        scale: _pressed ? 0.975 : (_hovering ? 1.01 : 1),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFDDE5F2)),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: widget.onTap,
              onTapDown: (_) => setState(() => _pressed = true),
              onTapUp: (_) => setState(() => _pressed = false),
              onTapCancel: () => setState(() => _pressed = false),
              child: ListTile(
                dense: true,
                leading: AnimatedSlide(
                  duration: const Duration(milliseconds: 120),
                  offset: _pressed
                      ? const Offset(0.08, 0)
                      : const Offset(0, 0),
                  child: Icon(widget.icon, color: adminNavy),
                ),
                title: Text(
                  widget.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2A3D),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
