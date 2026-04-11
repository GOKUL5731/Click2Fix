import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class PushNotificationService {
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      await FirebaseMessaging.instance.setAutoInitEnabled(true);
      await FirebaseMessaging.instance.requestPermission(
        alert: true, badge: true, sound: true,
      );
      FirebaseMessaging.onMessage.listen((message) {
        debugPrint('Foreground push: ${message.messageId}');
      });
      _initialized = true;
    } catch (e) {
      debugPrint('Push init skipped: $e');
    }
  }

  Future<String?> getDeviceToken() async {
    try {
      await initialize();
      return FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('FCM token error: $e');
      return null;
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
