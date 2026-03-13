import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';

class SessionStore extends ChangeNotifier {
  static const String _keyToken = 'session_token';
  static const String _keyUserJson = 'session_user_json';

  AppUser? _user;
  String? _token;

  AppUser? get user => _user;
  String? get token => _token;

  bool get isAuthenticated => _user != null && _token != null;

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString(_keyToken);
    final savedUserJson = prefs.getString(_keyUserJson);
    if (savedToken == null ||
        savedToken.isEmpty ||
        savedUserJson == null ||
        savedUserJson.isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(savedUserJson);
      if (decoded is! Map) return;
      final savedUser = AppUser.fromJson(Map<String, dynamic>.from(decoded));
      _user = savedUser;
      _token = savedToken;
      notifyListeners();
    } catch (_) {
      await clear();
    }
  }

  void setSession({required AppUser user, required String token}) {
    _user = user;
    _token = token;
    notifyListeners();
    unawaited(_persist());
  }

  Future<void> clear() async {
    _user = null;
    _token = null;
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUser = _user;
    final currentToken = _token;
    if (currentUser == null || currentToken == null || currentToken.isEmpty) {
      await prefs.remove(_keyToken);
      await prefs.remove(_keyUserJson);
      return;
    }

    final userMap = <String, dynamic>{
      'id': currentUser.id,
      'email': currentUser.email,
      'fullName': currentUser.fullName,
      'role': userRoleToApi(currentUser.role),
    };
    await prefs.setString(_keyToken, currentToken);
    await prefs.setString(_keyUserJson, jsonEncode(userMap));
  }
}
