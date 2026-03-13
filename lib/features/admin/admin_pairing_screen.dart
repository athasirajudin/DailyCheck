import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/models/unit_models.dart';
import 'admin_pairing_view_model.dart';
import 'admin_style.dart';

class AdminPairingScreen extends StatefulWidget {
  const AdminPairingScreen({super.key});

  @override
  State<AdminPairingScreen> createState() => _AdminPairingScreenState();
}

class _AdminPairingScreenState extends State<AdminPairingScreen> {
  AdminPairingViewModel? _vm;
  UnitDto? _selectedUnit;
  final _deviceName = TextEditingController(text: 'Display-1');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_vm != null) return;
    final scope = AppScope.of(context);
    _vm = AdminPairingViewModel(
      apiClient: scope.apiClient,
      session: scope.session,
    );
    _vm!.loadUnits().then((_) {
      if (!mounted) return;
      setState(() {
        _selectedUnit = _vm!.units.isNotEmpty ? _vm!.units.first : null;
      });
    });
  }

  @override
  void dispose() {
    _vm?.dispose();
    _deviceName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = _vm!;
    return Scaffold(
      appBar: AppBar(title: const Text('Pairing Device')),
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) {
          return AdminPageBackground(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 880),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: AdminSectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (vm.error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              vm.error!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        DropdownButtonFormField<UnitDto>(
                          initialValue: _selectedUnit,
                          decoration: const InputDecoration(labelText: 'Unit'),
                          items: vm.units
                              .map(
                                (u) => DropdownMenuItem<UnitDto>(
                                  value: u,
                                  child: Text('${u.id} • ${u.name}'),
                                ),
                              )
                              .toList(),
                          onChanged: vm.loading
                              ? null
                              : (v) => setState(() => _selectedUnit = v),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _deviceName,
                          decoration: const InputDecoration(
                            labelText: 'Nama Device Display',
                          ),
                          enabled: !vm.loading,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 48,
                          child: FilledButton.icon(
                            onPressed: vm.loading || _selectedUnit == null
                                ? null
                                : () => vm.createPairing(
                                    unitId: _selectedUnit!.id,
                                    deviceName: _deviceName.text.trim(),
                                  ),
                            icon: const Icon(Icons.link),
                            label: vm.loading
                                ? const Text('Memproses...')
                                : const Text('Generate Pairing Code'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (vm.last != null) ...[
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Pairing Code (berlaku 10 menit):',
                                  ),
                                  const SizedBox(height: 8),
                                  SelectableText(
                                    vm.last!.pairingCode,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Expires: ${vm.last!.expiresAt}'),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Masukkan pairing code ini di menu "Mode Display (Kiosk)" pada device display.',
                          ),
                        ],
                      ],
                    ),
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
