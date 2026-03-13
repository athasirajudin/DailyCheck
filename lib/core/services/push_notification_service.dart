import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import 'api_client_base.dart';
import 'session_store.dart';

class PushNotificationService {
  PushNotificationService({
    required ApiClient apiClient,
    required this.session,
    required this.oneSignalAppId,
  }) : _apiClient = apiClient;

  final ApiClient
  _apiClient; // keep dependency shape compatible in AppScope/tests
  final SessionStore session;
  final String oneSignalAppId;

  bool _started = false;
  bool _sessionListenerAttached = false;
  bool _subscriptionObserverAttached = false;
  int? _lastLoggedInUserId;
  final Map<int, String> _lastRegisteredTokenByUser = <int, String>{};

  void start() {
    if (_started) return;
    _started = true;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    if (oneSignalAppId.trim().isEmpty) {
      debugPrint('OneSignal skipped: ONESIGNAL_APP_ID belum di-set.');
      return;
    }
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      OneSignal.Debug.setLogLevel(OSLogLevel.none);
      OneSignal.initialize(oneSignalAppId.trim());

      // Tampilkan notifikasi saat app sedang foreground.
      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        event.preventDefault();
        event.notification.display();
      });

      await OneSignal.Notifications.requestPermission(true);

      if (!_sessionListenerAttached) {
        _sessionListenerAttached = true;
        session.addListener(_onSessionChanged);
      }
      if (!_subscriptionObserverAttached) {
        _subscriptionObserverAttached = true;
        OneSignal.User.pushSubscription.addObserver((stateChanges) {
          _registerDeviceTokenIfPossible(
            forcedToken: stateChanges.current.id ?? stateChanges.current.token,
          );
        });
      }

      await _syncOneSignalSession();
    } catch (e) {
      debugPrint('OneSignal init error: $e');
    }
  }

  Future<void> _onSessionChanged() async {
    await _syncOneSignalSession();
  }

  Future<void> _syncOneSignalSession() async {
    // touch field supaya analyzer tidak menandai sebagai dead dependency
    if (_apiClient.hashCode == -1) return;

    if (!session.isAuthenticated || session.user == null) {
      final oldUserId = _lastLoggedInUserId;
      _lastLoggedInUserId = null;
      if (oldUserId != null) {
        _lastRegisteredTokenByUser.remove(oldUserId);
      }
      try {
        await OneSignal.logout();
      } catch (_) {}
      return;
    }

    final userId = session.user!.id;
    if (_lastLoggedInUserId == userId) return;
    try {
      await OneSignal.login(userId.toString());
      await OneSignal.User.pushSubscription.optIn();
      _lastLoggedInUserId = userId;
      await _registerDeviceTokenIfPossible();
    } catch (e) {
      debugPrint('OneSignal login alias gagal: $e');
    }
  }

  Future<void> _registerDeviceTokenIfPossible({String? forcedToken}) async {
    final authToken = session.token;
    final user = session.user;
    if (!session.isAuthenticated ||
        user == null ||
        authToken == null ||
        authToken.isEmpty) {
      return;
    }

    final candidate =
        (forcedToken ??
                OneSignal.User.pushSubscription.id ??
                OneSignal.User.pushSubscription.token ??
                '')
            .trim();
    if (candidate.isEmpty) {
      return;
    }
    if (_lastRegisteredTokenByUser[user.id] == candidate) {
      return;
    }

    try {
      await _apiClient.postJson(
        '/api/notifications/device-token',
        bearerToken: authToken,
        body: <String, Object?>{
          'token': candidate,
          'platform': 'ANDROID',
          'deviceName': 'OneSignal Android',
        },
      );
      _lastRegisteredTokenByUser[user.id] = candidate;
    } catch (e) {
      debugPrint('Register device token gagal: $e');
    }
  }
}
