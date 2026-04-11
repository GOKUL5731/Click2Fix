import 'package:flutter/foundation.dart';
import '../../services/api_client.dart';

/// Push Notification Service — Firebase optional.
/// Firebase packages are available in this project.
/// Configure google-services.json and fill Firebase env vars to enable.
class PushNotificationService {
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    debugPrint('PushNotificationService: Firebase not yet configured.');
  }

  Future<String?> getDeviceToken() async => null;

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
      case TargetPlatform.android: return 'android';
      case TargetPlatform.iOS: return 'ios';
      default: return 'unknown';
    }
  }
}
