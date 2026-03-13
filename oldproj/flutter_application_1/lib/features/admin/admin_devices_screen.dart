import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import 'admin_devices_view_model.dart';

class AdminDevicesScreen extends StatefulWidget {
  const AdminDevicesScreen({super.key});

  @override
  State<AdminDevicesScreen> createState() => _AdminDevicesScreenState();
}

class _AdminDevicesScreenState extends State<AdminDevicesScreen> {
  AdminDevicesViewModel? _vm;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_vm != null) return;
    final scope = AppScope.of(context);
    _vm = AdminDevicesViewModel(apiClient: scope.apiClient, session: scope.session)..start();
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
        title: const Text('Monitoring Device'),
        actions: [
          IconButton(onPressed: vm.loading ? null : () => vm.refresh(), icon: const Icon(Icons.refresh)),
        ],
      ),
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) {
          if (vm.loading && vm.devices.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView.separated(
            padding: const EdgeInsets.all(8),
            itemCount: vm.devices.length + (vm.error != null ? 1 : 0),
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              if (vm.error != null && i == 0) {
                return ListTile(
                  title: Text(vm.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                );
              }
              final d = vm.devices[i - (vm.error != null ? 1 : 0)];
              final color = d.online ? Colors.green : Colors.red;
              return ListTile(
                leading: Icon(d.online ? Icons.wifi : Icons.wifi_off, color: color),
                title: Text('${d.name} • ${d.unitName}'),
                subtitle: Text('Last seen: ${d.lastSeenAt ?? '-'}'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: color.withOpacity(0.4)),
                  ),
                  child: Text(d.online ? 'ONLINE' : 'OFFLINE', style: TextStyle(color: color)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

