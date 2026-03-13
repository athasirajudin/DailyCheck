import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/models/unit_models.dart';
import 'admin_units_view_model.dart';

class AdminUnitsScreen extends StatefulWidget {
  const AdminUnitsScreen({super.key});

  @override
  State<AdminUnitsScreen> createState() => _AdminUnitsScreenState();
}

class _AdminUnitsScreenState extends State<AdminUnitsScreen> {
  AdminUnitsViewModel? _vm;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_vm != null) return;
    final scope = AppScope.of(context);
    _vm = AdminUnitsViewModel(apiClient: scope.apiClient, session: scope.session)..load();
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
        title: const Text('Unit & Geofence'),
        actions: [
          IconButton(onPressed: vm.loading ? null : () => vm.load(), icon: const Icon(Icons.refresh)),
        ],
      ),
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) {
          if (vm.loading && vm.units.isEmpty) return const Center(child: CircularProgressIndicator());
          return Column(
            children: [
              if (vm.error != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(vm.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
              Expanded(
                child: ListView.separated(
                  itemCount: vm.units.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final u = vm.units[i];
                    return ListTile(
                      title: Text(u.name),
                      subtitle: Text('Lat: ${u.geofenceLat}, Lon: ${u.geofenceLon}\nRadius: ${u.geofenceRadiusM} m'),
                      isThreeLine: true,
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _edit(context, vm, u),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _edit(BuildContext context, AdminUnitsViewModel vm, UnitDto unit) async {
    final updated = await showDialog<UnitDto>(
      context: context,
      builder: (_) => _EditUnitDialog(unit: unit),
    );
    if (updated == null) return;
    await vm.updateUnit(updated);
    if (!mounted) return;
    if (vm.error == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Geofence tersimpan.')));
    }
  }
}

class _EditUnitDialog extends StatefulWidget {
  const _EditUnitDialog({required this.unit});

  final UnitDto unit;

  @override
  State<_EditUnitDialog> createState() => _EditUnitDialogState();
}

class _EditUnitDialogState extends State<_EditUnitDialog> {
  late final TextEditingController name = TextEditingController(text: widget.unit.name);
  late final TextEditingController lat = TextEditingController(text: widget.unit.geofenceLat.toString());
  late final TextEditingController lon = TextEditingController(text: widget.unit.geofenceLon.toString());
  late final TextEditingController radius = TextEditingController(text: widget.unit.geofenceRadiusM.toString());

  @override
  void dispose() {
    name.dispose();
    lat.dispose();
    lon.dispose();
    radius.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Unit & Geofence'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Nama Unit')),
            const SizedBox(height: 12),
            TextField(controller: lat, decoration: const InputDecoration(labelText: 'Geofence Lat'), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            TextField(controller: lon, decoration: const InputDecoration(labelText: 'Geofence Lon'), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            TextField(controller: radius, decoration: const InputDecoration(labelText: 'Radius (meter)'), keyboardType: TextInputType.number),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Batal')),
        FilledButton(
          onPressed: () {
            final r = int.tryParse(radius.text.trim());
            final la = double.tryParse(lat.text.trim());
            final lo = double.tryParse(lon.text.trim());
            if (r == null || la == null || lo == null) return;
            Navigator.of(context).pop(
              UnitDto(
                id: widget.unit.id,
                name: name.text.trim(),
                geofenceLat: la,
                geofenceLon: lo,
                geofenceRadiusM: r,
              ),
            );
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

