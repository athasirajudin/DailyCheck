import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/app_scope.dart';
import '../../core/services/api_client_base.dart';

class KioskScreen extends StatefulWidget {
  const KioskScreen({super.key});

  @override
  State<KioskScreen> createState() => _KioskScreenState();
}

class _KioskScreenState extends State<KioskScreen> {
  final _pairingCode = TextEditingController();
  String? _authKey;
  String? _token;
  DateTime? _expiresAt;
  String? _error;
  Timer? _heartbeat;
  Timer? _refreshToken;

  static const _prefsAuthKey = 'kiosk_auth_key';

  @override
  void initState() {
    super.initState();
    _loadStoredAuthKey();
  }

  @override
  void dispose() {
    _pairingCode.dispose();
    _heartbeat?.cancel();
    _refreshToken?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Mode Display (Kiosk)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final qrSize = (constraints.maxWidth.clamp(240.0, 560.0) * 0.55).clamp(160.0, 260.0);
            return SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('1) Masukkan Pairing Code (dari Admin)'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _pairingCode,
                        decoration: const InputDecoration(labelText: 'Pairing Code'),
                        textCapitalization: TextCapitalization.characters,
                      ),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: () => _pair(scope),
                        child: const Text('Pair Device'),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      if (_error != null)
                        Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      if (_authKey != null) ...[
                        Text('AuthKey (tersimpan di device): $_authKey'),
                        const SizedBox(height: 8),
                        const Text('2) Token saat ini:'),
                        const SizedBox(height: 8),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if ((_token ?? '').isNotEmpty) ...[
                                  QrImageView(
                                    data: _token!,
                                    size: qrSize,
                                    backgroundColor: Colors.white,
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                SelectableText(
                                  _token ?? '-',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 8),
                                Text('Berlaku sampai: ${_expiresAt?.toLocal().toIso8601String() ?? '-'}'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: () => _requestToken(scope),
                          child: const Text('Refresh Token'),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => _resetDevice(scope),
                          icon: const Icon(Icons.restart_alt),
                          label: const Text('Reset Device (hapus AuthKey)'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _loadStoredAuthKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_prefsAuthKey);
      if (stored == null || stored.isEmpty) return;
      if (!mounted) return;
      setState(() => _authKey = stored);
      _heartbeat?.cancel();
      _refreshToken?.cancel();
      _heartbeat = Timer.periodic(const Duration(seconds: 20), (_) {
        final scope = AppScope.of(context);
        _sendHeartbeat(scope);
      });
      _refreshToken = Timer.periodic(const Duration(seconds: 25), (_) {
        final scope = AppScope.of(context);
        _requestToken(scope);
      });
      final scope = AppScope.of(context);
      await _sendHeartbeat(scope);
      await _requestToken(scope);
    } catch (_) {
      // ignore
    }
  }

  Future<void> _pair(AppScope scope) async {
    setState(() => _error = null);
    try {
      final data = await scope.apiClient.postJson(
        '/api/device/pair',
        body: {'pairingCode': _pairingCode.text.trim()},
      );
      if (data is! Map) throw ApiError(code: 'BAD_RESPONSE', message: 'Format pairing tidak valid.');
      final map = Map<String, dynamic>.from(data);
      final authKey = (map['authKey'] ?? '').toString();
      if (authKey.isEmpty) throw ApiError(code: 'BAD_RESPONSE', message: 'AuthKey kosong.');
      setState(() => _authKey = authKey);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsAuthKey, authKey);

      _heartbeat?.cancel();
      _heartbeat = Timer.periodic(const Duration(seconds: 20), (_) => _sendHeartbeat(scope));
      await _sendHeartbeat(scope);

      _refreshToken?.cancel();
      _refreshToken = Timer.periodic(const Duration(seconds: 25), (_) => _requestToken(scope));
      await _requestToken(scope);
    } on ApiError catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _resetDevice(AppScope scope) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Device'),
        content: const Text('Ini akan menghapus AuthKey tersimpan. Setelah reset, perlu pairing lagi.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Reset')),
        ],
      ),
    );
    if (ok != true) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsAuthKey);
    _heartbeat?.cancel();
    _refreshToken?.cancel();
    setState(() {
      _authKey = null;
      _token = null;
      _expiresAt = null;
      _error = null;
    });
  }

  Future<void> _sendHeartbeat(AppScope scope) async {
    final authKey = _authKey;
    if (authKey == null) return;
    try {
      await scope.apiClient.postJson('/api/device/heartbeat', bearerToken: authKey);
    } catch (_) {
      // ignore for now; UI will show stale token if server unreachable
    }
  }

  Future<void> _requestToken(AppScope scope) async {
    final authKey = _authKey;
    if (authKey == null) return;
    setState(() => _error = null);
    try {
      final data = await scope.apiClient.postJson('/api/device/qr-token', bearerToken: authKey);
      if (data is! Map) throw ApiError(code: 'BAD_RESPONSE', message: 'Format token tidak valid.');
      final map = Map<String, dynamic>.from(data);
      final token = (map['token'] ?? '').toString();
      final expiresAtStr = (map['expiresAt'] ?? '').toString();
      final expiresAt = DateTime.tryParse(expiresAtStr);
      setState(() {
        _token = token;
        _expiresAt = expiresAt;
      });
    } on ApiError catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }
}
