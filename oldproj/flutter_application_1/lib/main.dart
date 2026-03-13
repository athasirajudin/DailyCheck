import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/app_scope.dart';
import 'core/services/api_client.dart';
import 'core/services/api_base_url_store.dart';
import 'core/services/app_config.dart';
import 'core/services/location_service.dart';
import 'core/services/session_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const envApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://4ff5-114-8-214-77.ngrok-free.app',
  );
  final initialApiBaseUrl = await ApiBaseUrlStore.load(fallback: envApiBaseUrl);

  final config = AppConfig(
    appName: 'Absensi PKL Lemhannas',
    apiBaseUrl: initialApiBaseUrl,
  );

  final apiClient = createApiClient(baseUrl: config.apiBaseUrl);
  final location = LocationService();
  final session = SessionStore();

  runApp(
    AppScope(
      config: config,
      apiClient: apiClient,
      location: location,
      session: session,
      child: const AbsensiApp(),
    ),
  );
}
