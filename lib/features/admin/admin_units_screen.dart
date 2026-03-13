import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/models/unit_models.dart';
import '../../core/ui/app_notice.dart';
import 'admin_style.dart';
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
    _vm = AdminUnitsViewModel(
      apiClient: scope.apiClient,
      session: scope.session,
    )..load();
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
      appBar: AppBar(title: const Text('Unit & Geofence')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context, vm),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Unit'),
      ),
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
                      _UnitHeader(totalUnit: vm.units.length),
                      if (vm.error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            vm.error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),
                      AdminSectionCard(
                        padding: EdgeInsets.zero,
                        child: vm.loading && vm.units.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 48),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : vm.units.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 48),
                                child: Center(child: Text('Belum ada unit.')),
                              )
                            : ListView.separated(
                                itemCount: vm.units.length,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, i) {
                                  final u = vm.units[i];
                                  return ListTile(
                                    title: Text(
                                      u.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Lat: ${u.geofenceLat}, Lon: ${u.geofenceLon}\nRadius: ${u.geofenceRadiusM} m',
                                    ),
                                    isThreeLine: true,
                                    leading: Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: adminBlue.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.place_rounded,
                                        color: adminBlue,
                                      ),
                                    ),
                                    trailing: Wrap(
                                      spacing: 4,
                                      children: [
                                        IconButton(
                                          onPressed: () =>
                                              _edit(context, vm, u),
                                          tooltip: 'Edit unit',
                                          icon: const Icon(Icons.edit_rounded),
                                        ),
                                        IconButton(
                                          onPressed: () =>
                                              _delete(context, vm, u),
                                          tooltip: 'Hapus unit',
                                          icon: const Icon(
                                            Icons.delete_outline_rounded,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 92),
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

  Future<void> _edit(
    BuildContext context,
    AdminUnitsViewModel vm,
    UnitDto unit,
  ) async {
    final updated = await showDialog<UnitDto>(
      context: context,
      builder: (_) => _EditUnitDialog(unit: unit),
    );
    if (updated == null) return;
    await vm.updateUnit(updated);
    if (!context.mounted) return;
    if (vm.error == null) {
      AppNotice.show(
        context,
        'Geofence tersimpan.',
        type: AppNoticeType.success,
      );
    }
  }

  Future<void> _add(BuildContext context, AdminUnitsViewModel vm) async {
    final created = await showDialog<UnitDto>(
      context: context,
      builder: (_) => const _EditUnitDialog(unit: null),
    );
    if (created == null) return;
    await vm.createUnit(
      name: created.name,
      geofenceLat: created.geofenceLat,
      geofenceLon: created.geofenceLon,
      geofenceRadiusM: created.geofenceRadiusM,
    );
    if (!context.mounted) return;
    if (vm.error == null) {
      AppNotice.show(context, 'Unit ditambahkan.', type: AppNoticeType.success);
    }
  }

  Future<void> _delete(
    BuildContext context,
    AdminUnitsViewModel vm,
    UnitDto unit,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Unit'),
        content: Text('Yakin hapus unit "${unit.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await vm.deleteUnit(unit.id);
    if (!context.mounted) return;
    if (vm.error == null) {
      AppNotice.show(context, 'Unit dihapus.', type: AppNoticeType.success);
    }
  }
}

class _UnitHeader extends StatelessWidget {
  const _UnitHeader({required this.totalUnit});

  final int totalUnit;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 640;
    return AdminPageHeroPanel(
      icon: Icons.gps_fixed_rounded,
      title: 'Manajemen Unit & Geofence',
      subtitle: 'Atur lokasi unit, koordinat geofence, dan radius absensi.',
      rightPanel: Column(
        children: [
          AdminHeroInfoTile(
            icon: Icons.location_on_rounded,
            label: 'Total Unit',
            value: totalUnit.toString(),
            compact: compact,
          ),
        ],
      ),
    );
  }
}

class _EditUnitDialog extends StatefulWidget {
  const _EditUnitDialog({required this.unit});

  final UnitDto? unit;

  @override
  State<_EditUnitDialog> createState() => _EditUnitDialogState();
}

class _EditUnitDialogState extends State<_EditUnitDialog> {
  late final TextEditingController name;
  late final TextEditingController lat;
  late final TextEditingController lon;
  late final TextEditingController radius;

  GeofenceMode mode = GeofenceMode.defaultPreset;

  @override
  void initState() {
    super.initState();
    final u = widget.unit;
    name = TextEditingController(text: u?.name ?? '');
    lat = TextEditingController(
      text: (u?.geofenceLat ?? AdminUnitsViewModel.defaultLat).toString(),
    );
    lon = TextEditingController(
      text: (u?.geofenceLon ?? AdminUnitsViewModel.defaultLon).toString(),
    );
    radius = TextEditingController(
      text: (u?.geofenceRadiusM ?? AdminUnitsViewModel.defaultRadius)
          .toString(),
    );
    mode = GeofenceMode.defaultPreset;
  }

  void _setMode(GeofenceMode value) {
    setState(() {
      mode = value;
      if (mode == GeofenceMode.defaultPreset) {
        lat.text = AdminUnitsViewModel.defaultLat.toString();
        lon.text = AdminUnitsViewModel.defaultLon.toString();
        radius.text = AdminUnitsViewModel.defaultRadius.toString();
      } else {
        lat.clear();
        lon.clear();
        radius.clear();
      }
    });
  }

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
    final isPhone = MediaQuery.sizeOf(context).width < 640;
    return AdminFormDialogShell(
      title: widget.unit == null ? 'Tambah Unit' : 'Edit Unit',
      subtitle:
          'Atur nama unit dan konfigurasi geofence agar absensi lebih terkontrol.',
      icon: Icons.apartment_rounded,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminFormSection(
            title: 'Informasi Unit',
            icon: Icons.business_rounded,
            compact: isPhone,
            child: TextField(
              controller: name,
              decoration: adminDialogFieldDecoration(label: 'Nama Unit'),
            ),
          ),
          const SizedBox(height: 14),
          AdminFormSection(
            title: 'Geofence',
            icon: Icons.pin_drop_rounded,
            compact: isPhone,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mode Geofence',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF405067),
                  ),
                ),
                const SizedBox(height: 10),
                SegmentedButton<GeofenceMode>(
                  segments: const [
                    ButtonSegment(
                      value: GeofenceMode.defaultPreset,
                      label: Text('Default'),
                      icon: Icon(Icons.auto_fix_high_rounded),
                    ),
                    ButtonSegment(
                      value: GeofenceMode.manual,
                      label: Text('Manual'),
                      icon: Icon(Icons.tune_rounded),
                    ),
                  ],
                  selected: {mode},
                  onSelectionChanged: (s) {
                    if (s.isNotEmpty) _setMode(s.first);
                  },
                ),
                const SizedBox(height: 12),
                if (mode == GeofenceMode.defaultPreset)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F6FC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFDCE4F1)),
                    ),
                    child: const Text(
                      'Mode default menggunakan koordinat dan radius bawaan Lemhannas.',
                    ),
                  ),
                if (mode == GeofenceMode.manual)
                  _GeofenceFields(lat: lat, lon: lon, radius: radius),
              ],
            ),
          ),
        ],
      ),
      actions: [
        SizedBox(
          width: isPhone ? double.infinity : null,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF324057),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text('Batal'),
          ),
        ),
        SizedBox(
          width: isPhone ? double.infinity : null,
          child: FilledButton(
            onPressed: () {
              double? la;
              double? lo;
              int? r;
              if (mode == GeofenceMode.defaultPreset) {
                la = AdminUnitsViewModel.defaultLat;
                lo = AdminUnitsViewModel.defaultLon;
                r = AdminUnitsViewModel.defaultRadius;
              } else {
                r = int.tryParse(radius.text.trim());
                la = double.tryParse(lat.text.trim());
                lo = double.tryParse(lon.text.trim());
              }
              if (r == null || la == null || lo == null) return;
              Navigator.of(context).pop(
                UnitDto(
                  id: widget.unit?.id ?? -1,
                  name: name.text.trim(),
                  geofenceLat: la,
                  geofenceLon: lo,
                  geofenceRadiusM: r,
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: adminNavy,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text('Simpan'),
          ),
        ),
      ],
    );
  }
}

enum GeofenceMode { defaultPreset, manual }

class _GeofenceFields extends StatelessWidget {
  const _GeofenceFields({
    required this.lat,
    required this.lon,
    required this.radius,
  });

  final TextEditingController lat;
  final TextEditingController lon;
  final TextEditingController radius;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: lat,
          decoration: adminDialogFieldDecoration(label: 'Geofence Lat'),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: lon,
          decoration: adminDialogFieldDecoration(label: 'Geofence Lon'),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: radius,
          decoration: adminDialogFieldDecoration(label: 'Radius (meter)'),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }
}
