import 'package:flutter/material.dart';

import '../home/app_drawer.dart';
import 'mentor_create_intern_screen.dart';
import 'mentor_interns_manage_screen.dart';
import 'mentor_pairing_screen.dart';
import 'mentor_leave_screen.dart';
import 'mentor_recap_screen.dart';

class MentorDashboardScreen extends StatelessWidget {
  const MentorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Pembimbing')),
      drawer: const AppDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.person_add_alt_1),
            title: const Text('Daftarkan Intern'),
            subtitle: const Text('Pembimbing bisa buat akun intern (langsung aktif)'),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MentorCreateInternScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.badge),
            title: const Text('Data Intern'),
            subtitle: const Text('Lihat detail + aktif/nonaktif + hapus permanen'),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MentorInternsManageScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.display_settings),
            title: const Text('Pairing Display (QR)'),
            subtitle: const Text('Generate pairing code untuk device display'),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MentorPairingScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.event_available),
            title: const Text('Izin / Sakit (Approval)'),
            subtitle: const Text('Approve/Reject request intern'),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MentorLeaveScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.list_alt),
            title: const Text('Rekap Bimbingan'),
            subtitle: const Text('Lihat absensi intern bimbingan + override status'),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MentorRecapScreen())),
          ),
          const SizedBox(height: 12),
          const Text(
            'Catatan: override status wajib isi alasan, akan tercatat di AuditLog.',
          ),
        ],
      ),
    );
  }
}
