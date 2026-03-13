import 'package:flutter/material.dart';

enum AppNoticeType { success, error, info, warning }

class AppNotice {
  static void show(
    BuildContext context,
    String message, {
    AppNoticeType type = AppNoticeType.info,
    Duration? duration,
    bool replaceCurrent = true,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    if (replaceCurrent) {
      messenger.hideCurrentSnackBar();
    }

    final palette = _palette(type);
    final screenWidth = MediaQuery.maybeOf(context)?.size.width ?? 800;
    final isCompact = screenWidth < 680;

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: duration ?? Duration(seconds: type == AppNoticeType.error ? 4 : 3),
        margin: EdgeInsets.fromLTRB(
          isCompact ? 12 : 20,
          0,
          isCompact ? 12 : 20,
          isCompact ? 12 : 18,
        ),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: palette.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: palette.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  palette.icon,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static _NoticePalette _palette(AppNoticeType type) {
    switch (type) {
      case AppNoticeType.success:
        return const _NoticePalette(
          background: Color(0xFF0F7B63),
          border: Color(0xFF22A586),
          icon: Icons.check_circle_rounded,
        );
      case AppNoticeType.error:
        return const _NoticePalette(
          background: Color(0xFFB43B36),
          border: Color(0xFFD6645F),
          icon: Icons.error_rounded,
        );
      case AppNoticeType.warning:
        return const _NoticePalette(
          background: Color(0xFF9A6617),
          border: Color(0xFFC88B34),
          icon: Icons.warning_rounded,
        );
      case AppNoticeType.info:
        return const _NoticePalette(
          background: Color(0xFF1E467A),
          border: Color(0xFF3A6AA8),
          icon: Icons.info_rounded,
        );
    }
  }
}

class _NoticePalette {
  const _NoticePalette({
    required this.background,
    required this.border,
    required this.icon,
  });

  final Color background;
  final Color border;
  final IconData icon;
}
