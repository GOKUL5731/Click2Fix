import 'package:flutter/foundation.dart';

class AppConfig {
  static const String _defaultApiBaseUrl =
      'https://click2fix-backend.onrender.com';

  static String get apiBaseUrl {
    const configured = String.fromEnvironment('API_BASE_URL');
    final value = configured.trim().isEmpty ? _defaultApiBaseUrl : configured;
    return _normalizeBaseUrl(value);
  }

  static String _normalizeBaseUrl(String value) {
    var normalized = value.trim();
    if (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    if (!normalized.startsWith('http://') &&
        !normalized.startsWith('https://')) {
      if (kIsWeb) {
        normalized = 'https://$normalized';
      } else {
        normalized = 'http://$normalized';
      }
    }
    return normalized;
  }
}