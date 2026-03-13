import 'package:flutter/widgets.dart';

import '../core/services/api_client.dart';
import '../core/services/app_config.dart';
import '../core/services/location_service.dart';
import '../core/services/session_store.dart';

class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.config,
    required this.apiClient,
    required this.location,
    required this.session,
    required super.child,
  });

  final AppConfig config;
  final ApiClient apiClient;
  final LocationService location;
  final SessionStore session;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope tidak ditemukan di widget tree.');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) {
    return oldWidget.config != config ||
        oldWidget.apiClient != apiClient ||
        oldWidget.location != location ||
        oldWidget.session != session;
  }
}
