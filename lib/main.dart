import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/app_scope.dart';
import 'core/services/api_client.dart';
import 'core/services/api_base_url_store.dart';
import 'core/services/app_config.dart';
import 'core/services/location_service.dart';
import 'core/services/push_notification_service.dart';
import 'core/services/session_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const envApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://tony-aforethought-tonishly.ngrok-free.dev',
  );
  const envOneSignalAppId = String.fromEnvironment(
    'ONESIGNAL_APP_ID',
    defaultValue: '46750d68-7eff-481f-a40d-5917c57d3a97',
  );
  final initialApiBaseUrl = await ApiBaseUrlStore.load(fallback: envApiBaseUrl);

  final config = AppConfig(
    appName: 'Absensi PKL Lemhannas',
    apiBaseUrl: initialApiBaseUrl,
  );

  final apiClient = createApiClient(baseUrl: config.apiBaseUrl);
  final location = LocationService();
  final session = SessionStore();
  await session.restore();
  final pushNotifications = PushNotificationService(
    apiClient: apiClient,
    session: session,
    oneSignalAppId: envOneSignalAppId,
  );
  pushNotifications.start();

  runApp(
    AppScope(
      config: config,
      apiClient: apiClient,
      location: location,
      session: session,
      pushNotifications: pushNotifications,
      child: const AbsensiApp(),
    ),
  );
}
