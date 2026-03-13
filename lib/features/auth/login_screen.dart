import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/services/api_client_base.dart';
import 'login_mode.dart';
import 'login_view_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.mode = LoginMode.intern,
    this.adminAccessTicket,
  });

  final LoginMode mode;
  final String? adminAccessTicket;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  LoginViewModel? _vm;
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  String? _appName;
  bool _obscurePassword = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = AppScope.of(context);
    _vm ??= LoginViewModel.of(scope);
    _appName ??= scope.config.appName;
  }

  @override
  void dispose() {
    _vm?.dispose();
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = _vm!;
    final appName = _appName ?? 'Absensi PKL';

    return Scaffold(
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: const [Color(0xFFF4F7FC), Color(0xFFE7EEF8)],
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  Positioned(
                    top: -130,
                    right: -120,
                    child: _GlowCircle(
                      size: 340,
                      color: const Color(0xFF0E2C58).withValues(alpha: 0.12),
                    ),
                  ),
                  Positioned(
                    top: 120,
                    left: -90,
                    child: _GlowCircle(
                      size: 220,
                      color: const Color(0xFFC9A227).withValues(alpha: 0.18),
                    ),
                  ),
                  Positioned(
                    bottom: -140,
                    left: -80,
                    child: _GlowCircle(
                      size: 320,
                      color: const Color(0xFF102B54).withValues(alpha: 0.10),
                    ),
                  ),
                  Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(22),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1080),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isCompact = constraints.maxWidth < 900;
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.96),
                                borderRadius: BorderRadius.circular(34),
                                border: Border.all(
                                  color: const Color(0xFFDEE5F2),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.10),
                                    blurRadius: 36,
                                    offset: const Offset(0, 18),
                                  ),
                                ],
                              ),
                              child: isCompact
                                  ? Column(
                                      children: [
                                        _buildBrandPanel(
                                          context,
                                          appName,
                                          compact: true,
                                        ),
                                        _buildFormPanel(context, vm),
                                      ],
                                    )
                                  : Row(
                                      children: [
                                        SizedBox(
                                          width: 430,
                                          child: _buildBrandPanel(
                                            context,
                                            appName,
                                          ),
                                        ),
                                        Expanded(
                                          child: _buildFormPanel(context, vm),
                                        ),
                                      ],
                                    ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBrandPanel(
    BuildContext context,
    String appName, {
    bool compact = false,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 24 : 34),
      decoration: BoxDecoration(
        borderRadius: compact
            ? const BorderRadius.only(
                topLeft: Radius.circular(34),
                topRight: Radius.circular(34),
              )
            : const BorderRadius.only(
                topLeft: Radius.circular(34),
                bottomLeft: Radius.circular(34),
              ),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A2750), Color(0xFF1D4A80)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -40,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.center,
                child: SizedBox(
                  width: compact ? 82 : 108,
                  height: compact ? 82 : 108,
                  child: Image.asset(
                    'assets/icon/logo-icon.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.account_balance,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
              ),
              SizedBox(height: compact ? 16 : 26),
              Align(
                alignment: Alignment.center,
                child: Text(
                  appName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: compact ? 34 : 44,
                    height: 1.05,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.center,
                child: Text(
                  'Selamat datang di aplikasi DailyCheck absensi PKL berbasis lokasi Lemhannas RI.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: compact ? 16 : 18,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _FeatureTile(
                icon: Icons.location_on_outlined,
                text: 'Validasi check-in berdasarkan GPS dan radius',
              ),
              const SizedBox(height: 10),
              _FeatureTile(
                icon: Icons.verified_user_outlined,
                text: 'Izin dan sakit diverifikasi langsung pembimbing',
              ),
              if (!compact) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'Lemhannas RI - Sistem Absensi Intern',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormPanel(BuildContext context, LoginViewModel vm) {
    final theme = Theme.of(context);
    final isIntern = widget.mode == LoginMode.intern;
    final isAdmin = widget.mode == LoginMode.admin;
    final isMentor = widget.mode == LoginMode.mentor;
    return Padding(
      padding: const EdgeInsets.all(34),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            switch (widget.mode) {
              LoginMode.intern => 'Masuk sebagai intern',
              LoginMode.admin => 'Masuk sebagai admin',
              LoginMode.mentor => 'Masuk sebagai pembimbing',
            },
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            switch (widget.mode) {
              LoginMode.intern =>
                'Masukkan NISN dan password yang telah terdaftar.',
              LoginMode.admin =>
                'Masukkan email dan password akun admin setelah verifikasi PIN.',
              LoginMode.mentor =>
                'Masukkan email dan password akun pembimbing.',
            },
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _identifier,
            keyboardType: isIntern
                ? TextInputType.number
                : TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: _inputDecoration(
              labelText: isIntern ? 'NISN' : 'Email',
              icon: isIntern ? Icons.badge_outlined : Icons.email_outlined,
            ),
            enabled: !vm.loading,
            onSubmitted: (_) => _submitLogin(vm),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _password,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            decoration:
                _inputDecoration(
                  labelText: 'Password',
                  icon: Icons.lock_outline_rounded,
                ).copyWith(
                  suffixIcon: IconButton(
                    onPressed: vm.loading
                        ? null
                        : () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                  ),
                ),
            enabled: !vm.loading,
            onSubmitted: (_) => _submitLogin(vm),
          ),
          const SizedBox(height: 12),
          if (vm.error != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF3BDC4)),
              ),
              child: Text(
                vm.error!,
                style: const TextStyle(color: Color(0xFFB3261E)),
              ),
            ),
            const SizedBox(height: 14),
          ],
          if (isAdmin) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F7FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD5E0F3)),
              ),
              child: const Text(
                'Halaman ini hanya untuk akun admin yang telah lolos verifikasi PIN.',
                style: TextStyle(color: Color(0xFF29466E)),
              ),
            ),
            const SizedBox(height: 14),
          ] else if (isMentor) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F7FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD5E0F3)),
              ),
              child: const Text(
                'Halaman ini hanya untuk akun pembimbing dan tidak memerlukan PIN admin.',
                style: TextStyle(color: Color(0xFF29466E)),
              ),
            ),
            const SizedBox(height: 14),
          ],
          SizedBox(
            height: 56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFF10315E), Color(0xFF0A2344)],
                ),
              ),
              child: FilledButton(
                onPressed: vm.loading ? null : () => _submitLogin(vm),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: vm.loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Masuk',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (isIntern) ...[
            OutlinedButton.icon(
              onPressed: vm.loading ? null : _openRoleLoginChooser,
              icon: const Icon(Icons.admin_panel_settings_outlined),
              label: const Text('Login Admin / Pembimbing'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                side: const BorderSide(color: Color(0xFF163D73)),
                foregroundColor: const Color(0xFF163D73),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Akses admin dipisahkan agar pengguna intern tidak bingung saat login.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ] else ...[
            TextButton.icon(
              onPressed: vm.loading ? null : () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Kembali ke login intern'),
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String labelText,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: labelText,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: const Color(0xFFF9FBFF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFB8C2D7)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF163D73), width: 2),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  Future<void> _submitLogin(LoginViewModel vm) async {
    await vm.login(
      identifier: _identifier.text.trim(),
      password: _password.text,
      mode: widget.mode,
      adminAccessTicket: widget.adminAccessTicket,
    );

    if (!mounted) return;

    final session = AppScope.of(context).session;
    if (!session.isAuthenticated) return;

    if (widget.mode != LoginMode.intern && Navigator.of(context).canPop()) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _openRoleLoginChooser() async {
    final selectedMode = await showDialog<LoginMode>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 460),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFD9E2F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 32,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF113660), Color(0xFF1B4D86)],
                        ),
                      ),
                      child: const Icon(
                        Icons.account_tree_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pilih Jenis Login',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Pilih akses yang sesuai sebelum masuk ke sistem.',
                            style: TextStyle(
                              color: Color(0xFF5E718D),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _RoleOptionCard(
                  title: 'Login Admin',
                  description:
                      'Akses khusus admin. Setelah dipilih, sistem akan meminta PIN verifikasi.',
                  icon: Icons.admin_panel_settings_rounded,
                  accent: const Color(0xFF123764),
                  onTap: () => Navigator.of(dialogContext).pop(LoginMode.admin),
                ),
                const SizedBox(height: 12),
                _RoleOptionCard(
                  title: 'Login Pembimbing',
                  description:
                      'Masuk sebagai pembimbing menggunakan email dan password tanpa PIN admin.',
                  icon: Icons.groups_rounded,
                  accent: const Color(0xFFC48F14),
                  onTap: () =>
                      Navigator.of(dialogContext).pop(LoginMode.mentor),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Batal'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || selectedMode == null) return;

    if (selectedMode == LoginMode.admin) {
      await _openAdminLogin();
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(mode: LoginMode.mentor),
      ),
    );
  }

  Future<void> _openAdminLogin() async {
    final vm = _vm!;

    final ticket = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final controller = TextEditingController();
        var obscurePin = true;
        var verifying = false;
        String? errorText;

        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> submitPin() async {
              if (verifying) return;
              setState(() {
                verifying = true;
                errorText = null;
              });
              try {
                final issuedTicket = await vm.verifyAdminPin(controller.text);
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop(issuedTicket);
              } on ApiError catch (e) {
                if (!dialogContext.mounted) return;
                setState(() {
                  errorText = e.message;
                });
              } catch (_) {
                if (!dialogContext.mounted) return;
                setState(() {
                  errorText = 'Terjadi kendala saat verifikasi PIN.';
                });
              } finally {
                if (dialogContext.mounted) {
                  setState(() {
                    verifying = false;
                  });
                }
              }
            }

            return AlertDialog(
              title: const Text('Verifikasi PIN Admin'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kamu akan ditujukan ke halaman login admin. Masukkan PIN untuk memverifikasi akses.',
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller,
                      obscureText: obscurePin,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: 'PIN Admin',
                        prefixIcon: const Icon(Icons.pin_outlined),
                        errorText: errorText,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      enabled: !verifying,
                      onSubmitted: (_) => submitPin(),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: verifying
                            ? null
                            : () => setState(() {
                                obscurePin = !obscurePin;
                              }),
                        child: Text(
                          obscurePin ? 'Tampilkan PIN' : 'Sembunyikan PIN',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: verifying
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: verifying ? null : submitPin,
                  child: verifying
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Verifikasi'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted || ticket == null || ticket.trim().isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            LoginScreen(mode: LoginMode.admin, adminAccessTicket: ticket),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _RoleOptionCard extends StatelessWidget {
  const _RoleOptionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: [
              accent.withValues(alpha: 0.12),
              accent.withValues(alpha: 0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: accent.withValues(alpha: 0.18)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Color(0xFF4E607A),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, color: accent),
          ],
        ),
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
