import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/models/admin_user_models.dart';
import '../../core/models/unit_models.dart';
import '../../core/models/public_school_models.dart';
import '../../core/ui/app_notice.dart';
import 'admin_style.dart';
import 'admin_interns_view_model.dart';

class AdminInternsScreen extends StatefulWidget {
  const AdminInternsScreen({super.key});

  @override
  State<AdminInternsScreen> createState() => _AdminInternsScreenState();
}

class _AdminInternsScreenState extends State<AdminInternsScreen> {
  AdminInternsViewModel? _vm;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_vm != null) return;
    final scope = AppScope.of(context);
    _vm = AdminInternsViewModel(
      apiClient: scope.apiClient,
      session: scope.session,
    )..loadAll();
  }

  @override
  void dispose() {
    _vm?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = _vm!;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isPhone = screenWidth < 640;
    final isSmallPhone = screenWidth < 430;
    final inactiveIntern = vm.interns.where((e) => !e.active).length;
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Intern (CRUD)')),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: ListenableBuilder(
        listenable: vm,
        builder: (context, _) {
          return SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isPhone ? 320 : 420),
              child: Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: vm.loading ? null : vm.loadAll,
                    icon: vm.loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded),
                    label: Text(vm.loading ? 'Memuat' : 'Refresh'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: isPhone ? 16 : 18,
                        vertical: isPhone ? 14 : 16,
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _create(context, vm),
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    label: const Text('Tambah Intern'),
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: isPhone ? 18 : 20,
                        vertical: isPhone ? 14 : 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) {
          return AdminPageBackground(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1260),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    isPhone ? 10 : 12,
                    isPhone ? 10 : 12,
                    isPhone ? 10 : 12,
                    isPhone ? 120 : 112,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _InternHeader(
                        totalIntern: vm.interns.length,
                        activeIntern: vm.interns.where((e) => e.active).length,
                        inactiveIntern: inactiveIntern,
                        compact: isPhone,
                        loading: vm.loading,
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
                      AdminSectionCard(
                        padding: EdgeInsets.all(isPhone ? 14 : 16),
                        child: vm.loading && vm.interns.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 48),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : vm.interns.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 48),
                                child: Center(
                                  child: Text('Belum ada data intern.'),
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Daftar Intern Aktif & Nonaktif',
                                              style: TextStyle(
                                                fontSize: isPhone ? 17 : 20,
                                                fontWeight: FontWeight.w900,
                                                color: const Color(0xFF21314B),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Kelola profil intern, penempatan unit, sekolah, dan status akses dari satu panel.',
                                              style: TextStyle(
                                                fontSize: isPhone ? 12.5 : 13.5,
                                                color: const Color(0xFF667387),
                                                height: 1.4,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isPhone ? 10 : 12,
                                          vertical: isPhone ? 8 : 9,
                                        ),
                                        decoration: BoxDecoration(
                                          color: adminBlue.withValues(
                                            alpha: 0.10,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                          border: Border.all(
                                            color: adminBlue.withValues(
                                              alpha: 0.18,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          '${vm.interns.length} data',
                                          style: TextStyle(
                                            color: adminBlue,
                                            fontWeight: FontWeight.w800,
                                            fontSize: isPhone ? 12 : 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      final width = constraints.maxWidth;
                                      final columns = width >= 1020 ? 2 : 1;
                                      final spacing = isPhone ? 10.0 : 12.0;
                                      final itemWidth = columns == 1
                                          ? width
                                          : (width - spacing) / 2;
                                      return Wrap(
                                        spacing: spacing,
                                        runSpacing: spacing,
                                        children: [
                                          for (final intern in vm.interns)
                                            SizedBox(
                                              width: itemWidth,
                                              child: _InternRecordCard(
                                                intern: intern,
                                                compact: isPhone,
                                                dense: isSmallPhone,
                                                onOpen: () => _showDetail(
                                                  context,
                                                  intern,
                                                ),
                                                onEdit: () =>
                                                    _edit(context, vm, intern),
                                              ),
                                            ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
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

  Future<void> _showDetail(BuildContext context, AdminInternRowDto it) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => _InternDetailDialog(intern: it),
    );
  }

  Future<void> _create(BuildContext context, AdminInternsViewModel vm) async {
    final res = await showDialog<_InternPayload>(
      context: context,
      builder: (context) => _InternDialog(units: vm.units, mentors: vm.mentors),
    );
    if (res == null) return;
    final temp = await vm.create(
      nisn: res.nisn,
      gender: res.gender,
      fullName: res.fullName,
      unitId: res.unitId,
      mentorUserId: res.mentorUserId,
      internshipStart: res.start,
      internshipEnd: res.end,
      schoolName: res.schoolName,
      schoolAddress: res.schoolAddress,
      password: res.password,
    );
    if (!context.mounted) return;
    if (temp != null && temp.isNotEmpty) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Intern dibuat'),
          content: SelectableText('Password sementara:\n\n$temp'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _edit(
    BuildContext context,
    AdminInternsViewModel vm,
    AdminInternRowDto it,
  ) async {
    final res = await showDialog<_InternPayload>(
      context: context,
      builder: (context) =>
          _InternDialog(units: vm.units, mentors: vm.mentors, initial: it),
    );
    if (res == null) return;
    final ok = await vm.update(
      userId: it.userId,
      fullName: res.fullName,
      nisn: res.nisn,
      gender: res.gender,
      unitId: res.unitId,
      mentorUserId: res.mentorUserId,
      internshipStart: res.start,
      internshipEnd: res.end,
      schoolName: res.schoolName,
      schoolAddress: res.schoolAddress,
      active: res.active,
    );
    if (!context.mounted) return;
    if (ok && vm.error == null) {
      AppNotice.show(
        context,
        'Data intern diperbarui.',
        type: AppNoticeType.success,
      );
    }
  }
}

class _InternDetailDialog extends StatelessWidget {
  const _InternDetailDialog({required this.intern});

  final AdminInternRowDto intern;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final isPhone = screenWidth < 640;
    final isSmallPhone = screenWidth < 430;
    final statusColor = intern.active
        ? const Color(0xFF14735D)
        : const Color(0xFFB24A48);
    final trimmedName = intern.fullName.trim();
    final initial = trimmedName.isEmpty
        ? 'I'
        : trimmedName.substring(0, 1).toUpperCase();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isSmallPhone ? 12 : (isPhone ? 18 : 24),
        vertical: isPhone ? 16 : 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 720,
          maxHeight: screenHeight * (isPhone ? 0.9 : 0.84),
        ),
        child: AdminSectionCard(
          padding: EdgeInsets.all(isPhone ? 14 : 22),
          child: SelectionArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isPhone) ...[
                    Row(
                      children: [
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFFF2F5FB),
                            foregroundColor: adminNavy,
                            minimumSize: const Size(42, 42),
                          ),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [adminNavy, adminBlue],
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    intern.fullName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF182538),
                                      height: 1.1,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: statusColor.withValues(
                                          alpha: 0.28,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      intern.active ? 'Aktif' : 'Nonaktif',
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Ringkasan profil intern, penempatan, dan informasi sekolah.',
                                style: TextStyle(
                                  color: Color(0xFF5B6678),
                                  fontSize: 12.5,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [adminNavy, adminBlue],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    intern.fullName,
                                    style: const TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF182538),
                                      height: 1.05,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: statusColor.withValues(
                                          alpha: 0.28,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      intern.active ? 'Aktif' : 'Nonaktif',
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Ringkasan profil intern, penempatan, dan informasi sekolah.',
                                style: TextStyle(
                                  color: Color(0xFF5B6678),
                                  fontSize: 14,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFFF2F5FB),
                            foregroundColor: adminNavy,
                          ),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  SizedBox(height: isPhone ? 14 : 20),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isPhone ? 12 : 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          adminNavy.withValues(alpha: 0.08),
                          adminBlue.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFDDE6F3)),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final summaryCards = [
                          _DetailPill(
                            icon: Icons.badge_rounded,
                            label: 'NISN',
                            value: intern.nisn,
                            compact: isPhone,
                            stretch: true,
                          ),
                          _DetailPill(
                            icon: Icons.wc_rounded,
                            label: 'Gender',
                            value: intern.gender ?? '-',
                            compact: isPhone,
                            stretch: true,
                          ),
                          _DetailPill(
                            icon: Icons.email_rounded,
                            label: 'Email',
                            value: intern.email,
                            compact: isPhone,
                            stretch: true,
                          ),
                        ];
                        if (isPhone) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    size: 16,
                                    color: adminNavy,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Identitas Cepat',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1E2D44),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(child: summaryCards[0]),
                                  const SizedBox(width: 10),
                                  Expanded(child: summaryCards[1]),
                                ],
                              ),
                              const SizedBox(height: 10),
                              summaryCards[2],
                            ],
                          );
                        }
                        if (constraints.maxWidth >= 620) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    size: 18,
                                    color: adminNavy,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Identitas Cepat',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1E2D44),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(flex: 3, child: summaryCards[0]),
                                  const SizedBox(width: 10),
                                  Expanded(flex: 2, child: summaryCards[1]),
                                  const SizedBox(width: 10),
                                  Expanded(flex: 5, child: summaryCards[2]),
                                ],
                              ),
                            ],
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 18,
                                  color: adminNavy,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Identitas Cepat',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1E2D44),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: summaryCards[0]),
                                const SizedBox(width: 10),
                                Expanded(child: summaryCards[1]),
                              ],
                            ),
                            const SizedBox(height: 10),
                            summaryCards[2],
                          ],
                        );
                      },
                    ),
                  ),
                  SizedBox(height: isPhone ? 14 : 20),
                  _DetailSection(
                    title: 'Informasi Penempatan',
                    icon: Icons.apartment_rounded,
                    compact: isPhone,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final twoColumns = constraints.maxWidth >= 520;
                        final children = [
                          _DetailTile(
                            label: 'Unit',
                            value: intern.unitName,
                            icon: Icons.account_tree_rounded,
                            compact: isPhone,
                          ),
                          _DetailTile(
                            label: 'Mentor',
                            value: intern.mentorName ?? '-',
                            icon: Icons.support_agent_rounded,
                            compact: isPhone,
                          ),
                          _DetailTile(
                            label: 'Periode Mulai',
                            value: intern.internshipStart,
                            icon: Icons.event_available_rounded,
                            compact: isPhone,
                          ),
                          _DetailTile(
                            label: 'Periode Selesai',
                            value: intern.internshipEnd,
                            icon: Icons.event_busy_rounded,
                            compact: isPhone,
                          ),
                        ];
                        if (twoColumns) {
                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: children
                                .map(
                                  (child) => SizedBox(
                                    width: (constraints.maxWidth - 12) / 2,
                                    child: child,
                                  ),
                                )
                                .toList(),
                          );
                        }
                        return Column(
                          children:
                              children
                                  .expand(
                                    (child) => [
                                      child,
                                      const SizedBox(height: 12),
                                    ],
                                  )
                                  .toList()
                                ..removeLast(),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  _DetailSection(
                    title: 'Informasi Sekolah',
                    icon: Icons.school_rounded,
                    compact: isPhone,
                    child: Column(
                      children: [
                        _DetailTile(
                          label: 'Nama Sekolah',
                          value: intern.schoolName ?? '-',
                          icon: Icons.domain_rounded,
                          compact: isPhone,
                        ),
                        const SizedBox(height: 12),
                        _DetailTile(
                          label: 'Alamat Sekolah',
                          value: intern.schoolAddress ?? '-',
                          icon: Icons.location_on_rounded,
                          compact: isPhone,
                          multiLine: true,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isPhone ? 16 : 18),
                  SizedBox(
                    width: isPhone ? double.infinity : null,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: adminNavy,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: isPhone ? 16 : 18,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Tutup'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.icon,
    required this.child,
    this.compact = false,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 14 : 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCE4F1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: adminNavy, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: compact ? 15.5 : 17,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E2D44),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 12 : 14),
          child,
        ],
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.label,
    required this.value,
    required this.icon,
    this.multiLine = false,
    this.compact = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool multiLine;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3EAF5)),
      ),
      child: Row(
        crossAxisAlignment: multiLine
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Container(
            width: compact ? 34 : 38,
            height: compact ? 34 : 38,
            decoration: BoxDecoration(
              color: adminBlue.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: adminBlue, size: compact ? 18 : 20),
          ),
          SizedBox(width: compact ? 10 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF6B7688),
                  ),
                ),
                SizedBox(height: compact ? 4 : 5),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: compact ? 14 : 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1D293D),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailPill extends StatelessWidget {
  const _DetailPill({
    required this.icon,
    required this.label,
    required this.value,
    this.compact = false,
    this.stretch = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool compact;
  final bool stretch;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: stretch ? double.infinity : 280),
      child: Container(
        width: stretch ? double.infinity : null,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 12,
          vertical: compact ? 9 : 10,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFDCE4F1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: compact ? 15 : 16, color: adminNavy),
            SizedBox(width: compact ? 7 : 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: compact ? 10 : 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF728095),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: compact ? 12.5 : 13,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E2D44),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InternHeader extends StatelessWidget {
  const _InternHeader({
    required this.totalIntern,
    required this.activeIntern,
    required this.inactiveIntern,
    required this.compact,
    required this.loading,
  });

  final int totalIntern;
  final int activeIntern;
  final int inactiveIntern;
  final bool compact;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return AdminPageHeroPanel(
      icon: Icons.groups_rounded,
      title: 'Manajemen Intern PKL',
      subtitle:
          'Tambah, edit, dan atur status aktif intern dari satu panel yang sinkron untuk laptop dan HP.',
      compactBreakpoint: 920,
      rightPanel: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminHeroInfoTile(
            icon: Icons.groups_rounded,
            label: 'Total Intern',
            value: totalIntern.toString(),
            compact: compact,
          ),
          const SizedBox(height: 8),
          AdminHeroInfoTile(
            icon: Icons.check_circle_rounded,
            label: 'Intern Aktif',
            value: activeIntern.toString(),
            compact: compact,
          ),
          const SizedBox(height: 8),
          AdminHeroInfoTile(
            icon: Icons.person_off_rounded,
            label: 'Nonaktif',
            value: inactiveIntern.toString(),
            compact: compact,
          ),
          const SizedBox(height: 8),
          AdminHeroInfoTile(
            icon: loading ? Icons.sync_rounded : Icons.sync_alt_rounded,
            label: 'Sinkronisasi',
            value: loading ? 'Memuat' : 'Normal',
            compact: compact,
          ),
        ],
      ),
    );
  }
}

