import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/models/leave_models.dart';
import 'mentor_leave_view_model.dart';

class MentorLeaveScreen extends StatefulWidget {
  const MentorLeaveScreen({super.key});

  @override
  State<MentorLeaveScreen> createState() => _MentorLeaveScreenState();
}

class _MentorLeaveScreenState extends State<MentorLeaveScreen> {
  MentorLeaveViewModel? _vm;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_vm != null) return;
    final scope = AppScope.of(context);
    _vm = MentorLeaveViewModel(apiClient: scope.apiClient, session: scope.session)..start();
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
      appBar: AppBar(
        title: const Text('Approval Izin/Sakit'),
        actions: [
          IconButton(
            onPressed: vm.loading ? null : () => vm.refresh(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) {
          return Column(
            children: [
              SwitchListTile(
                value: vm.pendingOnly,
                title: const Text('Tampilkan hanya PENDING'),
                onChanged: (v) => vm.setPendingOnly(v),
              ),
              if (vm.error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(vm.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
              Expanded(
                child: vm.loading && vm.items.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.separated(
                        itemCount: vm.items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) => _LeaveTile(
                          item: vm.items[i],
                          onApprove: () => _decide(vm, vm.items[i], true),
                          onReject: () => _decide(vm, vm.items[i], false),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _decide(MentorLeaveViewModel vm, LeaveRequestDto item, bool approve) async {
    final reason = await _askReason(
      context,
      title: approve ? 'Approve Request' : 'Reject Request',
      hint: 'Alasan (wajib untuk audit)',
    );
    if (reason == null) return;
    await vm.decide(leaveId: item.id, approve: approve, reason: reason);
  }

  Future<String?> _askReason(BuildContext context, {required String title, required String hint}) async {
    final c = TextEditingController();
    final res = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: c,
            decoration: InputDecoration(labelText: hint),
            minLines: 2,
            maxLines: 4,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Batal')),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(c.text.trim()),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
    c.dispose();
    if (res == null || res.trim().isEmpty) return null;
    return res.trim();
  }
}

class _LeaveTile extends StatelessWidget {
  const _LeaveTile({
    required this.item,
    required this.onApprove,
    required this.onReject,
  });

  final LeaveRequestDto item;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (item.status) {
      'PENDING' => Colors.orange,
      'APPROVED' => Colors.green,
      'REJECTED' => Colors.red,
      _ => Colors.grey,
    };
    return ListTile(
      title: Text('${item.internName} • ${item.type}'),
      subtitle: Text('${item.dateFrom} → ${item.dateTo}\n${item.reason}'),
      trailing: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: statusColor.withOpacity(0.4)),
            ),
            child: Text(item.status, style: TextStyle(color: statusColor)),
          ),
          if (item.status == 'PENDING') ...[
            IconButton(onPressed: onReject, icon: const Icon(Icons.close)),
            IconButton(onPressed: onApprove, icon: const Icon(Icons.check)),
          ],
        ],
      ),
      isThreeLine: true,
    );
  }
}

