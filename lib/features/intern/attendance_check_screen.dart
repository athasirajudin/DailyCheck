import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/ui/app_notice.dart';
import '../admin/admin_style.dart';
import 'attendance_check_view_model.dart';

class AttendanceCheckScreen extends StatefulWidget {
  const AttendanceCheckScreen({super.key});

  @override
  State<AttendanceCheckScreen> createState() => _AttendanceCheckScreenState();
}

class _AttendanceCheckScreenState extends State<AttendanceCheckScreen> {
  AttendanceCheckViewModel? _vm;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_vm != null) return;
    final scope = AppScope.of(context);
    _vm = AttendanceCheckViewModel(
      apiClient: scope.apiClient,
      session: scope.session,
      location: scope.location,
    )..refresh();
  }

  @override
  void dispose() {
    _vm?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = _vm!;
    return Scaffold(
      appBar: AppBar(title: const Text('Check-in / Check-out')),
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) {
          if (vm.refreshing && vm.meta == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final meta = vm.meta;
          return AdminPageBackground(
            child: RefreshIndicator(
              onRefresh: () => vm.refresh(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(
                  MediaQuery.sizeOf(context).width < 640 ? 12 : 16,
                ),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 980),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (vm.error != null) ...[
                            _ErrorBanner(message: vm.error!),
                            const SizedBox(height: 12),
                          ],
                          if (meta == null)
                            const AdminSectionCard(
                              child: Padding(
                                padding: EdgeInsets.all(6),
                                child: Text(
                                  'Belum ada data absensi hari ini. Tarik layar ke bawah untuk refresh.',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF33415C),
                                  ),
                                ),
                              ),
                            )
                          else ...[
                            _SummaryPanel(meta: meta, vm: vm),
                            const SizedBox(height: 12),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final wide = constraints.maxWidth >= 920;
                                final left = _ScheduleCard(meta: meta);
                                final right = _LocationCard(vm: vm);
                                if (!wide) {
                                  return Column(
                                    children: [
                                      left,
                                      const SizedBox(height: 12),
                                      right,
                                    ],
                                  );
                                }
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: left),
                                    const SizedBox(width: 12),
                                    Expanded(child: right),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            _ActionSection(
                              vm: vm,
                              onSubmit: (action) => _submit(vm, action),
                            ),
                          ],
                          if (vm.lastResult != null) ...[
                            const SizedBox(height: 12),
                            AdminSectionCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Hasil Terakhir',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1E2D44),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _InfoRow(
                                    label: 'Status',
                                    value: vm.lastResult!.status,
                                  ),
                                  _InfoRow(
                                    label: 'Check-in',
                                    value:
                                        vm.lastResult!.attendance.checkInAt ??
                                        '-',
                                  ),
                                  _InfoRow(
                                    label: 'Check-out',
                                    value:
                                        vm.lastResult!.attendance.checkOutAt ??
                                        '-',
                                  ),
                                  _InfoRow(
                                    label: 'Ditandai oleh',
                                    value: vm.lastResult!.attendance.markedBy,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _submit(
    AttendanceCheckViewModel vm,
    AttendanceAction action,
  ) async {
    await vm.submit(action: action);
    if (!mounted) return;
    if (vm.error == null) {
      AppNotice.show(
        context,
        'Berhasil: ${vm.lastResult?.status ?? '-'}',
        type: AppNoticeType.success,
      );
      vm.refresh();
      return;
    }
    AppNotice.show(context, vm.error!, type: AppNoticeType.error);
  }
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({required this.meta, required this.vm});

  final AttendanceCheckMeta meta;
  final AttendanceCheckViewModel vm;

  @override
  Widget build(BuildContext context) {
    final status = meta.attendance?.status ?? 'BELUM_ABSEN';
    final timeNow = _extractTime(meta.serverTime);
    final isPhone = MediaQuery.sizeOf(context).width < 640;
    return AdminPageHeroPanel(
      icon: Icons.fact_check_rounded,
      title: 'Absensi Hari Ini',
      subtitle:
          'Pantau status hadir harian, validasi radius geofence, dan lakukan check-in/check-out dari satu panel.',
      leftPanelFooter: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _SmallBadge(
            icon: Icons.calendar_today_rounded,
            label: meta.date,
            color: Colors.white,
            onDarkBackground: true,
          ),
          _SmallBadge(
            icon: Icons.apartment_rounded,
            label: meta.unitName,
            color: Colors.white,
            onDarkBackground: true,
          ),
          _SmallBadge(
            icon: Icons.assignment_turned_in_rounded,
            label: status,
            color: _statusColor(status),
            onDarkBackground: true,
          ),
          _SmallBadge(
            icon: vm.insideRadius
                ? Icons.gps_fixed_rounded
                : Icons.location_off_rounded,
            label: vm.insideRadius ? 'Dalam Radius' : 'Luar Radius',
            color: vm.insideRadius
                ? const Color(0xFF33D39C)
                : const Color(0xFFFFA29B),
            onDarkBackground: true,
          ),
        ],
      ),
      rightPanel: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminHeroInfoTile(
            icon: Icons.gps_fixed_rounded,
            label: 'Validasi',
            value: 'GPS + Radius',
            compact: isPhone,
          ),
          const SizedBox(height: 10),
          AdminHeroInfoTile(
            icon: Icons.access_time_rounded,
            label: 'Jam Sekarang',
            value: timeNow,
            compact: isPhone,
          ),
          const SizedBox(height: 10),
          AdminHeroInfoTile(
            icon: vm.refreshing ? Icons.sync_rounded : Icons.sync_alt_rounded,
            label: 'Sinkronisasi',
            value: vm.refreshing ? 'Memperbarui' : 'Normal',
            compact: isPhone,
          ),
          const SizedBox(height: 10),
          AdminHeroInfoTile(
            icon: Icons.schedule_rounded,
            label: 'Update Terakhir',
            value: timeNow,
            compact: isPhone,
          ),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.meta});

  final AttendanceCheckMeta meta;

  @override
  Widget build(BuildContext context) {
    final isPhone = MediaQuery.sizeOf(context).width < 640;
    return AdminSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: isPhone ? 44 : 48,
                height: isPhone ? 44 : 48,
                decoration: BoxDecoration(
                  color: adminBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.schedule_rounded,
                  color: adminBlue,
                  size: isPhone ? 24 : 26,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jadwal Absensi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E2D44),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Ringkasan jam kerja dan status hari ini.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF5D6677)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _AttendanceInfoTile(
                icon: Icons.login_rounded,
                label: 'Jam Check-in',
                value:
                    '${_hhmm(meta.checkinWindow.opensAt)} - ${_hhmm(meta.checkinWindow.closesAt)}',
                compact: isPhone,
              ),
              _AttendanceInfoTile(
                icon: Icons.logout_rounded,
                label: 'Jam Check-out',
                value:
                    '${_hhmm(meta.checkoutWindow.opensAt)} - ${_hhmm(meta.checkoutWindow.closesAt)}',
                compact: isPhone,
              ),
              _AttendanceInfoTile(
                icon: Icons.calendar_view_week_rounded,
                label: 'Hari Kerja',
                value: meta.isWorkday ? 'Aktif' : 'Libur / Non-kerja',
                compact: isPhone,
                fullWidth: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.vm});

  final AttendanceCheckViewModel vm;

  @override
  Widget build(BuildContext context) {
    final radius = vm.meta?.geofence.radiusM.toStringAsFixed(0) ?? '-';
    final distance = vm.distanceM == null
        ? 'Belum terdeteksi'
        : '${vm.distanceM!.toStringAsFixed(1)} m';
    final inside = vm.insideRadius;
    final isPhone = MediaQuery.sizeOf(context).width < 640;
    return AdminSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: isPhone ? 44 : 48,
                height: isPhone ? 44 : 48,
                decoration: BoxDecoration(
                  color: inside
                      ? const Color(0xFF13765E).withValues(alpha: 0.12)
                      : const Color(0xFFB24A48).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(
                  inside
                      ? Icons.my_location_rounded
                      : Icons.location_searching_rounded,
                  color: inside
                      ? const Color(0xFF13765E)
                      : const Color(0xFFB24A48),
                  size: isPhone ? 24 : 26,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Validasi Lokasi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E2D44),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Cek posisi kamu terhadap radius geofence unit.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF5D6677)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                inside
                    ? Icons.check_circle_rounded
                    : Icons.warning_amber_rounded,
                color: inside
                    ? const Color(0xFF13765E)
                    : const Color(0xFFB24A48),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  inside
                      ? 'Di dalam radius geofence'
                      : 'Di luar radius geofence',
                  style: TextStyle(
                    color: inside
                        ? const Color(0xFF13765E)
                        : const Color(0xFFB24A48),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _AttendanceInfoTile(
                icon: Icons.social_distance_rounded,
                label: 'Jarak Kamu',
                value: distance,
                compact: isPhone,
              ),
              _AttendanceInfoTile(
                icon: Icons.radar_rounded,
                label: 'Batas Radius',
                value: '$radius m',
                compact: isPhone,
              ),
            ],
          ),
          if (vm.locationError != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF2F1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFD2CF)),
              ),
              child: Text(
                vm.locationError!,
                style: const TextStyle(
                  color: Color(0xFFB24A48),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: vm.loading ? null : () => vm.refreshLocationOnly(),
                icon: const Icon(Icons.my_location_rounded),
                label: const Text('Cek Lokasi'),
              ),
              if (vm.canOpenAppSettings || vm.canOpenLocationSettings)
                TextButton.icon(
                  onPressed: vm.loading
                      ? null
                      : () => vm.openSettingsForLocation(),
                  icon: const Icon(Icons.settings_rounded),
                  label: const Text('Buka Settings'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionSection extends StatelessWidget {
  const _ActionSection({required this.vm, required this.onSubmit});

  final AttendanceCheckViewModel vm;
  final Future<void> Function(AttendanceAction action) onSubmit;

  @override
  Widget build(BuildContext context) {
    final isPhone = MediaQuery.sizeOf(context).width < 640;
    return AdminSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: isPhone ? 44 : 48,
                height: isPhone ? 44 : 48,
                decoration: BoxDecoration(
                  color: adminBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.touch_app_rounded,
                  color: adminBlue,
                  size: isPhone ? 24 : 26,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aksi Absensi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E2D44),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Gunakan tombol yang aktif sesuai status dan jendela waktu absensi.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF5D6677)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 720;
              final checkin = _ActionButtonCard(
                primary: true,
                icon: Icons.login_rounded,
                title: 'Check-in',
                enabled: vm.canCheckIn,
                helperText: vm.checkinBlockedReason,
                onPressed: vm.canCheckIn
                    ? () => onSubmit(AttendanceAction.checkin)
                    : null,
              );
              final checkout = _ActionButtonCard(
                primary: false,
                icon: Icons.logout_rounded,
                title: 'Check-out',
                enabled: vm.canCheckOut,
                helperText: vm.checkoutBlockedReason,
                onPressed: vm.canCheckOut
                    ? () => onSubmit(AttendanceAction.checkout)
                    : null,
              );
              if (!wide) {
                return Column(
                  children: [checkin, const SizedBox(height: 12), checkout],
                );
              }
              return Row(
                children: [
                  Expanded(child: checkin),
                  const SizedBox(width: 12),
                  Expanded(child: checkout),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  const _SmallBadge({
    required this.icon,
    required this.label,
    required this.color,
    this.onDarkBackground = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool onDarkBackground;

  @override
  Widget build(BuildContext context) {
    final foreground = onDarkBackground ? Colors.white : color;
    final fillColor = onDarkBackground
        ? color.withValues(alpha: 0.18)
        : color.withValues(alpha: 0.14);
    final borderColor = onDarkBackground
        ? Colors.white.withValues(alpha: 0.18)
        : color.withValues(alpha: 0.34);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceInfoTile extends StatelessWidget {
  const _AttendanceInfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.compact,
    this.fullWidth = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool compact;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.sizeOf(context).width;
    final width = fullWidth
        ? double.infinity
        : (maxWidth < 720 ? double.infinity : 220.0);
    return Container(
      width: width,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 11 : 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE4F1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: compact ? 36 : 40,
            height: compact ? 36 : 40,
            decoration: BoxDecoration(
              color: adminBlue.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: adminBlue, size: compact ? 18 : 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF69758A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: compact ? 13.5 : 14.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF22324B),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtonCard extends StatelessWidget {
  const _ActionButtonCard({
    required this.primary,
    required this.icon,
    required this.title,
    required this.enabled,
    required this.helperText,
    required this.onPressed,
  });

  final bool primary;
  final IconData icon;
  final String title;
  final bool enabled;
  final String? helperText;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final helper = helperText?.trim();
    final helperVisible = helper != null && helper.isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: primary
            ? adminBlue.withValues(alpha: enabled ? 0.08 : 0.04)
            : const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: primary
              ? adminBlue.withValues(alpha: enabled ? 0.22 : 0.10)
              : const Color(0xFFDCE4F1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: enabled
                    ? (primary ? adminBlue : const Color(0xFF4C5C74))
                    : const Color(0xFF9AA7B8),
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: const Color(0xFF21314B),
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: enabled
                      ? const Color(0xFFE8F4FF)
                      : const Color(0xFFF1F4F8),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: enabled
                        ? adminBlue.withValues(alpha: 0.18)
                        : const Color(0xFFD7DEE8),
                  ),
                ),
                child: Text(
                  enabled ? 'Aktif' : 'Terkunci',
                  style: TextStyle(
                    color: enabled ? adminBlue : const Color(0xFF7C889A),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          primary
              ? FilledButton.icon(
                  onPressed: onPressed,
                  icon: Icon(icon),
                  label: Text(title),
                )
              : OutlinedButton.icon(
                  onPressed: onPressed,
                  icon: Icon(icon),
                  label: Text(title),
                ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: helperVisible
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7FAFF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFDCE4F1)),
                    ),
                    child: Text(
                      helper,
                      style: const TextStyle(
                        color: Color(0xFF5A6372),
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return AdminSectionCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFB24A48)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFB24A48),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 122,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF5A6372),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Text(':  '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF1E2D44),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _hhmm(String ts) {
  if (ts.contains(' ')) {
    final parts = ts.split(' ');
    if (parts.length >= 2 && parts[1].length >= 5) {
      return parts[1].substring(0, 5);
    }
  }
  if (ts.length >= 5) return ts.substring(0, 5);
  return ts;
}

String _extractTime(String serverTime) {
  if (serverTime.contains(' ')) {
    final parts = serverTime.split(' ');
    if (parts.length > 1 && parts[1].length >= 8) {
      return parts[1].substring(0, 8);
    }
    if (parts.length > 1 && parts[1].length >= 5) {
      return parts[1].substring(0, 5);
    }
  }
  if (serverTime.length >= 8) return serverTime.substring(0, 8);
  return serverTime.isEmpty ? '-' : serverTime;
}

Color _statusColor(String status) {
  switch (status.toUpperCase()) {
    case 'HADIR':
      return const Color(0xFF12715C);
    case 'IZIN':
      return const Color(0xFF6B5CC2);
    case 'SAKIT':
      return const Color(0xFFAA6B1E);
    case 'ALPA':
      return const Color(0xFFB24A48);
    default:
      return adminNavy;
  }
}
