import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/models/admin_user_models.dart';
import '../../core/ui/app_notice.dart';
import 'admin_mentors_view_model.dart';
import 'admin_style.dart';

class AdminMentorsScreen extends StatefulWidget {
  const AdminMentorsScreen({super.key});

  @override
  State<AdminMentorsScreen> createState() => _AdminMentorsScreenState();
}

class _AdminMentorsScreenState extends State<AdminMentorsScreen> {
  AdminMentorsViewModel? _vm;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_vm != null) return;
    final scope = AppScope.of(context);
    _vm = AdminMentorsViewModel(
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
      appBar: AppBar(title: const Text('Kelola Mentor')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, vm),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Tambah Mentor'),
      ),
      body: ListenableBuilder(
        listenable: vm,
        builder: (_, __) {
          return AdminPageBackground(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1260),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _MentorHeader(totalMentor: vm.mentors.length),
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
                        padding: EdgeInsets.all(14),
                        child: vm.loading && vm.mentors.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 48),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : vm.mentors.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 48),
                                child: Center(
                                  child: Text('Belum ada data mentor.'),
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
                                      for (final mentor in vm.mentors)
                                        SizedBox(
                                          width: itemWidth,
                                          child: _MentorRecordCard(
                                            mentor: mentor,
                                            compact: width < 640,
                                            onEdit: () => _openForm(
                                              context,
                                              vm,
                                              mentor: mentor,
                                            ),
                                            onDelete: () =>
                                                _delete(context, vm, mentor),
                                          ),
                                        ),
                                    ],
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

  Future<void> _openForm(
    BuildContext context,
    AdminMentorsViewModel vm, {
    MentorMiniDto? mentor,
  }) async {
    final res = await showDialog<_MentorFormResult>(
      context: context,
      builder: (_) => _MentorFormDialog(mentor: mentor),
    );
    if (res == null) return;
    if (mentor == null) {
      await vm.createMentor(
        email: res.email,
        fullName: res.fullName,
        workUnit: res.workUnit,
        password: res.password,
      );
    } else {
      await vm.updateMentor(
        id: mentor.id,
        email: res.email,
        fullName: res.fullName,
        workUnit: res.workUnit,
        password: res.password,
      );
    }
    if (!context.mounted) return;
    if (vm.error == null) {
      AppNotice.show(
        context,
        mentor == null ? 'Mentor dibuat.' : 'Mentor diperbarui.',
        type: AppNoticeType.success,
      );
    }
  }

  Future<void> _delete(
    BuildContext context,
    AdminMentorsViewModel vm,
    MentorMiniDto mentor,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Mentor'),
        content: Text(
          'Hapus mentor "${mentor.fullName}"? Intern yang di-bimbing akan kehilangan mentor.',
        ),
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
    if (ok != true) return;
    await vm.deleteMentor(mentor.id);
    if (!context.mounted) return;
    if (vm.error == null) {
      AppNotice.show(context, 'Mentor dihapus.', type: AppNoticeType.success);
    }
  }
}

class _MentorHeader extends StatelessWidget {
  const _MentorHeader({required this.totalMentor});

  final int totalMentor;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 640;
    return AdminPageHeroPanel(
      icon: Icons.school_rounded,
      title: 'Data Mentor',
      subtitle: 'Kelola akun mentor untuk kebutuhan pembimbing PKL.',
      rightPanel: Column(
        children: [
          AdminHeroInfoTile(
            icon: Icons.groups_rounded,
            label: 'Total Mentor',
            value: totalMentor.toString(),
            compact: compact,
          ),
        ],
      ),
    );
  }
}

class _MentorFormResult {
  _MentorFormResult({
    required this.email,
    required this.fullName,
    required this.workUnit,
    this.password,
  });

  final String email;
  final String fullName;
  final String workUnit;
  final String? password;
}

class _MentorFormDialog extends StatefulWidget {
  const _MentorFormDialog({this.mentor});

  final MentorMiniDto? mentor;

  @override
  State<_MentorFormDialog> createState() => _MentorFormDialogState();
}

class _MentorFormDialogState extends State<_MentorFormDialog> {
  late final TextEditingController email;
  late final TextEditingController name;
  late final TextEditingController workUnit;
  late final TextEditingController password;
  bool obscurePassword = true;

