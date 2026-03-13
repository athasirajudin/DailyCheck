import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/app_scope.dart';
import '../../core/ui/app_notice.dart';
import '../admin/admin_style.dart';
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
  final _picker = ImagePicker();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_vm != null) return;
    final scope = AppScope.of(context);
    _vm = LeaveRequestViewModel(
      apiClient: scope.apiClient,
      session: scope.session,
    );

    final now = DateTime.now();
    final today =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
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
      appBar: AppBar(title: const Text('Ajukan Izin / Sakit')),
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) {
          return AdminPageBackground(
            child: ListView(
              padding: EdgeInsets.all(
                MediaQuery.sizeOf(context).width < 640 ? 12 : 16,
              ),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AdminSectionCard(
                          padding: EdgeInsets.zero,
                          child: _LeaveHeroPanel(
                            type: _type,
                            dateFrom: _dateFrom.text,
                            dateTo: _dateTo.text,
                          ),
                        ),
                        const SizedBox(height: 12),
                        AdminSectionCard(
                          child: Column(
                            children: [
                              DropdownButtonFormField<String>(
                                initialValue: _type,
                                decoration: const InputDecoration(
                                  labelText: 'Tipe',
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'IZIN',
                                    child: Text('IZIN'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'SAKIT',
                                    child: Text('SAKIT'),
                                  ),
                                ],
                                onChanged: vm.loading
                                    ? null
                                    : (v) => setState(() => _type = v ?? _type),
                              ),
                              const SizedBox(height: 12),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final vertical = constraints.maxWidth < 760;
                                  final fromField = _DateField(
                                    label: 'Date From (YYYY-MM-DD)',
                                    controller: _dateFrom,
                                    enabled: !vm.loading,
                                    onTap: () => _pickDate(_dateFrom),
                                  );
                                  final toField = _DateField(
                                    label: 'Date To (YYYY-MM-DD)',
                                    controller: _dateTo,
                                    enabled: !vm.loading,
                                    onTap: () => _pickDate(_dateTo),
                                  );
                                  if (vertical) {
                                    return Column(
                                      children: [
                                        fromField,
                                        const SizedBox(height: 12),
                                        toField,
                                      ],
                                    );
                                  }
                                  return Row(
                                    children: [
                                      Expanded(child: fromField),
                                      const SizedBox(width: 12),
                                      Expanded(child: toField),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _reason,
                                decoration: const InputDecoration(
                                  labelText: 'Alasan',
                                ),
                                minLines: 3,
                                maxLines: 5,
                                enabled: !vm.loading,
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF6F8FC),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFFDCE4F1),
                                  ),
                                ),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final compact = constraints.maxWidth < 620;
                                    final button = OutlinedButton.icon(
                                      onPressed: vm.loading
                                          ? null
                                          : () async {
                                              final file = await _picker
                                                  .pickImage(
                                                    source: ImageSource.gallery,
                                                    imageQuality: 80,
                                                  );
                                              if (file != null) {
                                                vm.setAttachment(file);
                                              }
                                            },
                                      icon: const Icon(Icons.upload_rounded),
                                      label: const Text('Upload bukti'),
                                    );
                                    final text = Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Lampiran bukti',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF22314A),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          vm.attachmentName == null
                                              ? 'Belum ada bukti terlampir'
                                              : 'Lampiran: ${vm.attachmentName}',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Color(0xFF586276),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    );
                                    if (compact) {
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          text,
                                          const SizedBox(height: 10),
                                          button,
                                        ],
                                      );
                                    }
                                    return Row(
                                      children: [
                                        Expanded(child: text),
                                        const SizedBox(width: 8),
                                        button,
                                      ],
                                    );
                                  },
                                ),
                              ),
                              if (vm.error != null) ...[
                                const SizedBox(height: 10),
                                Text(
                                  vm.error!,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                              if (vm.success) ...[
                                const SizedBox(height: 10),
                                const Text(
                                  'Request terkirim (PENDING).',
                                  style: TextStyle(
                                    color: Color(0xFF13765E),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 14),
                              SizedBox(
                                height: 48,
                                child: FilledButton.icon(
                                  onPressed: vm.loading
                                      ? null
                                      : () async {
                                          await vm.submit(
                                            type: _type,
                                            dateFrom: _dateFrom.text.trim(),
                                            dateTo: _dateTo.text.trim(),
                                            reason: _reason.text.trim(),
                                          );
                                          if (!context.mounted) return;
                                          if (!vm.success) return;
                                          AppNotice.show(
                                            context,
                                            'Request terkirim.',
                                            type: AppNoticeType.success,
                                          );
                                        },
                                  icon: vm.loading
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.send_rounded),
                                  label: Text(
                                    vm.loading ? 'Mengirim...' : 'Kirim',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickDate(TextEditingController controller) async {
    DateTime initial = DateTime.now();
    final raw = controller.text.trim();
    if (raw.isNotEmpty) {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) initial = parsed;
    }
    final selected = await showAdminDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2100, 12, 31),
    );
    if (selected == null) return;
    controller.text =
        '${selected.year.toString().padLeft(4, '0')}-${selected.month.toString().padLeft(2, '0')}-${selected.day.toString().padLeft(2, '0')}';
    if (mounted) setState(() {});
  }
}

class _LeaveHeroPanel extends StatelessWidget {
  const _LeaveHeroPanel({
    required this.type,
    required this.dateFrom,
    required this.dateTo,
  });

  final String type;
  final String dateFrom;
  final String dateTo;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 640;
    return AdminPageHeroPanel(
      icon: Icons.note_add_rounded,
      title: 'Form Request Izin / Sakit',
      subtitle:
          'Isi tanggal dan alasan. Untuk tipe sakit, lampiran bukti wajib diunggah.',
      compactBreakpoint: 700,
      rightPanel: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminHeroInfoTile(
            icon: Icons.check_circle_rounded,
            label: 'Tipe Pengajuan',
            value: type,
            compact: compact,
          ),
          const SizedBox(height: 10),
          AdminHeroInfoTile(
            icon: Icons.calendar_today_rounded,
            label: 'Tanggal Mulai',
            value: dateFrom,
            compact: compact,
          ),
          const SizedBox(height: 10),
          AdminHeroInfoTile(
            icon: Icons.event_available_rounded,
            label: 'Tanggal Selesai',
            value: dateTo,
            compact: compact,
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.controller,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: true,
      onTap: enabled ? onTap : null,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.calendar_month_rounded),
      ),
      enabled: enabled,
    );
  }
}
