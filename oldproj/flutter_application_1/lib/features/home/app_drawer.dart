import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/models/app_user.dart';
import '../admin/admin_devices_screen.dart';
import '../admin/admin_interns_screen.dart';
import '../admin/admin_pairing_screen.dart';
import '../admin/admin_registration_screen.dart';
import '../admin/admin_recap_screen.dart';
import '../admin/admin_settings_screen.dart';
import '../admin/admin_units_screen.dart';
import '../intern/attendance_check_screen.dart';
import '../intern/leave_request_screen.dart';
import '../kiosk/kiosk_screen.dart';
import '../mentor/mentor_leave_screen.dart';
import '../mentor/mentor_recap_screen.dart';
import '../mentor/mentor_create_intern_screen.dart';
import '../mentor/mentor_pairing_screen.dart';
import '../mentor/mentor_interns_manage_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final user = scope.session.user!;
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            ListTile(
              title: Text(user.fullName),
              subtitle: Text('${user.email}\n${userRoleToApi(user.role)}'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Info Koneksi'),
              subtitle: Text(scope.apiClient.baseUrl),
              onTap: () => _showConnectionInfo(context, scope),
            ),
            if (user.role == UserRole.intern) ...[
              ListTile(
                leading: const Icon(Icons.qr_code_scanner),
                title: const Text('Check-in/Out'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AttendanceCheckScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.note_add),
                title: const Text('Ajukan Izin/Sakit'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LeaveRequestScreen()));
                },
              ),
            ],
            if (user.role != UserRole.intern)
              ListTile(
                leading: const Icon(Icons.qr_code),
                title: const Text('Mode Display (Kiosk)'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const KioskScreen()));
                },
              ),
            if (user.role == UserRole.pembimbing) ...[
              ListTile(
                leading: const Icon(Icons.person_add_alt_1),
                title: const Text('Daftarkan Intern'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MentorCreateInternScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.badge),
                title: const Text('Data Intern'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MentorInternsManageScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.display_settings),
                title: const Text('Pairing Display'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MentorPairingScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.event_available),
                title: const Text('Approval Izin/Sakit'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MentorLeaveScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.list_alt),
                title: const Text('Rekap Bimbingan'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MentorRecapScreen()));
                },
              ),
            ],
            if (user.role == UserRole.admin) ...[
              ListTile(
                leading: const Icon(Icons.how_to_reg),
                title: const Text('Approval Pendaftaran'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminRegistrationScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text('Kelola Intern'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminInternsScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminSettingsScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.place),
                title: const Text('Unit & Geofence'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminUnitsScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.display_settings),
                title: const Text('Pairing Device'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminPairingScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.monitor_heart),
                title: const Text('Monitoring Device'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminDevicesScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.analytics),
                title: const Text('Rekap & Export'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminRecapScreen()));
                },
              ),
            ],
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                scope.session.clear();
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showConnectionInfo(BuildContext context, AppScope scope) async {
    final user = scope.session.user;
    final token = scope.session.token;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Info Koneksi'),
        content: SelectableText(
          'API_BASE_URL:\n${scope.apiClient.baseUrl}\n\n'
          'User: ${user?.email ?? '-'}\n'
          'Role: ${user == null ? '-' : userRoleToApi(user.role)}\n'
          'Token: ${token == null ? '(null)' : '(ada)'}',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Tutup')),
        ],
      ),
    );
  }
}