class _InternRecordCard extends StatelessWidget {
  const _InternRecordCard({
    required this.intern,
    required this.compact,
    required this.dense,
    required this.onOpen,
    required this.onEdit,
  });

  final AdminInternRowDto intern;
  final bool compact;
  final bool dense;
  final VoidCallback onOpen;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final initials = intern.fullName.trim().isEmpty
        ? 'I'
        : intern.fullName.trim().substring(0, 1).toUpperCase();
    final schoolName = (intern.schoolName ?? '').trim().isEmpty
        ? 'Sekolah belum diisi'
        : intern.schoolName!.trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(22),
        child: AdminSectionCard(
          padding: EdgeInsets.all(compact ? 14 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: compact ? 48 : 56,
                    height: compact ? 48 : 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [adminNavy, adminBlue],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: compact ? 20 : 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                intern.fullName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: compact ? 18 : 20,
                                  color: const Color(0xFF22324B),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _StatusChip(active: intern.active, compact: dense),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          schoolName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(0xFF667387),
                            fontSize: compact ? 12.5 : 13.5,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MiniValueChip(
                    label: 'NISN',
                    value: intern.nisn,
                    compact: dense,
                  ),
                  _MiniValueChip(
                    label: 'Gender',
                    value: intern.gender ?? '-',
                    compact: dense,
                  ),
                  _MiniValueChip(
                    label: 'Email',
                    value: intern.email,
                    compact: dense,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final columns = width >= 500 ? 2 : 1;
                  final spacing = 10.0;
                  final itemWidth = columns == 1
                      ? width
                      : (width - spacing) / 2;
                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: [
                      SizedBox(
                        width: itemWidth,
                        child: _InternInfoTile(
                          icon: Icons.apartment_rounded,
                          label: 'Unit',
                          value: intern.unitName,
                          compact: compact,
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: _InternInfoTile(
                          icon: Icons.person_search_rounded,
                          label: 'Pembimbing',
                          value: intern.mentorName ?? '-',
                          compact: compact,
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: _InternInfoTile(
                          icon: Icons.calendar_month_rounded,
                          label: 'Periode Mulai',
                          value: intern.internshipStart,
                          compact: compact,
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: _InternInfoTile(
                          icon: Icons.event_available_rounded,
                          label: 'Periode Selesai',
                          value: intern.internshipEnd,
                          compact: compact,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 12 : 14,
                  vertical: compact ? 11 : 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FAFF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFDCE4F1)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: compact ? 36 : 40,
                      height: compact ? 36 : 40,
                      decoration: BoxDecoration(
                        color: adminBlue.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.school_rounded, color: adminBlue),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Penempatan Sekolah',
                            style: TextStyle(
                              fontSize: compact ? 11.5 : 12.5,
                              color: const Color(0xFF69758A),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            schoolName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: compact ? 13.5 : 14.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF22324B),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onOpen,
                      icon: const Icon(Icons.visibility_rounded),
                      label: const Text('Detail'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('Edit'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InternInfoTile extends StatelessWidget {
  const _InternInfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.compact,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 11 : 12,
        vertical: compact ? 10 : 11,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE4F1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: compact ? 34 : 38,
            height: compact ? 34 : 38,
            decoration: BoxDecoration(
              color: adminBlue.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: adminBlue, size: compact ? 18 : 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF6A768A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 13.5 : 14.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF21314B),
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.active, this.compact = false});

  final bool active;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.green : Colors.red;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 8,
        vertical: compact ? 3.5 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        active ? 'Aktif' : 'Nonaktif',
        style: TextStyle(
          color: color.shade700,
          fontWeight: FontWeight.w700,
          fontSize: compact ? 11 : 12,
        ),
      ),
    );
  }
}

class _MiniValueChip extends StatelessWidget {
  const _MiniValueChip({
    required this.label,
    required this.value,
    this.compact = false,
  });

  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 8,
        vertical: compact ? 3.5 : 4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F6FC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFDCE4F1)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: const Color(0xFF445062),
          fontWeight: FontWeight.w700,
          fontSize: compact ? 11 : 12,
        ),
      ),
    );
  }
}

class _InternPayload {
  _InternPayload({
    required this.nisn,
    required this.gender,
    required this.fullName,
    required this.unitId,
    required this.mentorUserId,
    required this.start,
    required this.end,
    required this.schoolName,
    required this.schoolAddress,
    required this.password,
    required this.active,
  });

