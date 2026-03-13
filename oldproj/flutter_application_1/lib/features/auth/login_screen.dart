import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/services/api_base_url_store.dart';
import 'login_view_model.dart';
import 'register_request_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  LoginViewModel? _vm;
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _currentApiBaseUrl;
  String? _appName;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = AppScope.of(context);
    _vm ??= LoginViewModel.of(scope);
    _currentApiBaseUrl ??= scope.apiClient.baseUrl;
    _appName ??= scope.config.appName;
  }

  @override
  void dispose() {
    _vm?.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = _vm!;
    final appName = _appName ?? 'Absensi';
    final currentBaseUrl = _currentApiBaseUrl ?? '-';
    return Scaffold(
      appBar: AppBar(title: Text(appName)),
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Login',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email'),
                      enabled: !vm.loading,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _password,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password'),
                      enabled: !vm.loading,
                    ),
                    const SizedBox(height: 12),
                    if (vm.error != null) ...[
                      Text(
                        vm.error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: vm.loading
                            ? null
                            : () => vm.login(
                                email: _email.text.trim(),
                                password: _password.text,
                              ),
                        child: vm.loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Masuk'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: vm.loading
                            ? null
                            : () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const RegisterRequestScreen(),
                                ),
                              ),
                        child: const Text('Daftar PKL (Request)'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Base URL API saat ini:\n$currentBaseUrl',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: vm.loading
                          ? null
                          : _changeApiBaseUrl,
                      icon: const Icon(Icons.link),
                      label: const Text('Ubah URL API (ngrok)'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _changeApiBaseUrl() async {
    if (!mounted) {
      return;
    }
    final current = AppScope.of(context).apiClient.baseUrl;
    final controller = TextEditingController(text: current);
    final raw = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah URL API'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'API Base URL',
            hintText: 'https://xxxx-xxxx.ngrok-free.app',
          ),
          keyboardType: TextInputType.url,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (raw == null) {
      return;
    }

    if (!ApiBaseUrlStore.isValidHttpUrl(raw)) {
      if (!mounted) {
        return;
      }
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'URL tidak valid. Gunakan format http:// atau https://',
          ),
        ),
      );
      return;
    }

    final saved = await ApiBaseUrlStore.save(raw);

    if (!mounted) {
      return;
    }
    final scope = AppScope.of(context);
    scope.apiClient.baseUrl = saved;
    scope.config.apiBaseUrl = saved;
    setState(() {
      _currentApiBaseUrl = saved;
    });
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(content: Text('API Base URL diubah: $saved')),
    );
  }
}
