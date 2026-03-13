// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/app/app.dart';
import 'package:flutter_application_1/app/app_scope.dart';
import 'package:flutter_application_1/core/services/api_client_base.dart';
import 'package:flutter_application_1/core/services/app_config.dart';
import 'package:flutter_application_1/core/services/location_service.dart';
import 'package:flutter_application_1/core/services/session_store.dart';

void main() {
  testWidgets('Shows login screen when not authenticated', (WidgetTester tester) async {
    final session = SessionStore();
    await tester.pumpWidget(
      AppScope(
        config: AppConfig(appName: 'Absensi PKL Lemhannas', apiBaseUrl: 'http://localhost'),
        apiClient: _FakeApiClient(),
        location: LocationService(),
        session: session,
        child: const AbsensiApp(),
      ),
    );

    expect(find.text('Login'), findsOneWidget);
  });
}

class _FakeApiClient implements ApiClient {
  @override
  String baseUrl = 'http://localhost/public/api';

  @override
  Future<Object?> getJson(String path, {String? bearerToken, Map<String, String>? query}) async {
    throw ApiError(code: 'NOT_IMPLEMENTED', message: 'Not used in this test');
  }

  @override
  Future<Object?> postJson(String path, {String? bearerToken, Map<String, String>? query, Object? body}) async {
    throw ApiError(code: 'NOT_IMPLEMENTED', message: 'Not used in this test');
  }
}