  bool get isEdit => widget.mentor != null;

  @override
  void initState() {
    super.initState();
    email = TextEditingController(text: widget.mentor?.email ?? '');
    name = TextEditingController(text: widget.mentor?.fullName ?? '');
    workUnit = TextEditingController(text: widget.mentor?.workUnit ?? '');
    password = TextEditingController();
  }

  @override
  void dispose() {
    email.dispose();
    name.dispose();
    workUnit.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = MediaQuery.sizeOf(context).width < 640;
    return AdminFormDialogShell(
      title: isEdit ? 'Edit Mentor' : 'Tambah Mentor',
      subtitle: isEdit
          ? 'Perbarui identitas mentor dan kredensial login bila diperlukan.'
          : 'Buat akun mentor baru untuk kebutuhan pembimbing PKL.',
      icon: Icons.school_rounded,
      content: AdminFormSection(
        title: 'Data Mentor',
        icon: Icons.person_outline_rounded,
        compact: isPhone,
        child: Column(
          children: [
            TextField(
              controller: email,
              decoration: adminDialogFieldDecoration(label: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: name,
              decoration: adminDialogFieldDecoration(label: 'Nama Lengkap'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: workUnit,
              decoration: adminDialogFieldDecoration(
                label: 'Unit Kerja Mentor',
                hintText: 'Contoh: Sistem Informatika',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: password,
              decoration: adminDialogFieldDecoration(
                label: isEdit
                    ? 'Password baru (opsional)'
                    : 'Password sementara',
                hintText: isEdit
                    ? 'Kosongkan jika password tidak diubah'
                    : 'Kosongkan untuk generate otomatis',
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => obscurePassword = !obscurePassword),
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
              obscureText: obscurePassword,
            ),
            if (isEdit) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F7FC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFDCE4F1)),
                ),
                child: const Text(
                  'Kosongkan password jika tidak ingin diubah.',
                  style: TextStyle(
                    color: Color(0xFF5B6678),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
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
              if (email.text.trim().isEmpty || name.text.trim().isEmpty) return;
              Navigator.of(context).pop(
                _MentorFormResult(
                  email: email.text.trim(),
                  fullName: name.text.trim(),
                  workUnit: workUnit.text.trim(),
                  password: password.text.trim().isEmpty
                      ? null
                      : password.text.trim(),
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

class _MentorRecordCard extends StatelessWidget {
  const _MentorRecordCard({
    required this.mentor,
    required this.compact,
    required this.onEdit,
    required this.onDelete,
  });

  final MentorMiniDto mentor;
  final bool compact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final trimmedName = mentor.fullName.trim();
    final initials = trimmedName.isEmpty
        ? 'M'
        : trimmedName.substring(0, 1).toUpperCase();
    final workUnit = (mentor.workUnit ?? '').trim().isEmpty
        ? 'Unit kerja belum diisi'
        : mentor.workUnit!.trim();

    return AdminSectionCard(
      padding: EdgeInsets.all(compact ? 14 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: compact ? 52 : 60,
                height: compact ? 52 : 60,
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
                  initials,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: compact ? 24 : 28,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mentor.fullName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: compact ? 18 : 20,
                        color: const Color(0xFF22324B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      workUnit,
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
              _MentorMiniValueChip(
                label: 'Email',
                value: mentor.email,
                compact: compact,
              ),
              _MentorMiniValueChip(
                label: 'Role',
                value: 'Pembimbing',
                compact: compact,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _MentorInfoTile(
            icon: Icons.apartment_rounded,
            label: 'Unit Kerja Mentor',
            value: workUnit,
            compact: compact,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Hapus'),
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
    );
  }
}

class _MentorInfoTile extends StatelessWidget {
  const _MentorInfoTile({
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
            child: Icon(icon, color: adminBlue, size: compact ? 20 : 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: compact ? 11.5 : 12.5,
                    color: const Color(0xFF69758A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
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
    );
  }
}

class _MentorMiniValueChip extends StatelessWidget {
  const _MentorMiniValueChip({
    required this.label,
    required this.value,
    required this.compact,
  });

  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 7 : 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F6FC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFD9E2F1)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: compact ? 12 : 13,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF445368),
        ),
      ),
    );
  }
}
