import 'package:flutter/material.dart';

import '../../core/models/app_user.dart';
import '../admin/admin_dashboard_screen.dart';
import '../intern/intern_dashboard_screen.dart';
import '../mentor/mentor_dashboard_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    return switch (role) {
      UserRole.intern => const InternDashboardScreen(),
      UserRole.pembimbing => const MentorDashboardScreen(),
      UserRole.admin => const AdminDashboardScreen(),
    };
  }
}
