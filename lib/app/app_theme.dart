import 'package:flutter/material.dart';

class AppTheme {
  static const Color lemhannasNavy = Color(0xFF0A1E3A);
  static const Color lemhannasGold = Color(0xFFC9A227);

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: lemhannasNavy,
      brightness: Brightness.light,
    ).copyWith(primary: lemhannasNavy, secondary: lemhannasGold);

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      splashFactory: InkRipple.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _LemhannasPageTransitionsBuilder(),
          TargetPlatform.iOS: _LemhannasPageTransitionsBuilder(),
          TargetPlatform.fuchsia: _LemhannasPageTransitionsBuilder(),
          TargetPlatform.linux: _LemhannasPageTransitionsBuilder(),
          TargetPlatform.macOS: _LemhannasPageTransitionsBuilder(),
          TargetPlatform.windows: _LemhannasPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          animationDuration: const Duration(milliseconds: 180),
          minimumSize: const WidgetStatePropertyAll(Size(0, 52)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return colorScheme.primary.withValues(alpha: 0.42);
            }
            if (states.contains(WidgetState.pressed)) {
              return _mix(colorScheme.primary, Colors.black, 0.12);
            }
            if (states.contains(WidgetState.hovered)) {
              return _mix(colorScheme.primary, colorScheme.secondary, 0.08);
            }
            return colorScheme.primary;
          }),
          elevation: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return 0;
            if (states.contains(WidgetState.pressed)) return 1;
            if (states.contains(WidgetState.hovered)) return 6;
            return 3;
          }),
          shadowColor: WidgetStatePropertyAll(
            colorScheme.primary.withValues(alpha: 0.24),
          ),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return Colors.white.withValues(alpha: 0.10);
            }
            if (states.contains(WidgetState.hovered)) {
              return Colors.white.withValues(alpha: 0.05);
            }
            return null;
          }),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          animationDuration: const Duration(milliseconds: 180),
          minimumSize: const WidgetStatePropertyAll(Size(0, 52)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          side: WidgetStateProperty.resolveWith((states) {
            final base = colorScheme.primary.withValues(alpha: 0.28);
            if (states.contains(WidgetState.pressed)) {
              return BorderSide(
                color: colorScheme.primary.withValues(alpha: 0.42),
              );
            }
            if (states.contains(WidgetState.hovered)) {
              return BorderSide(
                color: colorScheme.primary.withValues(alpha: 0.55),
              );
            }
            return BorderSide(color: base);
          }),
          foregroundColor: WidgetStatePropertyAll(colorScheme.primary),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return colorScheme.primary.withValues(alpha: 0.08);
            }
            if (states.contains(WidgetState.hovered)) {
              return colorScheme.primary.withValues(alpha: 0.04);
            }
            return Colors.white.withValues(alpha: 0.92);
          }),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return colorScheme.primary.withValues(alpha: 0.08);
            }
            return null;
          }),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          animationDuration: const Duration(milliseconds: 160),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          foregroundColor: WidgetStatePropertyAll(colorScheme.primary),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return colorScheme.primary.withValues(alpha: 0.08);
            }
            if (states.contains(WidgetState.hovered)) {
              return colorScheme.primary.withValues(alpha: 0.05);
            }
            return null;
          }),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          animationDuration: const Duration(milliseconds: 160),
          padding: const WidgetStatePropertyAll(EdgeInsets.all(10)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return colorScheme.primary.withValues(alpha: 0.34);
            }
            return colorScheme.primary;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return colorScheme.primary.withValues(alpha: 0.14);
            }
            if (states.contains(WidgetState.hovered)) {
              return colorScheme.primary.withValues(alpha: 0.08);
            }
            return Colors.transparent;
          }),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return colorScheme.primary.withValues(alpha: 0.10);
            }
            return null;
          }),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
  }

  static Color _mix(Color a, Color b, double t) {
    return Color.lerp(a, b, t) ?? a;
  }
}

class _LemhannasPageTransitionsBuilder extends PageTransitionsBuilder {
  const _LemhannasPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (route.fullscreenDialog) {
      return child;
    }

    final slideAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.07, 0),
        end: Offset.zero,
      ).animate(slideAnimation),
      child: child,
    );
  }
}
