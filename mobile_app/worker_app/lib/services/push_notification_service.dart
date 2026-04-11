import 'package:flutter/foundation.dart';
import 'api_client.dart';

/// Push Notification Service
/// Firebase FCM is optional â€” the app gracefully degrades if not configured.
/// To enable real push notifications, add firebase_core and firebase_messaging
/// to pubspec.yaml and place google-services.json in android/app/.
class PushNotificationService {
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    // Firebase initialization is deferred â€” add firebase packages when ready
    _initialized = true;
    debugPrint('PushNotificationService: Firebase not yet configured. Skipping FCM init.');
  }

  Future<String?> getDeviceToken() async {
    // Returns null until Firebase is configured
    return null;
  }

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

