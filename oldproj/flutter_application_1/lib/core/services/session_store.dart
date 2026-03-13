import 'package:flutter/foundation.dart';

import '../models/app_user.dart';

class SessionStore extends ChangeNotifier {
  AppUser? _user;
  String? _token;

  AppUser? get user => _user;
  String? get token => _token;

  bool get isAuthenticated => _user != null && _token != null;

  void setSession({required AppUser user, required String token}) {
    _user = user;
    _token = token;
    notifyListeners();
  }

  void clear() {
    _user = null;
    _token = null;
    notifyListeners();
  }
}

