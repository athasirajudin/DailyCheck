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
          debugShowCheckedModeBanner: false,
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
    final page = user == null
        ? const LoginScreen(key: ValueKey('guest'))
        : HomeScreen(key: ValueKey('role'), role: user.role);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          fit: StackFit.expand,
          children: [
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      transitionBuilder: (child, animation) {
        final slideAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        final slide = Tween<Offset>(
          begin: const Offset(0.06, 0),
          end: Offset.zero,
        ).animate(slideAnimation);
        return SlideTransition(position: slide, child: child);
      },
      child: KeyedSubtree(
        key: ValueKey(user == null ? 'guest' : user.role.name),
        child: page,
      ),
    );
  }
}
