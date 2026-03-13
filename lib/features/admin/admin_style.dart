import 'package:flutter/material.dart';

const Color adminNavy = Color(0xFF0F2F5B);
const Color adminBlue = Color(0xFF1B4D86);
const Color adminGold = Color(0xFFC9A227);

class AdminPageBackground extends StatelessWidget {
  const AdminPageBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF4F7FC), Color(0xFFE7EEF8)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -140,
            right: -120,
            child: _GlowCircle(
              size: 320,
              color: adminNavy.withValues(alpha: 0.10),
            ),
          ),
          Positioned(
            bottom: -140,
            left: -80,
            child: _GlowCircle(
              size: 280,
              color: adminGold.withValues(alpha: 0.14),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class AdminSectionCard extends StatelessWidget {
  const AdminSectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDDE5F2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class AdminPageHeroPanel extends StatelessWidget {
  const AdminPageHeroPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.rightPanel,
    this.leftPanelFooter,
    this.compactBreakpoint = 900,
    this.leftFlex = 3,
    this.rightFlex = 2,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget rightPanel;
  final Widget? leftPanelFooter;
  final double compactBreakpoint;
  final int leftFlex;
  final int rightFlex;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isPhone = screenWidth < 640;
    return AdminSectionCard(
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < compactBreakpoint;
          final leftPanel = Container(
            width: double.infinity,
            padding: EdgeInsets.all(isPhone ? 18 : 24),
            decoration: BoxDecoration(
              borderRadius: compact
                  ? const BorderRadius.only(
                      topLeft: Radius.circular(22),
                      topRight: Radius.circular(22),
                    )
                  : const BorderRadius.only(
                      topLeft: Radius.circular(22),
                      bottomLeft: Radius.circular(22),
                    ),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [adminNavy, adminBlue],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: isPhone ? 56 : 64,
                  height: isPhone ? 56 : 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: isPhone ? 30 : 34,
                  ),
                ),
                SizedBox(height: isPhone ? 12 : 16),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isPhone ? 26 : 32,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: isPhone ? 14 : 16,
                    height: 1.35,
                  ),
                ),
                if (leftPanelFooter != null) ...[
                  SizedBox(height: isPhone ? 12 : 16),
                  leftPanelFooter!,
                ],
              ],
            ),
          );
          final rightContent = Padding(
            padding: EdgeInsets.all(isPhone ? 12 : 16),
            child: rightPanel,
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [leftPanel, rightContent],
            );
          }
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: leftFlex, child: leftPanel),
                Expanded(flex: rightFlex, child: rightContent),
              ],
            ),
          );
        },
      ),
    );
  }
}

class AdminHeroInfoTile extends StatelessWidget {
  const AdminHeroInfoTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 9 : 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6FC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCE4F1)),
      ),
      child: Row(
        children: [
          Icon(icon, size: compact ? 17 : 18, color: adminNavy),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF596376),
              ),
            ),
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: compact ? 13 : 14,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E2D44),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminFormDialogShell extends StatelessWidget {
  const AdminFormDialogShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.content,
    required this.actions,
    this.maxWidth = 560,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget content;
  final List<Widget> actions;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isPhone = size.width < 640;
    final isSmallPhone = size.width < 430;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isSmallPhone ? 12 : (isPhone ? 18 : 24),
        vertical: isPhone ? 16 : 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: size.height * (isPhone ? 0.9 : 0.86),
        ),
        child: AdminSectionCard(
          padding: EdgeInsets.zero,
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(
                    isPhone ? 16 : 20,
                    isPhone ? 16 : 20,
                    isPhone ? 16 : 20,
                    isPhone ? 14 : 16,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [adminNavy, adminBlue],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(22),
                      topRight: Radius.circular(22),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: isPhone ? 46 : 52,
                        height: isPhone ? 46 : 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: isPhone ? 24 : 28,
                        ),
                      ),
                      SizedBox(width: isPhone ? 12 : 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isPhone ? 24 : 28,
                                fontWeight: FontWeight.w900,
                                height: 1.05,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              subtitle,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: isPhone ? 12.5 : 14,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.14),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(42, 42),
                        ),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(isPhone ? 14 : 18),
                  child: content,
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    isPhone ? 14 : 18,
                    0,
                    isPhone ? 14 : 18,
                    isPhone ? 14 : 18,
                  ),
                  child: isPhone
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var i = 0; i < actions.length; i++) ...[
                              actions[i],
                              if (i != actions.length - 1)
                                const SizedBox(height: 10),
                            ],
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            for (var i = 0; i < actions.length; i++) ...[
                              actions[i],
                              if (i != actions.length - 1)
                                const SizedBox(width: 10),
                            ],
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AdminFormSection extends StatelessWidget {
  const AdminFormSection({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.compact = false,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 14 : 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCE4F1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: adminNavy, size: compact ? 18 : 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: compact ? 15 : 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E2D44),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 12 : 14),
          child,
        ],
      ),
    );
  }
}

InputDecoration adminDialogFieldDecoration({
  required String label,
  String? hintText,
  Widget? prefixIcon,
  Widget? suffixIcon,
}) {
  const borderColor = Color(0xFFD5DFEE);
  return InputDecoration(
    labelText: label,
    hintText: hintText,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: const Color(0xFFFDFEFF),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: borderColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: borderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: adminBlue, width: 1.4),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFB24A48)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFB24A48), width: 1.4),
    ),
  );
}

class DashboardReveal extends StatefulWidget {
  const DashboardReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offsetY = 16,
    this.offsetX = 0,
    this.duration = const Duration(milliseconds: 520),
    this.curve = Curves.easeOutCubic,
  });

  final Widget child;
  final Duration delay;
  final double offsetY;
  final double offsetX;
  final Duration duration;
  final Curve curve;

  @override
  State<DashboardReveal> createState() => _DashboardRevealState();
}

class _DashboardRevealState extends State<DashboardReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _fade = CurvedAnimation(parent: _controller, curve: widget.curve);
    _slide = Tween<Offset>(
      begin: Offset(widget.offsetX / 100, widget.offsetY / 100),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
    _start();
  }

  Future<void> _start() async {
    if (widget.delay > Duration.zero) {
      await Future<void>.delayed(widget.delay);
      if (!mounted) return;
    }
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

Future<DateTime?> showAdminDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    builder: (context, child) {
      final base = Theme.of(context);
      return Theme(
        data: base.copyWith(
          colorScheme: base.colorScheme.copyWith(
            primary: adminNavy,
            onPrimary: Colors.white,
            surface: const Color(0xFFF5F7FC),
            onSurface: const Color(0xFF1E2430),
          ),
          datePickerTheme: DatePickerThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            backgroundColor: const Color(0xFFF5F7FC),
            headerBackgroundColor: const Color(0xFFE9EEF8),
            headerForegroundColor: const Color(0xFF273244),
            weekdayStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF2E3440),
            ),
            dayStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Color(0xFF1E2430),
            ),
            todayForegroundColor: WidgetStateProperty.all(adminNavy),
            dayForegroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return Colors.white;
              return const Color(0xFF1E2430);
            }),
            dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return adminNavy;
              if (states.contains(WidgetState.hovered)) {
                return const Color(0xFFE7ECF6);
              }
              return null;
            }),
            dayShape: WidgetStateProperty.all(
              const CircleBorder(side: BorderSide(color: Colors.transparent)),
            ),
            cancelButtonStyle: TextButton.styleFrom(
              foregroundColor: adminNavy,
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
            confirmButtonStyle: TextButton.styleFrom(
              foregroundColor: adminNavy,
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        child: child!,
      );
    },
  );
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
