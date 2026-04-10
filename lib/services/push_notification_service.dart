import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import 'api_client.dart';

class PushNotificationService {
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    try {
      await _initializeFirebase();
      await FirebaseMessaging.instance.setAutoInitEnabled(true);
      await FirebaseMessaging.instance
          .requestPermission(alert: true, badge: true, sound: true);
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Foreground push received: ${message.messageId}');
      });
      _initialized = true;
    } catch (error) {
      debugPrint('Push notification initialization skipped: $error');
    }
  }

  Future<String?> getDeviceToken() async {
    try {
      await initialize();
      return FirebaseMessaging.instance.getToken();
    } catch (error) {
      debugPrint('Unable to read FCM token: $error');
      return null;
    }
  }

  Future<void> registerDeviceToken({
    required ApiClient apiClient,
    required String authToken,
    required String appVariant,
  }) async {
    final token = await getDeviceToken();
    if (token == null || token.isEmpty) {
      return;
    }

    try {
      apiClient.setToken(authToken);
      await apiClient.post('/notifications/register-token', {
        'fcmToken': token,
        'platform': _platformName,
        'appVariant': appVariant,
      });
    } catch (error) {
      debugPrint('FCM token registration failed: $error');
    }
  }

  Future<void> _initializeFirebase() async {
    if (Firebase.apps.isNotEmpty) {
      return;
    }

    if (kIsWeb) {
      if (AppConfig.firebaseWebApiKey.isEmpty ||
          AppConfig.firebaseWebAppId.isEmpty ||
          AppConfig.firebaseWebMessagingSenderId.isEmpty ||
          AppConfig.firebaseWebProjectId.isEmpty) {
        throw StateError(
          'Missing web Firebase values. Set FIREBASE_WEB_API_KEY, FIREBASE_WEB_APP_ID, FIREBASE_WEB_MESSAGING_SENDER_ID, and FIREBASE_WEB_PROJECT_ID.',
        );
      }

      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: AppConfig.firebaseWebApiKey,
          appId: AppConfig.firebaseWebAppId,
          messagingSenderId: AppConfig.firebaseWebMessagingSenderId,
          projectId: AppConfig.firebaseWebProjectId,
        ),
      );
      return;
    }

    await Firebase.initializeApp();
  }

  String get _platformName {
    if (kIsWeb) {
      return 'web';
    }
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
