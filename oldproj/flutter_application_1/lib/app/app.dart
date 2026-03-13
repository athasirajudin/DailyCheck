import 'package:flutter/material.dart';

import '../core/services/session_store.dart';
import 'app_scope.dart';
import 'app_theme.dart';
import '../features/auth/login_screen.dart';
import '../features/home/home_screen.dart';

class AbsensiApp extends StatelessWidget {
  const AbsensiApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return AnimatedBuilder(
      animation: scope.session,
      builder: (context, _) {
        return MaterialApp(
          title: scope.config.appName,
          theme: AppTheme.light(),
          home: _AuthGate(session: scope.session),
        );
      },
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate({required this.session});

  final SessionStore session;

  @override
  Widget build(BuildContext context) {
    final user = session.user;
    if (user == null) {
      return const LoginScreen();
    }
    return HomeScreen(role: user.role);
  }
}

