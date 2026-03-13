import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/ui/app_notice.dart';
import 'admin_create_mentor_view_model.dart';
import 'admin_style.dart';

class AdminCreateMentorScreen extends StatefulWidget {
  const AdminCreateMentorScreen({super.key});

  @override
  State<AdminCreateMentorScreen> createState() =>
      _AdminCreateMentorScreenState();
}

class _AdminCreateMentorScreenState extends State<AdminCreateMentorScreen> {
  AdminCreateMentorViewModel? _vm;
  final _email = TextEditingController();
  final _name = TextEditingController();
  final _workUnit = TextEditingController();
  final _password = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _vm ??= AdminCreateMentorViewModel(
      apiClient: AppScope.of(context).apiClient,
      session: AppScope.of(context).session,
    );
  }

  @override
  void dispose() {
    _vm?.dispose();
    _email.dispose();
    _name.dispose();
    _workUnit.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = _vm!;
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Mentor')),
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) {
          return AdminPageBackground(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
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
                        if (vm.tempPassword != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: SelectableText(
                              'Berhasil. Password: ${vm.tempPassword}',
                            ),
                          ),
                        TextField(
                          controller: _email,
                          decoration: const InputDecoration(labelText: 'Email'),
                          keyboardType: TextInputType.emailAddress,
                          enabled: !vm.loading,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _name,
                          decoration: const InputDecoration(
                            labelText: 'Nama Lengkap',
                          ),
                          enabled: !vm.loading,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _workUnit,
                          decoration: const InputDecoration(
                            labelText: 'Unit Kerja Mentor',
                          ),
                          enabled: !vm.loading,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _password,
                          decoration: const InputDecoration(
                            labelText: 'Password (kosong = auto)',
                          ),
                          obscureText: true,
                          enabled: !vm.loading,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 48,
                          child: FilledButton.icon(
                            onPressed: vm.loading ? null : _submit,
                            icon: const Icon(Icons.save),
                            label: vm.loading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Simpan'),
                          ),
                        ),
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

  Future<void> _submit() async {
    final vm = _vm!;
    await vm.createMentor(
      email: _email.text.trim(),
      fullName: _name.text.trim(),
      workUnit: _workUnit.text.trim(),
      password: _password.text.trim(),
    );
    if (!mounted) return;
    if (vm.error == null) {
      AppNotice.show(context, 'Mentor dibuat.', type: AppNoticeType.success);
      _password.clear();
    }
  }
}