  final String nisn;
  final String? gender;
  final String fullName;
  final int unitId;
  final int? mentorUserId;
  final String start;
  final String end;
  final String schoolName;
  final String schoolAddress;
  final String password;
  final bool active;
}

class _InternDialog extends StatefulWidget {
  const _InternDialog({
    required this.units,
    required this.mentors,
    this.initial,
  });

  final List<UnitDto> units;
  final List<MentorMiniDto> mentors;
  final AdminInternRowDto? initial;

  @override
  State<_InternDialog> createState() => _InternDialogState();
}

class _InternDialogState extends State<_InternDialog> {
  final nisn = TextEditingController();
  final name = TextEditingController();
  final schoolName = TextEditingController();
  final schoolAddress = TextEditingController();
  final start = TextEditingController();
  final end = TextEditingController();
  final password = TextEditingController();
  String? gender;
  int? unitId;
  int? mentorUserId;
  PublicSchoolDto? selectedSchool;
  List<PublicSchoolDto> schools = const [];
  String schoolQuery = '';
  bool schoolLoading = false;
  bool active = true;

  bool get isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    if (widget.initial != null) {
      final it = widget.initial!;
      nisn.text = it.nisn;
      gender = it.gender;
      name.text = it.fullName;
      schoolName.text = it.schoolName ?? '';
      schoolAddress.text = it.schoolAddress ?? '';
      if (schoolName.text.isNotEmpty) {
        selectedSchool = PublicSchoolDto(
          id: '',
          name: schoolName.text,
          city: null,
          address: schoolAddress.text,
          npsn: null,
        );
      }
      start.text = it.internshipStart;
      end.text = it.internshipEnd;
      unitId = it.unitId;
      mentorUserId = it.mentorUserId;
      active = it.active;
    } else {
      start.text = today;
      end.text = today;
      if (widget.units.isNotEmpty) unitId = widget.units.first.id;
    }
  }

