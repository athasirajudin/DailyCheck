import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/services/api_client_base.dart';
import '../../core/models/leave_models.dart';
import '../admin/admin_style.dart';
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
    if (_vm != null) {
      return;
    }
    final scope = AppScope.of(context);
    _vm = MentorLeaveViewModel(
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
      appBar: AppBar(title: const Text('Approval Izin/Sakit')),
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) {
          final screenWidth = MediaQuery.sizeOf(context).width;
          final isPhone = screenWidth < 640;
          final pendingCount = vm.items
              .where((e) => e.status == 'PENDING')
              .length;
          final attachmentCount = vm.items.where((e) => e.hasAttachment).length;
          return AdminPageBackground(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1260),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    isPhone ? 10 : 12,
                    12,
                    isPhone ? 10 : 12,
                    12,
                  ),
                  children: [
                    DashboardReveal(
                      delay: const Duration(milliseconds: 40),
                      child: _MentorLeaveHeader(
                        totalRequest: vm.items.length,
                        pendingRequest: pendingCount,
                        withAttachment: attachmentCount,
                      ),
                    ),
                    const SizedBox(height: 10),
                    DashboardReveal(
                      delay: const Duration(milliseconds: 90),
                      child: AdminSectionCard(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final compactFilter = constraints.maxWidth < 760;
                            if (compactFilter) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  SwitchListTile(
                                    value: vm.pendingOnly,
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text(
                                      'Tampilkan hanya PENDING',
                                    ),
                                    subtitle: const Text(
                                      'Filter cepat untuk review pengajuan baru',
                                    ),
                                    onChanged: (v) => vm.setPendingOnly(v),
                                  ),
                                  const SizedBox(height: 8),
                                  FilledButton.icon(
                                    onPressed: vm.loading
                                        ? null
                                        : () => vm.refresh(),
                                    icon: const Icon(Icons.refresh_rounded),
                                    label: const Text('Refresh'),
                                  ),
                                ],
                              );
                            }
                            return Row(
                              children: [
                                Expanded(
                                  child: SwitchListTile(
                                    value: vm.pendingOnly,
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text(
                                      'Tampilkan hanya PENDING',
                                    ),
                                    subtitle: const Text(
                                      'Filter cepat untuk review pengajuan baru',
                                    ),
                                    onChanged: (v) => vm.setPendingOnly(v),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                FilledButton.icon(
                                  onPressed: vm.loading
                                      ? null
                                      : () => vm.refresh(),
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: const Text('Refresh'),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
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
                    DashboardReveal(
                      delay: const Duration(milliseconds: 140),
                      child: AdminSectionCard(
                        padding: EdgeInsets.zero,
                        child: vm.loading && vm.items.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 56),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : vm.items.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Text('Belum ada pengajuan.'),
                                ),
                              )
                            : ListView.separated(
                                itemCount: vm.items.length,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, i) => _LeaveTile(
                                  item: vm.items[i],
                                  onApprove: () =>
                                      _decide(vm, vm.items[i], true),
                                  onReject: () =>
                                      _decide(vm, vm.items[i], false),
                                  onViewAttachment: vm.items[i].hasAttachment
                                      ? () => _previewAttachment(vm.items[i])
                                      : null,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _decide(
    MentorLeaveViewModel vm,
    LeaveRequestDto item,
    bool approve,
  ) async {
    final reason = await _askReason(
      context,
      title: approve ? 'Approve Request' : 'Reject Request',
      hint: 'Alasan (wajib untuk audit)',
    );
    if (reason == null) {
      return;
    }
    await vm.decide(leaveId: item.id, approve: approve, reason: reason);
  }

  Future<void> _previewAttachment(LeaveRequestDto item) async {
    final scope = AppScope.of(context);
    final path = '/api/mentor/leave/${item.id}/attachment';
    final baseUri = Uri.parse(scope.config.apiBaseUrl);
    final displayUrl = baseUri.resolve(path).toString();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AdminFormDialogShell(
          title: 'Bukti ${item.type}',
          subtitle:
              'Preview lampiran milik ${item.internName}. Periksa bukti sebelum menyetujui atau menolak pengajuan.',
          icon: Icons.verified_user_rounded,
          maxWidth: 860,
          content: SizedBox(
            width: 760,
            child: _AttachmentPreview(
              path: path,
              token: scope.session.token ?? '',
              displayUrl: displayUrl,
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _askReason(
    BuildContext context, {
    required String title,
    required String hint,
  }) async {
    final c = TextEditingController();
    final res = await showDialog<String>(
      context: context,
      builder: (context) {
        return AdminFormDialogShell(
          title: title,
          subtitle:
              'Alasan dicatat untuk audit dan riwayat validasi pengajuan.',
          icon: title.contains('Approve')
              ? Icons.check_circle_rounded
              : Icons.cancel_rounded,
          content: TextField(
            controller: c,
            decoration: adminDialogFieldDecoration(label: hint),
            minLines: 3,
            maxLines: 5,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(c.text.trim()),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
    c.dispose();
    if (res == null || res.trim().isEmpty) {
      return null;
    }
    return res.trim();
  }
}

class _MentorLeaveHeader extends StatelessWidget {
  const _MentorLeaveHeader({
    required this.totalRequest,
    required this.pendingRequest,
    required this.withAttachment,
  });

  final int totalRequest;
  final int pendingRequest;
  final int withAttachment;

  @override
  Widget build(BuildContext context) {
    final isPhone = MediaQuery.sizeOf(context).width < 640;
    return AdminPageHeroPanel(
      icon: Icons.assignment_turned_in_rounded,
      title: 'Approval Izin / Sakit',
      subtitle:
          'Validasi pengajuan intern bimbingan dengan cepat, termasuk review lampiran bukti.',
      compactBreakpoint: 920,
      rightPanel: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminHeroInfoTile(
            icon: Icons.list_alt_rounded,
            label: 'Total Pengajuan',
            value: totalRequest.toString(),
            compact: isPhone,
          ),
          const SizedBox(height: 8),
          AdminHeroInfoTile(
            icon: Icons.pending_actions_rounded,
            label: 'Status Pending',
            value: pendingRequest.toString(),
            compact: isPhone,
          ),
          const SizedBox(height: 8),
          AdminHeroInfoTile(
            icon: Icons.image_rounded,
            label: 'Dengan Lampiran',
            value: withAttachment.toString(),
            compact: isPhone,
          ),
        ],
      ),
    );
  }
}

class _AttachmentPreview extends StatefulWidget {
  const _AttachmentPreview({
    required this.path,
    required this.token,
    required this.displayUrl,
  });

  final String path;
  final String token;
  final String displayUrl;

  @override
  State<_AttachmentPreview> createState() => _AttachmentPreviewState();
}

class _AttachmentPreviewState extends State<_AttachmentPreview> {
  late Future<Uint8List> _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future = AppScope.of(
      context,
    ).apiClient.getBytes(widget.path, bearerToken: widget.token);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _future,
      builder: (context, snapshot) {
        final child = switch (snapshot.connectionState) {
          ConnectionState.waiting || ConnectionState.active => const Center(
            child: CircularProgressIndicator(),
          ),
          _ when snapshot.hasError => _AttachmentPreviewError(
            message: snapshot.error is ApiError
                ? (snapshot.error as ApiError).message
                : 'Lampiran tidak dapat dimuat.',
            displayUrl: widget.displayUrl,
          ),
          _ when !snapshot.hasData || snapshot.data!.isEmpty =>
            _AttachmentPreviewError(
              message: 'Lampiran kosong atau tidak tersedia.',
              displayUrl: widget.displayUrl,
            ),
          _ => InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: Image.memory(
              snapshot.data!,
              fit: BoxFit.contain,
              gaplessPlayback: true,
              errorBuilder: (context, _, __) {
                return _AttachmentPreviewError(
                  message:
                      'Bukti tidak bisa ditampilkan sebagai gambar. Pastikan lampiran berupa foto.',
                  displayUrl: widget.displayUrl,
                );
              },
            ),
          ),
        };

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7FC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFDCE4F1)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.zoom_in_rounded, color: adminNavy, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Geser atau pinch untuk memperbesar gambar bukti.',
                      style: TextStyle(
                        color: Color(0xFF58657A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 260, maxHeight: 520),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFFDFEFF),
                  border: Border.all(color: const Color(0xFFD7E0EE)),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: child,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SelectableText(
              widget.displayUrl,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      },
    );
  }
}

class _AttachmentPreviewError extends StatelessWidget {
  const _AttachmentPreviewError({
    required this.message,
    required this.displayUrl,
  });

  final String message;
  final String displayUrl;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFFFDECEC),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.broken_image_rounded,
                color: Color(0xFFB24A48),
                size: 30,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF495668),
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            SelectableText(
              displayUrl,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaveTile extends StatelessWidget {
  const _LeaveTile({
    required this.item,
    required this.onApprove,
    required this.onReject,
    this.onViewAttachment,
  });

  final LeaveRequestDto item;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback? onViewAttachment;

  @override
  Widget build(BuildContext context) {
    final isPhone = MediaQuery.sizeOf(context).width < 640;
    final statusColor = switch (item.status) {
      'PENDING' => Colors.orange,
      'APPROVED' => Colors.green,
      'REJECTED' => Colors.red,
      _ => Colors.grey,
    };
    final subtitleStyle = const TextStyle(
      color: Color(0xFF4F5A6D),
      height: 1.4,
    );
    final statusBadge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: statusColor.withValues(alpha: 0.4)),
      ),
      child: Text(
        item.status,
        style: TextStyle(
          color: statusColor,
          fontWeight: FontWeight.w700,
          fontSize: isPhone ? 11.5 : 12.5,
        ),
      ),
    );
    final attachmentButton = onViewAttachment == null
        ? null
        : IconButton(
            tooltip: 'Lihat bukti',
            onPressed: onViewAttachment,
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF4F7FC),
              foregroundColor: adminNavy,
            ),
            icon: const Icon(Icons.image_outlined),
          );
    final approveButton = IconButton(
      onPressed: onApprove,
      style: IconButton.styleFrom(
        backgroundColor: const Color(0xFFE9F7EE),
        foregroundColor: const Color(0xFF1A7F48),
      ),
      icon: const Icon(Icons.check),
    );
    final rejectButton = IconButton(
      onPressed: onReject,
      style: IconButton.styleFrom(
        backgroundColor: const Color(0xFFFDECEC),
        foregroundColor: const Color(0xFFC74848),
      ),
      icon: const Icon(Icons.close),
    );

    if (isPhone) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.assignment_late_rounded,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.internName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Color(0xFF1E2D44),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.type,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                statusBadge,
                if (attachmentButton != null) attachmentButton,
                if (item.status == 'PENDING') rejectButton,
                if (item.status == 'PENDING') approveButton,
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${item.dateFrom} -> ${item.dateTo}',
              style: subtitleStyle.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(item.reason, style: subtitleStyle),
            const SizedBox(height: 6),
            Text(
              'Bukti: ${item.hasAttachment ? 'Ada' : 'Tidak ada'}',
              style: subtitleStyle,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.assignment_late_rounded, color: statusColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.internName} - ${item.type}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Color(0xFF1E2D44),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${item.dateFrom} -> ${item.dateTo}\n'
                  '${item.reason}\n'
                  'Bukti: ${item.hasAttachment ? 'Ada' : 'Tidak ada'}',
                  style: subtitleStyle,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.end,
                children: [
                  if (attachmentButton != null) attachmentButton,
                  statusBadge,
                ],
              ),
              if (item.status == 'PENDING') ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    rejectButton,
                    const SizedBox(width: 8),
                    approveButton,
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
