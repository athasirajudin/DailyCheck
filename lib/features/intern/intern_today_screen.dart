import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../admin/admin_style.dart';
import 'intern_today_view_model.dart';

class InternTodayScreen extends StatefulWidget {
  const InternTodayScreen({super.key});

  @override
  State<InternTodayScreen> createState() => _InternTodayScreenState();
}

class _InternTodayScreenState extends State<InternTodayScreen> {
  InternTodayViewModel? _vm;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_vm != null) return;
    final scope = AppScope.of(context);
    _vm = InternTodayViewModel(
      apiClient: scope.apiClient,
      session: scope.session,
    )..start();
  }

  @override
  void dispose() {
    _vm?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = _vm!;
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        if (vm.loading && vm.state == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (vm.error != null && vm.state == null) {
          return Center(child: Text(vm.error!));
        }
        final state = vm.state;
        if (state == null) {
          return const Center(child: Text('Tidak ada data.'));
        }
        final statusLabel = state.status ?? 'BELUM ABSEN';
        final statusColor = _statusColor(statusLabel);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ringkasan Absensi Hari Ini',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E2D44),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetaChip(
                  label: 'Tanggal ${state.date}',
                  icon: Icons.calendar_today_rounded,
                  color: adminNavy,
                ),
                _MetaChip(
                  label: 'Unit ${state.unitName}',
                  icon: Icons.account_balance_rounded,
                  color: const Color(0xFF6B5CC2),
                ),
                _MetaChip(
                  label: statusLabel,
                  icon: Icons.assignment_turned_in_rounded,
                  color: statusColor,
                ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final firstCard = AdminSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Status Kehadiran',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E2D44),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(label: 'Status', value: statusLabel),
                      _InfoRow(
                        label: 'Check-in',
                        value: state.checkInAt ?? '-',
                      ),
                      _InfoRow(
                        label: 'Check-out',
                        value: state.checkOutAt ?? '-',
                      ),
                      if (state.checkoutMissing == true)
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text(
                            'Catatan: checkout belum dilakukan.',
                            style: TextStyle(
                              color: Color(0xFFB24A48),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                );

                final secondCard = AdminSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Jendela Waktu & Geofence',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E2D44),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(
                        label: 'Jam Check-in',
                        value:
                            '${_hhmm(state.checkinWindow.opensAt)} - ${_hhmm(state.checkinWindow.closesAt)}',
                      ),
                      _InfoRow(
                        label: 'Jam Check-out',
                        value:
                            '${_hhmm(state.checkoutWindow.opensAt)} - ${_hhmm(state.checkoutWindow.closesAt)}',
                      ),
                      _InfoRow(
                        label: 'Radius Geofence',
                        value: '${state.geofenceRadiusM.toStringAsFixed(0)} m',
                      ),
                      _InfoRow(
                        label: 'Koordinat Geofence',
                        value:
                            '${state.geofenceLat.toStringAsFixed(6)}, ${state.geofenceLon.toStringAsFixed(6)}',
                      ),
                      if (state.currentLat != null && state.currentLon != null)
                        _InfoRow(
                          label: 'Posisi Saat Ini',
                          value:
                              '${state.currentLat!.toStringAsFixed(6)}, ${state.currentLon!.toStringAsFixed(6)}',
                        ),
                      if (state.distanceM != null)
                        _InfoRow(
                          label: 'Jarak ke Titik',
                          value: '${state.distanceM!.toStringAsFixed(1)} m',
                        ),
                      if (state.isWorkday == false)
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text(
                            'Hari ini libur / bukan hari kerja.',
                            style: TextStyle(
                              color: Color(0xFFB24A48),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                );

                if (constraints.maxWidth >= 900) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: firstCard),
                      const SizedBox(width: 12),
                      Expanded(child: secondCard),
                    ],
                  );
                }
                return Column(
                  children: [firstCard, const SizedBox(height: 12), secondCard],
                );
              },
            ),
          ],
        );
      },
    );
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
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
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
            width: 128,
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
