import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import 'admin_devices_view_model.dart';
import 'admin_style.dart';

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
    _vm = AdminDevicesViewModel(
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
    return Scaffold(
      appBar: AppBar(title: const Text('Monitoring Device')),
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) {
          return AdminPageBackground(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1260),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (vm.error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            vm.error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      AdminSectionCard(
                        padding: EdgeInsets.zero,
                        child: vm.loading && vm.devices.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 48),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : vm.devices.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 48),
                                child: Center(
                                  child: Text('Belum ada data device.'),
                                ),
                              )
                            : ListView.separated(
                                itemCount: vm.devices.length,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, i) {
                                  final d = vm.devices[i];
                                  final color = d.online
                                      ? Colors.green
                                      : Colors.red;
                                  return ListTile(
                                    leading: Icon(
                                      d.online
                                          ? Icons.wifi_rounded
                                          : Icons.wifi_off_rounded,
                                      color: color,
                                    ),
                                    title: Text('${d.name} • ${d.unitName}'),
                                    subtitle: Text(
                                      'Last seen: ${d.lastSeenAt ?? '-'}',
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        border: Border.all(
                                          color: color.withValues(alpha: 0.4),
                                        ),
                                      ),
                                      child: Text(
                                        d.online ? 'ONLINE' : 'OFFLINE',
                                        style: TextStyle(color: color),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
