import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'api_client.dart';

/// Background message handler — must be a top-level function.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('FCM background message: ${message.messageId}');
}

/// Push Notification Service — wraps Firebase Cloud Messaging (FCM).
class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  bool _initialized = false;
  String? _fcmToken;

  /// Call once at app startup (after Firebase.initializeApp()).
  Future<void> initialize() async {
    if (_initialized) return;

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permission on iOS / Android 13+
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint(
        'FCM permission: ${settings.authorizationStatus.name}');

    // Foreground notification display on Android
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
          'FCM foreground message: ${message.notification?.title} — ${message.notification?.body}');
    });

    // Fetch initial token
    _fcmToken = await messaging.getToken();
    debugPrint('FCM device token: $_fcmToken');

    // Refresh token callback
    messaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      debugPrint('FCM token refreshed: $newToken');
    });

    _initialized = true;
  }

  /// Returns the FCM device token (null if not available).
  Future<String?> getDeviceToken() async {
    if (!_initialized) await initialize();
    _fcmToken ??= await FirebaseMessaging.instance.getToken();
    return _fcmToken;
  }

  /// Registers the device FCM token with the Click2Fix backend.
  Future<void> registerDeviceToken({
    required ApiClient apiClient,
    required String authToken,
    required String appVariant,
  }) async {
    final token = await getDeviceToken();
    if (token == null || token.isEmpty) return;

    try {
      apiClient.setToken(authToken);
      await apiClient.post('/api/notifications/register-token', {
        'fcmToken': token,
        'platform': _platformName,
        'appVariant': appVariant,
      });
      debugPrint('FCM token registered with backend.');
    } catch (error) {
      debugPrint('FCM token registration failed: $error');
    }
  }

  String get _platformName {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      default:
        return 'unknown';
    }
  }
}