  @override
  void dispose() {
    nisn.dispose();
    name.dispose();
    schoolName.dispose();
    schoolAddress.dispose();
    start.dispose();
    end.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isPhone = screenWidth < 640;
    final isSmallPhone = screenWidth < 430;
    return AdminFormDialogShell(
      title: isEdit ? 'Edit Intern' : 'Tambah Intern',
      subtitle: isEdit
          ? 'Perbarui data intern, penempatan, dan status aksesnya.'
          : 'Lengkapi data akun intern, sekolah, dan penempatan PKL.',
      icon: Icons.person_rounded,
      maxWidth: 640,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminFormSection(
            title: 'Data Akun',
            icon: Icons.badge_rounded,
            compact: isPhone,
            child: Column(
              children: [
                TextField(
                  controller: nisn,
                  decoration: adminDialogFieldDecoration(label: 'NISN'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: name,
                  decoration: adminDialogFieldDecoration(label: 'Nama Lengkap'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: gender,
                  decoration: adminDialogFieldDecoration(label: 'Gender'),
                  items: const [
                    DropdownMenuItem<String?>(value: null, child: Text('-')),
                    DropdownMenuItem<String?>(
                      value: 'L',
                      child: Text('Laki-laki (L)'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'P',
                      child: Text('Perempuan (P)'),
                    ),
                  ],
                  onChanged: (v) => setState(() => gender = v),
                ),
                const SizedBox(height: 12),
                if (isEdit)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? const Color(0xFFE9F7F0)
                          : const Color(0xFFFCEDEC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: active
                            ? const Color(0xFFB9E1D0)
                            : const Color(0xFFF0C3C0),
                      ),
                    ),
                    child: SwitchListTile(
                      value: active,
                      onChanged: (v) => setState(() => active = v),
                      title: const Text(
                        'Status Akun Aktif',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        active
                            ? 'Intern bisa login dan menggunakan aplikasi.'
                            : 'Intern tidak dapat login sampai diaktifkan lagi.',
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  )
                else
                  TextField(
                    controller: password,
                    decoration: adminDialogFieldDecoration(
                      label: 'Password sementara',
                      hintText: 'Kosongkan untuk generate otomatis',
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AdminFormSection(
            title: 'Informasi Sekolah',
            icon: Icons.school_rounded,
            compact: isPhone,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: schoolName,
                  decoration: adminDialogFieldDecoration(label: 'Asal Sekolah'),
                ),
                const SizedBox(height: 10),
                if (isSmallPhone)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _pickSchool,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: adminNavy,
                          side: const BorderSide(color: Color(0xFFD5DFEE)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.search_rounded),
                        label: const Text('Cari SMK'),
                      ),
                      if (selectedSchool != null) ...[
                        const SizedBox(height: 8),
                        _SelectedSchoolBanner(name: selectedSchool!.name),
                      ],
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: OutlinedButton.icon(
                          onPressed: _pickSchool,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: adminNavy,
                            side: const BorderSide(color: Color(0xFFD5DFEE)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(Icons.search_rounded),
                          label: const Text('Cari SMK'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 3,
                        child: _SelectedSchoolBanner(
                          name:
                              selectedSchool?.name ??
                              'Belum ada sekolah dipilih',
                          muted: selectedSchool == null,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: schoolAddress,
                  decoration: adminDialogFieldDecoration(
                    label: 'Alamat Sekolah (opsional)',
                  ),
                  minLines: 2,
                  maxLines: 3,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AdminFormSection(
            title: 'Penempatan PKL',
            icon: Icons.apartment_rounded,
            compact: isPhone,
            child: Column(
              children: [
                DropdownButtonFormField<int>(
                  initialValue: unitId,
                  decoration: adminDialogFieldDecoration(label: 'Unit'),
                  items: widget.units
                      .map(
                        (u) =>
                            DropdownMenuItem(value: u.id, child: Text(u.name)),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => unitId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  initialValue: mentorUserId,
                  decoration: adminDialogFieldDecoration(
                    label: 'Pembimbing (opsional)',
                  ),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('-')),
                    ...widget.mentors.map(
                      (m) => DropdownMenuItem<int?>(
                        value: m.id,
                        child: Text(
                          m.fullName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => mentorUserId = v),
                ),
                const SizedBox(height: 12),
                if (isSmallPhone)
                  Column(
                    children: [
                      TextField(
                        controller: start,
                        readOnly: true,
                        decoration: adminDialogFieldDecoration(
                          label: 'Mulai',
                          suffixIcon: const Icon(Icons.calendar_month_outlined),
                        ),
                        onTap: () => _pickInternDate(start),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: end,
                        readOnly: true,
                        decoration: adminDialogFieldDecoration(
                          label: 'Selesai',
                          suffixIcon: const Icon(Icons.calendar_month_outlined),
                        ),
                        onTap: () => _pickInternDate(end),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: start,
                          readOnly: true,
                          decoration: adminDialogFieldDecoration(
                            label: 'Mulai',
                            suffixIcon: const Icon(
                              Icons.calendar_month_outlined,
                            ),
                          ),
                          onTap: () => _pickInternDate(start),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: end,
                          readOnly: true,
                          decoration: adminDialogFieldDecoration(
                            label: 'Selesai',
                            suffixIcon: const Icon(
                              Icons.calendar_month_outlined,
                            ),
                          ),
                          onTap: () => _pickInternDate(end),
                        ),
                      ),
                    ],
                  ),
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
              if (unitId == null) return;
              Navigator.of(context).pop(
                _InternPayload(
                  nisn: nisn.text.trim(),
                  gender: gender,
                  fullName: name.text.trim(),
                  unitId: unitId!,
                  mentorUserId: mentorUserId,
                  start: start.text.trim(),
                  end: end.text.trim(),
                  schoolName: schoolName.text.trim(),
                  schoolAddress: schoolAddress.text.trim(),
                  password: password.text.trim(),
                  active: active,
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

  Future<void> _pickInternDate(TextEditingController controller) async {
    final now = DateTime.now();
    DateTime initialDate = now;
    try {
      if (controller.text.trim().isNotEmpty) {
        initialDate = DateTime.parse(controller.text.trim());
      }
    } catch (_) {
      initialDate = now;
    }

    final picked = await showAdminDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2100, 12, 31),
    );
    if (picked == null || !mounted) return;

    final month = picked.month.toString().padLeft(2, '0');
    final day = picked.day.toString().padLeft(2, '0');
    setState(() {
      controller.text = '${picked.year}-$month-$day';
    });
  }

  Future<void> _searchSchools({String query = '', StateSetter? refresh}) async {
    void update(VoidCallback fn) {
      if (mounted) setState(fn);
      if (refresh != null) refresh(fn);
    }

    update(() {
      schoolQuery = query.trim();
      schoolLoading = true;
      schools = const []; // kosongkan agar hasil lama hilang saat fetch baru
    });
    final scope = AppScope.of(context);
    try {
      final path =
          '/api/public/schools?q=${Uri.encodeComponent(query)}&level=SMK&limit=40';
      final data = await scope.apiClient.getJson(path);
      final list = data is List
          ? data
          : (data is Map && data['data'] is List)
          ? data['data'] as List
          : <dynamic>[];
      final qUpper = schoolQuery.toUpperCase();
      final mapped = list
          .whereType<Map>()
          .map((e) => PublicSchoolDto.fromJson(Map<String, dynamic>.from(e)))
          .where((s) {
            if (qUpper.isEmpty) return true;
            final hay = '${s.name} ${s.city ?? ''} ${s.npsn ?? ''}'
                .toUpperCase();
            return hay.contains(qUpper);
          })
          .toList();
      // debug log
      // ignore: avoid_print
      print(
        'School search query="$query" raw=${list.length} mapped=${mapped.length}',
      );
      update(() {
        schools = mapped;
      });
    } catch (_) {
      update(() => schools = const []);
    } finally {
      update(() => schoolLoading = false);
    }
  }

  Future<void> _pickSchool() async {
    await _searchSchools();
    if (!mounted) return;
    final query = TextEditingController();
    final picked = await showDialog<PublicSchoolDto>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, dialogSetState) {
          final screenWidth = MediaQuery.sizeOf(context).width;
          final isPhone = screenWidth < 640;
          final isSmallPhone = screenWidth < 430;
          if (isPhone) {
            return AlertDialog(
              insetPadding: EdgeInsets.symmetric(
                horizontal: isSmallPhone ? 12 : 16,
                vertical: 24,
              ),
              title: const Text('Pilih Sekolah (SMK)'),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      children: [
                        TextField(
                          controller: query,
                          decoration: const InputDecoration(
                            labelText: 'Cari nama / kota / NPSN',
                          ),
                          onSubmitted: (v) =>
                              _searchSchools(query: v, refresh: dialogSetState),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () => _searchSchools(
                              query: query.text.trim(),
                              refresh: dialogSetState,
                            ),
                            child: const Text('Cari'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 280,
                      child: schoolLoading
                          ? const Center(child: CircularProgressIndicator())
                          : () {
                              final qUpper = schoolQuery.toUpperCase();
                              final results = List<PublicSchoolDto>.from(
                                schools.where((s) {
                                  if (qUpper.isEmpty) return true;
                                  final hay =
                                      '${s.name} ${s.city ?? ''} ${s.npsn ?? ''}'
                                          .toUpperCase();
                                  return hay.contains(qUpper);
                                }),
                              );
                              if (results.isEmpty) {
                                return const Center(
                                  child: Text('Tidak ada hasil'),
                                );
                              }
                              return ListView.separated(
                                itemCount: results.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, i) {
                                  final s = results[i];
                                  final subtitle = [
                                    if (s.npsn != null && s.npsn!.isNotEmpty)
                                      'NPSN ${s.npsn}',
                                    if (s.city != null && s.city!.isNotEmpty)
                                      s.city!,
                                  ].join(' - ');
                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 2,
                                    ),
                                    title: Text(
                                      s.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: subtitle.isEmpty
                                        ? null
                                        : Text(
                                            subtitle,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                    onTap: () => Navigator.of(context).pop(s),
                                  );
                                },
                              );
                            }(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Tutup'),
                ),
              ],
            );
          }
          return AlertDialog(
            title: const Text('Pilih Sekolah (SMK)'),
            content: SizedBox(
              width: 520,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: query,
                          decoration: const InputDecoration(
                            labelText: 'Cari nama / kota / NPSN',
                          ),
                          onSubmitted: (v) =>
                              _searchSchools(query: v, refresh: dialogSetState),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () => _searchSchools(
                          query: query.text.trim(),
                          refresh: dialogSetState,
                        ),
                        child: const Text('Cari'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 320,
                    child: schoolLoading
                        ? const Center(child: CircularProgressIndicator())
                        : () {
                            final qUpper = schoolQuery.toUpperCase();
                            final results = List<PublicSchoolDto>.from(
                              schools.where((s) {
                                if (qUpper.isEmpty) return true;
                                final hay =
                                    '${s.name} ${s.city ?? ''} ${s.npsn ?? ''}'
                                        .toUpperCase();
                                return hay.contains(qUpper);
                              }),
                            );
                            if (results.isEmpty) {
                              return const Center(
                                child: Text('Tidak ada hasil'),
                              );
                            }
                            return ListView.separated(
                              itemCount: results.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, i) {
                                final s = results[i];
                                final subtitle = [
                                  if (s.npsn != null && s.npsn!.isNotEmpty)
                                    'NPSN ${s.npsn}',
                                  if (s.city != null && s.city!.isNotEmpty)
                                    s.city!,
                                ].join(' • ');
                                return ListTile(
                                  title: Text(s.name),
                                  subtitle: subtitle.isEmpty
                                      ? null
                                      : Text(subtitle),
                                  onTap: () => Navigator.of(context).pop(s),
                                );
                              },
                            );
                          }(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Tutup'),
              ),
            ],
          );
        },
      ),
    );
    query.dispose();
    if (picked != null) {
      setState(() {
        selectedSchool = picked;
        schoolName.text = picked.name;
        schoolAddress.text = picked.address ?? '';
      });
    }
  }
}

class _SelectedSchoolBanner extends StatelessWidget {
  const _SelectedSchoolBanner({required this.name, this.muted = false});

  final String name;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: muted ? const Color(0xFFF7F9FD) : const Color(0xFFEEF4FD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: muted ? const Color(0xFFDCE4F1) : const Color(0xFFC9D8EF),
        ),
      ),
      child: Row(
        children: [
          Icon(
            muted ? Icons.info_outline_rounded : Icons.check_circle_rounded,
            size: 18,
            color: muted ? const Color(0xFF748196) : adminBlue,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: muted
                    ? const Color(0xFF748196)
                    : const Color(0xFF1E2D44),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeletePayload {
  _DeletePayload({required this.force});

  final bool force;
}

class _DeleteInternDialog extends StatefulWidget {
  const _DeleteInternDialog({required this.name});

  final String name;

  @override
  State<_DeleteInternDialog> createState() => _DeleteInternDialogState();
}

class _DeleteInternDialogState extends State<_DeleteInternDialog> {
  final confirm = TextEditingController();
  bool force = false;

  @override
  void dispose() {
    confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isPhone = screenWidth < 640;
    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isPhone ? 12 : 24,
        vertical: 24,
      ),
      title: const Text('Hapus Permanen'),
      content: ConstrainedBox(
        constraints: BoxConstraints(minWidth: isPhone ? 0 : 360, maxWidth: 460),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'PERINGATAN KERAS:\n'
                'Hapus permanen akan menghapus akun intern dan (jika force) seluruh riwayat absensi/izin.\n\n'
                'Intern: ${widget.name}',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirm,
                decoration: const InputDecoration(
                  labelText: 'Ketik HAPUS untuk konfirmasi',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: force,
                onChanged: (v) => setState(() => force = v ?? false),
                title: const Text('Force delete (hapus riwayat)'),
                subtitle: const Text(
                  'Jika intern punya riwayat, ini wajib untuk menghapus permanen.',
                ),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: confirm.text.trim().toUpperCase() == 'HAPUS'
              ? () => Navigator.of(context).pop(_DeletePayload(force: force))
              : null,
          child: const Text('Hapus'),
        ),
      ],
    );
  }
}
