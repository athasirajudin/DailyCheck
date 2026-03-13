import 'package:flutter/material.dart';

import '../home/app_drawer.dart';
import 'admin_devices_screen.dart';
import 'admin_interns_screen.dart';
import 'admin_pairing_screen.dart';
import 'admin_registration_screen.dart';
import 'admin_recap_screen.dart';
import 'admin_settings_screen.dart';
import 'admin_units_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Admin')),
      drawer: const AppDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.how_to_reg),
            title: const Text('Approval Pendaftaran'),
            subtitle: const Text('Approve/Reject request self-register (PENDING)'),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminRegistrationScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Kelola Intern (CRUD)'),
            subtitle: const Text('Tambah/aktif-nonaktif intern'),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminInternsScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            subtitle: const Text('Jam kerja, toleransi, cutoff, workdays, TTL QR'),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminSettingsScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.place),
            title: const Text('Unit & Geofence'),
            subtitle: const Text('Atur titik lat/lon dan radius meter'),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminUnitsScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.display_settings),
            title: const Text('Pairing Device Display'),
            subtitle: const Text('Generate pairing code untuk kiosk/display'),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminPairingScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.monitor_heart),
            title: const Text('Monitoring Device'),
            subtitle: const Text('Online/Offline via heartbeat'),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminDevicesScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Rekap & Export'),
            subtitle: const Text('Filter + statistik + export CSV'),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminRecapScreen())),
          ),
        ],
      ),
    );
  }
}
