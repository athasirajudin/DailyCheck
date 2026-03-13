import 'package:flutter/material.dart';

class AppDetailField {
  const AppDetailField({
    required this.label,
    required this.value,
    this.icon = Icons.info_outline_rounded,
  });

  final String label;
  final String value;
  final IconData icon;
}

Future<void> showAppDetailDialog({
  required BuildContext context,
  required String title,
  String? subtitle,
  required List<AppDetailField> fields,
  String closeLabel = 'Tutup',
}) {
  final theme = Theme.of(context);
  final width = MediaQuery.of(context).size.width;
  final maxWidth = width < 600 ? width * 0.92 : 560.0;

  return showDialog<void>(
    context: context,
    builder: (context) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withValues(alpha: 0.85),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.92),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Column(
                    children: fields
                        .map(
                          (field) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F8FF),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFD9E3F2),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    field.icon,
                                    size: 18,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        field.label,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          letterSpacing: 0.3,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF6A7385),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      SelectableText(
                                        field.value,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          height: 1.2,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1F2A3D),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.tonal(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(closeLabel),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Future<void> showAppMessageDialog({
  required BuildContext context,
  required String title,
  required String message,
  String closeLabel = 'Tutup',
}) {
  final theme = Theme.of(context);
  return showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.check_circle_outline_rounded,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SelectableText(
              message,
              style: const TextStyle(
                fontSize: 16,
                height: 1.3,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2A3448),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonal(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(closeLabel),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
