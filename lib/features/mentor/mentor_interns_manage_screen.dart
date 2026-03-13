import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/ui/app_notice.dart';
import '../../core/models/leave_models.dart';
import '../../core/models/public_school_models.dart';
import '../../core/models/unit_models.dart';
import '../admin/admin_style.dart';
import 'mentor_interns_manage_view_model.dart';

class MentorInternsManageScreen extends StatefulWidget {
  const MentorInternsManageScreen({super.key});

  @override
  State<MentorInternsManageScreen> createState() =>
      _MentorInternsManageScreenState();
}

class _MentorInternsManageScreenState extends State<MentorInternsManageScreen> {
  MentorInternsManageViewModel? _vm;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_vm != null) return;
    final scope = AppScope.of(context);
    _vm = MentorInternsManageViewModel(
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
      appBar: AppBar(title: const Text('Data Intern (Bimbingan)')),
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) {
          final screenWidth = MediaQuery.sizeOf(context).width;
          final isPhone = screenWidth < 640;
          final totalSchool = vm.interns
              .map((e) => (e.schoolName ?? '').trim())
              .where((e) => e.isNotEmpty)
              .toSet()
              .length;
          return AdminPageBackground(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1260),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isPhone ? 10 : 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DashboardReveal(
                        delay: const Duration(milliseconds: 40),
                        child: _MentorInternHeader(
                          totalIntern: vm.interns.length,
                          activeIntern: vm.interns
                              .where((e) => e.active)
                              .length,
                          totalSchool: totalSchool,
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
                        delay: const Duration(milliseconds: 100),
                        child: AdminSectionCard(
                          padding: EdgeInsets.all(isPhone ? 10 : 14),
                          child: vm.loading && vm.interns.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 54),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : vm.interns.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 54),
                                  child: Center(
                                    child: Text('Belum ada intern bimbingan.'),
                                  ),
                                )
                              : LayoutBuilder(
                                  builder: (context, constraints) {
                                    final width = constraints.maxWidth;
                                    final columns = width >= 980 ? 2 : 1;
                                    const spacing = 12.0;
                                    final itemWidth = columns == 1
                                        ? width
                                        : (width - spacing) / 2;
                                    return Wrap(
                                      spacing: spacing,
                                      runSpacing: spacing,
                                      children: [
                                        for (final it in vm.interns)
                                          SizedBox(
                                            width: itemWidth,
                                            child: _MentorInternCard(
                                              intern: it,
                                              compact: isPhone,
                                              onOpen: () =>
                                                  _detail(context, it),
                                              onEdit: () =>
                                                  _edit(context, vm, it),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
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

  Future<void> _detail(BuildContext context, InternDto it) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _MentorInternDetailDialog(intern: it),
    );
  }

  Future<void> _edit(
    BuildContext context,
    MentorInternsManageViewModel vm,
    InternDto it,
  ) async {
    final res = await showDialog<_MentorInternPayload>(
      context: context,
      builder: (context) => _MentorInternDialog(intern: it, units: vm.units),
    );
    if (res == null) return;
    final ok = await vm.update(
      userId: it.userId,
      fullName: res.fullName,
      nisn: res.nisn,
      gender: res.gender,
      unitId: res.unitId,
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

class _MentorInternCard extends StatelessWidget {
  const _MentorInternCard({
    required this.intern,
    required this.compact,
    required this.onOpen,
    required this.onEdit,
  });

  final InternDto intern;
  final bool compact;
  final VoidCallback onOpen;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final trimmedName = intern.fullName.trim();
    final initials = trimmedName.isEmpty
        ? 'I'
        : trimmedName.substring(0, 1).toUpperCase();
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
                  _MentorInitialAvatar(
                    initial: initials,
                    size: compact ? 52 : 60,
                    radius: 18,
                    fontSize: compact ? 24 : 28,
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
                            _ActiveChip(active: intern.active),
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
                  _MiniValueChip(label: 'NISN', value: intern.nisn),
                  _MiniValueChip(label: 'Gender', value: intern.gender ?? '-'),
                  _MiniValueChip(label: 'Email', value: intern.email),
                ],
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final columns = width >= 500 ? 2 : 1;
                  const spacing = 10.0;
                  final itemWidth = columns == 1
                      ? width
                      : (width - spacing) / 2;
                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: [
                      SizedBox(
                        width: itemWidth,
                        child: _MentorCardInfoTile(
                          label: 'Unit',
                          value: intern.unitName,
                          icon: Icons.account_tree_rounded,
                          compact: compact,
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: _MentorCardInfoTile(
                          label: 'Status Akun',
                          value: intern.active ? 'Aktif' : 'Nonaktif',
                          icon: Icons.verified_user_rounded,
                          compact: compact,
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: _MentorCardInfoTile(
                          label: 'Periode Mulai',
                          value: intern.internshipStart,
                          icon: Icons.event_available_rounded,
                          compact: compact,
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: _MentorCardInfoTile(
                          label: 'Periode Selesai',
                          value: intern.internshipEnd,
                          icon: Icons.event_busy_rounded,
                          compact: compact,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              _MentorCardInfoTile(
                label: 'Penempatan Sekolah',
                value: schoolName,
                icon: Icons.school_rounded,
                compact: compact,
              ),
              const SizedBox(height: 12),
              if (compact)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OutlinedButton.icon(
                      onPressed: onOpen,
                      icon: const Icon(Icons.visibility_rounded),
                      label: const Text('Detail'),
                    ),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('Edit'),
                    ),
                  ],
                )
              else
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

class _MentorInternHeader extends StatelessWidget {
  const _MentorInternHeader({
    required this.totalIntern,
    required this.activeIntern,
    required this.totalSchool,
  });

  final int totalIntern;
  final int activeIntern;
  final int totalSchool;

  @override
  Widget build(BuildContext context) {
    final isPhone = MediaQuery.sizeOf(context).width < 640;
    return AdminPageHeroPanel(
      icon: Icons.groups_2_rounded,
      title: 'Data Intern Bimbingan',
      subtitle:
          'Lihat data intern yang dibimbing, update profil intern, dan atur status aktif.',
      compactBreakpoint: 920,
      rightPanel: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminHeroInfoTile(
            icon: Icons.badge_rounded,
            label: 'Total Intern',
            value: totalIntern.toString(),
            compact: isPhone,
          ),
          const SizedBox(height: 8),
          AdminHeroInfoTile(
            icon: Icons.check_circle_rounded,
            label: 'Intern Aktif',
            value: activeIntern.toString(),
            compact: isPhone,
          ),
          const SizedBox(height: 8),
          AdminHeroInfoTile(
            icon: Icons.school_rounded,
            label: 'Sekolah Terlibat',
            value: totalSchool.toString(),
            compact: isPhone,
          ),
        ],
      ),
    );
  }
}

class _MentorCardInfoTile extends StatelessWidget {
  const _MentorCardInfoTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.compact,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 10 : 11,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE4F1)),
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 34 : 36,
            height: compact ? 34 : 36,
            decoration: BoxDecoration(
              color: adminBlue.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
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
                    fontSize: compact ? 11 : 11.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF6B7688),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 13 : 13.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1D293D),
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

class _MentorInternDetailDialog extends StatelessWidget {
  const _MentorInternDetailDialog({required this.intern});

  final InternDto intern;

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
                        _MentorInitialAvatar(
                          initial: initial,
                          size: 58,
                          radius: 18,
                          fontSize: 26,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MentorInternDetailHeader(
                            name: intern.fullName,
                            active: intern.active,
                            statusColor: statusColor,
                            compact: true,
                          ),
                        ),
                      ],
                    ),
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _MentorInitialAvatar(
                          initial: initial,
                          size: 68,
                          radius: 20,
                          fontSize: 30,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _MentorInternDetailHeader(
                            name: intern.fullName,
                            active: intern.active,
                            statusColor: statusColor,
                            compact: false,
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
                          _MentorDetailPill(
                            icon: Icons.badge_rounded,
                            label: 'NISN',
                            value: intern.nisn,
                            compact: isPhone,
                            stretch: true,
                          ),
                          _MentorDetailPill(
                            icon: Icons.wc_rounded,
                            label: 'Gender',
                            value: intern.gender ?? '-',
                            compact: isPhone,
                            stretch: true,
                          ),
                          _MentorDetailPill(
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
                  _MentorDetailSection(
                    title: 'Informasi Penempatan',
                    icon: Icons.apartment_rounded,
                    compact: isPhone,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final twoColumns = constraints.maxWidth >= 520;
                        final children = [
                          _MentorDetailTile(
                            label: 'Unit',
                            value: intern.unitName,
                            icon: Icons.account_tree_rounded,
                            compact: isPhone,
                          ),
                          _MentorDetailTile(
                            label: 'Status Akun',
                            value: intern.active ? 'Aktif' : 'Nonaktif',
                            icon: Icons.verified_user_rounded,
                            compact: isPhone,
                          ),
                          _MentorDetailTile(
                            label: 'Periode Mulai',
                            value: intern.internshipStart,
                            icon: Icons.event_available_rounded,
                            compact: isPhone,
                          ),
                          _MentorDetailTile(
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
                  _MentorDetailSection(
                    title: 'Informasi Sekolah',
                    icon: Icons.school_rounded,
                    compact: isPhone,
                    child: Column(
                      children: [
                        _MentorDetailTile(
                          label: 'Nama Sekolah',
                          value: intern.schoolName ?? '-',
                          icon: Icons.domain_rounded,
                          compact: isPhone,
                        ),
                        const SizedBox(height: 12),
                        _MentorDetailTile(
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

class _MentorInitialAvatar extends StatelessWidget {
  const _MentorInitialAvatar({
    required this.initial,
    required this.size,
    required this.radius,
    required this.fontSize,
  });

  final String initial;
  final double size;
  final double radius;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [adminNavy, adminBlue],
        ),
        borderRadius: BorderRadius.circular(radius),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MentorInternDetailHeader extends StatelessWidget {
  const _MentorInternDetailHeader({
    required this.name,
    required this.active,
    required this.statusColor,
    required this.compact,
  });

  final String name;
  final bool active;
  final Color statusColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              name,
              style: TextStyle(
                fontSize: compact ? 18 : 30,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF182538),
                height: compact ? 1.1 : 1.05,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 9 : 12,
                vertical: compact ? 4 : 6,
              ),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: statusColor.withValues(alpha: 0.28)),
              ),
              child: Text(
                active ? 'Aktif' : 'Nonaktif',
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w800,
                  fontSize: compact ? 11 : 12,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: compact ? 6 : 8),
        Text(
          'Ringkasan profil intern, penempatan, dan informasi sekolah.',
          style: TextStyle(
            color: const Color(0xFF5B6678),
            fontSize: compact ? 12.5 : 14,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _MentorDetailSection extends StatelessWidget {
  const _MentorDetailSection({
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

class _MentorDetailTile extends StatelessWidget {
  const _MentorDetailTile({
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

class _MentorDetailPill extends StatelessWidget {
  const _MentorDetailPill({
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

class _MiniValueChip extends StatelessWidget {
  const _MiniValueChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F6FC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFDCE4F1)),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: Color(0xFF445062),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ActiveChip extends StatelessWidget {
  const _ActiveChip({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF14735D) : const Color(0xFFB24A48);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Text(
        active ? 'Aktif' : 'Nonaktif',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _MentorSelectedSchoolBanner extends StatelessWidget {
  const _MentorSelectedSchoolBanner({required this.name, this.muted = false});

  final String name;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: muted
            ? const Color(0xFFF4F7FD)
            : adminBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: muted
              ? const Color(0xFFD5DFEE)
              : adminBlue.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.school_rounded,
            size: 18,
            color: muted ? const Color(0xFF8190A7) : adminBlue,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: muted
                    ? const Color(0xFF6A778C)
                    : const Color(0xFF21314B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MentorInternPayload {
  _MentorInternPayload({
    required this.nisn,
    required this.gender,
    required this.fullName,
    required this.unitId,
    required this.start,
    required this.end,
    required this.schoolName,
    required this.schoolAddress,
    required this.active,
  });

  final String nisn;
  final String? gender;
  final String fullName;
  final int unitId;
  final String start;
  final String end;
  final String schoolName;
  final String schoolAddress;
  final bool active;
}

class _MentorInternDialog extends StatefulWidget {
  const _MentorInternDialog({required this.intern, required this.units});

  final InternDto intern;
  final List<UnitDto> units;

  @override
  State<_MentorInternDialog> createState() => _MentorInternDialogState();
}

class _MentorInternDialogState extends State<_MentorInternDialog> {
  late final TextEditingController nisn;
  late final TextEditingController name;
  late final TextEditingController schoolName;
  late final TextEditingController schoolAddress;
  late final TextEditingController start;
  late final TextEditingController end;
  int? unitId;
  String? gender;
  PublicSchoolDto? selectedSchool;
  List<PublicSchoolDto> schools = const [];
  String schoolQuery = '';
  bool schoolLoading = false;
  bool active = true;

  @override
  void initState() {
    super.initState();
    nisn = TextEditingController(text: widget.intern.nisn);
    name = TextEditingController(text: widget.intern.fullName);
    schoolName = TextEditingController(text: widget.intern.schoolName ?? '');
    schoolAddress = TextEditingController(
      text: widget.intern.schoolAddress ?? '',
    );
    if (schoolName.text.isNotEmpty) {
      selectedSchool = PublicSchoolDto(
        id: '',
        name: schoolName.text,
        city: null,
        address: schoolAddress.text,
        npsn: null,
      );
    }
    start = TextEditingController(text: widget.intern.internshipStart);
    end = TextEditingController(text: widget.intern.internshipEnd);
    unitId = widget.intern.unitId;
    gender = widget.intern.gender;
    active = widget.intern.active;
  }

  @override
  void dispose() {
    nisn.dispose();
    name.dispose();
    schoolName.dispose();
    schoolAddress.dispose();
    start.dispose();
    end.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isPhone = screenWidth < 640;
    final isSmallPhone = screenWidth < 430;
    return AdminFormDialogShell(
      title: 'Edit Intern',
      subtitle: 'Perbarui data intern, penempatan, dan status aksesnya.',
      icon: Icons.person_rounded,
      maxWidth: 620,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminFormSection(
            title: 'Data Intern',
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
                        _MentorSelectedSchoolBanner(name: selectedSchool!.name),
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
                        child: _MentorSelectedSchoolBanner(
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
            onPressed: unitId == null
                ? null
                : () => Navigator.of(context).pop(
                    _MentorInternPayload(
                      nisn: nisn.text.trim(),
                      gender: gender,
                      fullName: name.text.trim(),
                      unitId: unitId!,
                      start: start.text.trim(),
                      end: end.text.trim(),
                      schoolName: schoolName.text.trim(),
                      schoolAddress: schoolAddress.text.trim(),
                      active: active,
                    ),
                  ),
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
      if (mounted) {
        setState(fn);
      }
      if (refresh != null) {
        refresh(fn);
      }
    }

    update(() {
      schoolQuery = query.trim();
      schoolLoading = true;
      schools = const [];
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
            if (qUpper.isEmpty) {
              return true;
            }
            final hay = '${s.name} ${s.city ?? ''} ${s.npsn ?? ''}'
                .toUpperCase();
            return hay.contains(qUpper);
          })
          .toList();
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
    if (!mounted) {
      return;
    }
    final query = TextEditingController();
    final picked = await showDialog<PublicSchoolDto>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, dialogSetState) => AlertDialog(
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
                              if (qUpper.isEmpty) {
                                return true;
                              }
                              final hay =
                                  '${s.name} ${s.city ?? ''} ${s.npsn ?? ''}'
                                      .toUpperCase();
                              return hay.contains(qUpper);
                            }),
                          );
                          if (results.isEmpty) {
                            return const Center(child: Text('Tidak ada hasil'));
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
                              ].join(' | ');
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
        ),
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
