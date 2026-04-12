import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'api_client.dart';

/// Registers the device FCM token with the backend when Firebase is available.
Future<void> syncFcmDeviceToken(ApiClient client) async {
  if (kIsWeb) return;
  try {
    if (Firebase.apps.isEmpty) return;
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    final token = await messaging.getToken();
    if (token == null || token.isEmpty) return;
    final platform = switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      _ => 'unknown',
    };
    await client.post('/notifications/register-token', {
      'fcmToken': token,
      'platform': platform,
      'appVariant': 'mobile',
    });
  } catch (e) {
    debugPrint('FCM token sync skipped: $e');
  }
}
