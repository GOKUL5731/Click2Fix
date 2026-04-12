import 'package:flutter/foundation.dart';

class AppConfig {
  static const appName = 'Click2Fix';
  static const tagline = 'Click the problem. Fix it instantly.';

  static const environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  static const _configuredApiBase = String.fromEnvironment('API_BASE_URL');
  static const _configuredSocket = String.fromEnvironment('SOCKET_URL');

  /// Production Render URL (HTTPS). Override with `--dart-define=API_BASE_URL=...` if your service URL changes.
  static const _defaultBackendHost = 'https://click2fix-backend.onrender.com';

  static String get apiBaseUrl => _normalizeBaseUrl(
        _configuredApiBase.trim().isEmpty ? _defaultBackendHost : _configuredApiBase,
      );

  static String get socketUrl => _normalizeBaseUrl(
        _configuredSocket.trim().isEmpty ? _defaultBackendHost : _configuredSocket,
      );

  static const googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  static const firebaseWebApiKey = String.fromEnvironment(
    'FIREBASE_WEB_API_KEY',
    defaultValue: '',
  );

  static const firebaseWebAppId = String.fromEnvironment(
    'FIREBASE_WEB_APP_ID',
    defaultValue: '',
  );

  static const firebaseWebMessagingSenderId = String.fromEnvironment(
    'FIREBASE_WEB_MESSAGING_SENDER_ID',
    defaultValue: '',
  );

  static const firebaseWebProjectId = String.fromEnvironment(
    'FIREBASE_WEB_PROJECT_ID',
    defaultValue: '',
  );

  static String _normalizeBaseUrl(String value) {
    var normalized = value.trim();
    if (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    if (!normalized.startsWith('http://') && !normalized.startsWith('https://')) {
      normalized = 'https://$normalized';
    }
    if (!kIsWeb && normalized.startsWith('http://')) {
      final host = normalized.replaceFirst('http://', '');
      if (!host.startsWith('127.0.0.1') && !host.startsWith('localhost')) {
        normalized = 'https://$host';
      }
    }
    return normalized;
  }
}