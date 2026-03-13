import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import 'leave_request_view_model.dart';

class LeaveRequestScreen extends StatefulWidget {
  const LeaveRequestScreen({super.key});

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  LeaveRequestViewModel? _vm;
  String _type = 'IZIN';
  final _dateFrom = TextEditingController();
  final _dateTo = TextEditingController();
  final _reason = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_vm != null) return;
    final scope = AppScope.of(context);
    _vm = LeaveRequestViewModel(apiClient: scope.apiClient, session: scope.session);

    final now = DateTime.now();
    final today = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    _dateFrom.text = today;
    _dateTo.text = today;
  }

  @override
  void dispose() {
    _vm?.dispose();
    _dateFrom.dispose();
    _dateTo.dispose();
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = _vm!;
    return Scaffold(
      appBar: AppBar(title: const Text('Ajukan Izin/Sakit')),
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Tipe'),
                items: const [
                  DropdownMenuItem(value: 'IZIN', child: Text('IZIN')),
                  DropdownMenuItem(value: 'SAKIT', child: Text('SAKIT')),
                ],
                onChanged: vm.loading ? null : (v) => setState(() => _type = v ?? _type),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _dateFrom,
                      decoration: const InputDecoration(labelText: 'Date From (YYYY-MM-DD)'),
                      enabled: !vm.loading,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _dateTo,
                      decoration: const InputDecoration(labelText: 'Date To (YYYY-MM-DD)'),
                      enabled: !vm.loading,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _reason,
                decoration: const InputDecoration(labelText: 'Alasan'),
                minLines: 3,
                maxLines: 5,
                enabled: !vm.loading,
              ),
              const SizedBox(height: 12),
              if (vm.error != null)
                Text(vm.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              if (vm.success)
                const Text('Request terkirim (PENDING).', style: TextStyle(color: Colors.green)),
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: vm.loading
                      ? null
                      : () async {
                          await vm.submit(
                            type: _type,
                            dateFrom: _dateFrom.text.trim(),
                            dateTo: _dateTo.text.trim(),
                            reason: _reason.text.trim(),
                          );
                          if (!mounted) return;
                          if (vm.success) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request terkirim.')));
                          }
                        },
                  child: vm.loading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Kirim'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

