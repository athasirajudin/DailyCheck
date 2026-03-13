import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
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
    _vm = InternTodayViewModel(apiClient: scope.apiClient, session: scope.session)..start();
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tanggal: ${state.date}', style: Theme.of(context).textTheme.titleMedium),
            Text('Unit: ${state.unitName}'),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Status: ${state.status ?? 'BELUM_ABSEN'}'),
                    Text('Check-in: ${state.checkInAt ?? '-'}'),
                    Text('Check-out: ${state.checkOutAt ?? '-'}'),
                    if (state.checkoutMissing == true) const Text('Catatan: Checkout missing'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Catatan: karena tanpa plugin QR & GPS, input QR token dan koordinat dilakukan manual (sementara).',
            ),
          ],
        );
      },
    );
  }
}
