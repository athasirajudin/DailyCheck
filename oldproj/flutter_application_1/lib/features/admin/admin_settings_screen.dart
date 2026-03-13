import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import 'admin_settings_view_model.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  AdminSettingsViewModel? _vm;

  final _timezone = TextEditingController();
  final _workStart = TextEditingController();
  final _tolerance = TextEditingController();
  final _cutoff = TextEditingController();
  final _offlineThreshold = TextEditingController();
  final _qrTtl = TextEditingController();
  final Set<int> _workdays = {1, 2, 3, 4, 5};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_vm != null) return;
    final scope = AppScope.of(context);
    _vm = AdminSettingsViewModel(apiClient: scope.apiClient, session: scope.session);
    _vm!.load().then((_) {
      final s = _vm!.state;
      if (s == null) return;
      _timezone.text = s.timezone;
      _workStart.text = s.workStartTime;
      _tolerance.text = s.toleranceMinutes.toString();
      _cutoff.text = s.dayCutoffTime;
      _offlineThreshold.text = s.offlineThresholdSeconds.toString();
      _qrTtl.text = s.qrTokenTtlSeconds.toString();
      _workdays
        ..clear()
        ..addAll(s.workdays);
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _vm?.dispose();
    _timezone.dispose();
    _workStart.dispose();
    _tolerance.dispose();
    _cutoff.dispose();
    _offlineThreshold.dispose();
    _qrTtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = _vm!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(onPressed: vm.loading ? null : () => vm.load(), icon: const Icon(Icons.refresh)),
        ],
      ),
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (vm.loading && vm.state == null) const LinearProgressIndicator(),
              if (vm.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(vm.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
              TextField(
                controller: _timezone,
                decoration: const InputDecoration(labelText: 'Timezone'),
                enabled: !vm.loading,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _workStart,
                decoration: const InputDecoration(labelText: 'Work Start Time (HH:MM:SS)'),
                enabled: !vm.loading,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _tolerance,
                decoration: const InputDecoration(labelText: 'Tolerance Minutes'),
                keyboardType: TextInputType.number,
                enabled: !vm.loading,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _cutoff,
                decoration: const InputDecoration(labelText: 'Day Cutoff Time (HH:MM:SS)'),
                enabled: !vm.loading,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _offlineThreshold,
                decoration: const InputDecoration(labelText: 'Offline Threshold Seconds'),
                keyboardType: TextInputType.number,
                enabled: !vm.loading,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _qrTtl,
                decoration: const InputDecoration(labelText: 'QR Token TTL Seconds'),
                keyboardType: TextInputType.number,
                enabled: !vm.loading,
              ),
              const SizedBox(height: 16),
              Text('Workdays', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _dayChip('Mon', 1),
                  _dayChip('Tue', 2),
                  _dayChip('Wed', 3),
                  _dayChip('Thu', 4),
                  _dayChip('Fri', 5),
                  _dayChip('Sat', 6),
                  _dayChip('Sun', 7),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: vm.loading ? null : () => _save(vm),
                  icon: const Icon(Icons.save),
                  label: const Text('Simpan'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _dayChip(String label, int day) {
    final selected = _workdays.contains(day);
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (v) {
        setState(() {
          if (v) {
            _workdays.add(day);
          } else {
            _workdays.remove(day);
          }
        });
      },
    );
  }

  Future<void> _save(AdminSettingsViewModel vm) async {
    final tol = int.tryParse(_tolerance.text.trim()) ?? 15;
    final offline = int.tryParse(_offlineThreshold.text.trim()) ?? 120;
    final ttl = int.tryParse(_qrTtl.text.trim()) ?? 30;
    final s = AdminSettingsState(
      timezone: _timezone.text.trim().isEmpty ? 'Asia/Jakarta' : _timezone.text.trim(),
      workStartTime: _workStart.text.trim().isEmpty ? '09:00:00' : _workStart.text.trim(),
      toleranceMinutes: tol,
      dayCutoffTime: _cutoff.text.trim().isEmpty ? '23:59:59' : _cutoff.text.trim(),
      workdays: _workdays.toList()..sort(),
      offlineThresholdSeconds: offline,
      qrTokenTtlSeconds: ttl,
    );
    await vm.save(s);
    if (!mounted) return;
    if (vm.error == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings tersimpan.')));
    }
  }
}

