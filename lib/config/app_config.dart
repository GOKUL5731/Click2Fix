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

  /// Host only (no `/api`) — used for WebSocket defaults. API calls use [apiBaseUrl].
  static const _defaultBackendHost = 'https://click2fix-backend.onrender.com';

  /// REST base includes `/api` so paths are `/auth/...`, `/app/...` (not `/api/auth/...` on top of host).
  static const _defaultApiBase = '$_defaultBackendHost/api';

  static String get apiBaseUrl {
    final raw = _configuredApiBase.trim().isEmpty ? _defaultApiBase : _configuredApiBase.trim();
    return _ensureApiSuffix(_normalizeBaseUrl(raw));
  }

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

  /// Ensures the base URL ends with `/api` (single suffix). Accepts defines like `https://host` or `https://host/api`.
  static String _ensureApiSuffix(String normalized) {
    var s = normalized.replaceAll(RegExp(r'/+$'), '');
    if (s.endsWith('/api')) return s;
    return '$s/api';
  }
}