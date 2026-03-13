// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/app/app.dart';
import 'package:flutter_application_1/app/app_scope.dart';
import 'package:flutter_application_1/core/services/api_client_base.dart';
import 'package:flutter_application_1/core/services/app_config.dart';
import 'package:flutter_application_1/core/services/location_service.dart';
import 'package:flutter_application_1/core/services/push_notification_service.dart';
import 'package:flutter_application_1/core/services/session_store.dart';

void main() {
  testWidgets('Shows login screen when not authenticated', (
    WidgetTester tester,
  ) async {
    final apiClient = _FakeApiClient();
    final session = SessionStore();
    final pushNotifications = PushNotificationService(
      apiClient: apiClient,
      session: session,
      oneSignalAppId: '',
    );
    await tester.pumpWidget(
      AppScope(
        config: AppConfig(
          appName: 'Absensi PKL Lemhannas',
          apiBaseUrl: 'http://localhost',
        ),
        apiClient: apiClient,
        location: LocationService(),
        session: session,
        pushNotifications: pushNotifications,
        child: const AbsensiApp(),
      ),
    );

    expect(find.text('Masuk'), findsOneWidget);
    expect(find.text('NISN'), findsOneWidget);
  });
}

class _FakeApiClient implements ApiClient {
  @override
  String baseUrl = 'http://localhost/public/api';

  @override
  Future<Object?> getJson(
    String path, {
    String? bearerToken,
    Map<String, String>? query,
  }) async {
    throw ApiError(code: 'NOT_IMPLEMENTED', message: 'Not used in this test');
  }

  @override
  Future<Object?> postJson(
    String path, {
    String? bearerToken,
    Map<String, String>? query,
    Object? body,
  }) async {
    throw ApiError(code: 'NOT_IMPLEMENTED', message: 'Not used in this test');
  }

  @override
  Future<Object?> deleteJson(
    String path, {
    String? bearerToken,
    Map<String, String>? query,
  }) async {
    throw ApiError(code: 'NOT_IMPLEMENTED', message: 'Not used in this test');
  }

  @override
  Future<Uint8List> getBytes(
    String path, {
    String? bearerToken,
    Map<String, String>? query,
  }) async {
    throw ApiError(code: 'NOT_IMPLEMENTED', message: 'Not used in this test');
  }
}
