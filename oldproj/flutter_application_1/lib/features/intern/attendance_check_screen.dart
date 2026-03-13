import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../app/app_scope.dart';
import 'attendance_check_view_model.dart';

class AttendanceCheckScreen extends StatefulWidget {
  const AttendanceCheckScreen({super.key});

  @override
  State<AttendanceCheckScreen> createState() => _AttendanceCheckScreenState();
}

class _AttendanceCheckScreenState extends State<AttendanceCheckScreen> {
  AttendanceCheckViewModel? _vm;
  final _manualToken = TextEditingController();
  AttendanceAction _action = AttendanceAction.checkin;
  bool _useScanner = true;

  final MobileScannerController _scanner = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  @override
  void dispose() {
    _vm?.dispose();
    _manualToken.dispose();
    _scanner.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_vm != null) return;
    final scope = AppScope.of(context);
    _vm = AttendanceCheckViewModel(apiClient: scope.apiClient, session: scope.session, location: scope.location);
  }

  @override
  Widget build(BuildContext context) {
    final vm = _vm!;
    return Scaffold(
      appBar: AppBar(title: const Text('Check-in / Check-out')),
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SegmentedButton<AttendanceAction>(
                  segments: const [
                    ButtonSegment(value: AttendanceAction.checkin, label: Text('Check-in')),
                    ButtonSegment(value: AttendanceAction.checkout, label: Text('Check-out')),
                  ],
                  selected: {_action},
                  onSelectionChanged: vm.loading
                      ? null
                      : (s) {
                          setState(() => _action = s.first);
                        },
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: _useScanner,
                  title: const Text('Pakai Scan QR (Camera)'),
                  onChanged: vm.loading
                      ? null
                      : (v) {
                          setState(() => _useScanner = v);
                        },
                ),
                const SizedBox(height: 12),
                if (_useScanner) ...[
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: MobileScanner(
                        controller: _scanner,
                        onDetect: (capture) {
                          final codes = capture.barcodes;
                          if (codes.isEmpty) return;
                          final raw = codes.first.rawValue;
                          if (raw == null || raw.trim().isEmpty) return;
                          _manualToken.text = raw.trim();
                          _submit(vm, raw.trim());
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  TextField(
                    controller: _manualToken,
                    decoration: const InputDecoration(
                      labelText: 'QR Token',
                      hintText: 'Tempel token dari display (kiosk)',
                    ),
                    enabled: !vm.loading,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: vm.loading ? null : () => _submit(vm, _manualToken.text),
                      child: vm.loading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Kirim'),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                if (vm.error != null)
                  Text(vm.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                if (vm.lastResult != null) ...[
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Status: ${vm.lastResult!.status}'),
                          Text('Check-in: ${vm.lastResult!.attendance.checkInAt ?? '-'}'),
                          Text('Check-out: ${vm.lastResult!.attendance.checkOutAt ?? '-'}'),
                          Text('Marked By: ${vm.lastResult!.attendance.markedBy}'),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _submit(AttendanceCheckViewModel vm, String token) async {
    await vm.submit(action: _action, qrToken: token);
    if (!mounted) return;
    if (vm.error == null && _useScanner) {
      // keep scanning but show snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Berhasil: ${vm.lastResult?.status ?? '-'}')),
      );
    }
  }
}

