import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/services/api_client_base.dart';

class MentorPairingScreen extends StatefulWidget {
  const MentorPairingScreen({super.key});

  @override
  State<MentorPairingScreen> createState() => _MentorPairingScreenState();
}

class _MentorPairingScreenState extends State<MentorPairingScreen> {
  List<_UnitMini> _units = const [];
  _UnitMini? _selected;
  final _deviceName = TextEditingController(text: 'Display-1');
  bool _loading = false;
  String? _error;
  String? _pairingCode;
  String? _expiresAt;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_units.isNotEmpty) return;
    _loadUnits();
  }

  @override
  void dispose() {
    _deviceName.dispose();
    super.dispose();
  }

  Future<void> _loadUnits() async {
    final scope = AppScope.of(context);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await scope.apiClient.getJson(
        '/api/mentor/units',
        bearerToken: scope.session.token,
      );
      if (data is! List) {
        throw ApiError(
          code: 'BAD_RESPONSE',
          message: 'Format unit tidak valid.',
        );
      }
      final units = data
          .whereType<Map>()
          .map((e) => _UnitMini.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      setState(() {
        _units = units;
        _selected = units.isNotEmpty ? units.first : null;
      });
    } on ApiError catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _createPairing() async {
    final scope = AppScope.of(context);
    final unit = _selected;
    if (unit == null) return;
    setState(() {
      _loading = true;
      _error = null;
      _pairingCode = null;
      _expiresAt = null;
    });
    try {
      final data = await scope.apiClient.postJson(
        '/api/mentor/pairing/create',
        bearerToken: scope.session.token,
        body: {'unitId': unit.id, 'deviceName': _deviceName.text.trim()},
      );
      if (data is! Map) {
        throw ApiError(
          code: 'BAD_RESPONSE',
          message: 'Format pairing tidak valid.',
        );
      }
      final map = Map<String, dynamic>.from(data);
      setState(() {
        _pairingCode = (map['pairingCode'] ?? '').toString();
        _expiresAt = (map['expiresAt'] ?? '').toString();
      });
    } on ApiError catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pairing Display (Pembimbing)')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Pembimbing bisa membuat pairing code untuk unit intern bimbingannya.',
          ),
          const SizedBox(height: 12),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          if (_units.isEmpty && _loading) const LinearProgressIndicator(),
          const SizedBox(height: 12),
          DropdownButtonFormField<_UnitMini>(
            initialValue: _selected,
            decoration: const InputDecoration(labelText: 'Unit'),
            items: _units
                .map((u) => DropdownMenuItem(value: u, child: Text(u.name)))
                .toList(),
            onChanged: _loading ? null : (v) => setState(() => _selected = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _deviceName,
            decoration: const InputDecoration(labelText: 'Nama Device Display'),
            enabled: !_loading,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: _loading || _selected == null ? null : _createPairing,
              icon: const Icon(Icons.link),
              label: const Text('Generate Pairing Code'),
            ),
          ),
          const SizedBox(height: 16),
          if (_pairingCode != null && _pairingCode!.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pairing Code (berlaku 10 menit):'),
                    const SizedBox(height: 8),
                    SelectableText(
                      _pairingCode!,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('Expires: ${_expiresAt ?? '-'}'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _UnitMini {
  _UnitMini({required this.id, required this.name});

  final int id;
  final String name;

  factory _UnitMini.fromJson(Map<String, dynamic> json) {
    return _UnitMini(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '').toString(),
    );
  }
}
