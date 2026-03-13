import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../home/app_drawer.dart';
import 'attendance_check_screen.dart';
import 'intern_today_screen.dart';
import 'leave_request_screen.dart';

class InternDashboardScreen extends StatelessWidget {
  const InternDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Intern')),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selamat datang, ${scope.session.user?.fullName ?? '-'}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AttendanceCheckScreen()));
                },
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Check-in / Check-out'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LeaveRequestScreen()));
                },
                icon: const Icon(Icons.note_add),
                label: const Text('Ajukan Izin/Sakit'),
              ),
            ),
            const SizedBox(height: 12),
            const Expanded(child: InternTodayScreen()),
          ],
        ),
      ),
    );
  }
}
