import 'package:flutter/foundation.dart';

class AppConfig {
  static const String _defaultHost = 'https://click2fix-backend.onrender.com';
  static const String _defaultApiBase = '$_defaultHost/api';

  static String get apiBaseUrl {
    const configured = String.fromEnvironment('API_BASE_URL');
    final raw = configured.trim().isEmpty ? _defaultApiBase : configured.trim();
    return _ensureApiSuffix(_normalizeBaseUrl(raw));
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
    if (!kIsWeb &&
        normalized.startsWith('http://') &&
        !normalized.replaceFirst('http://', '').startsWith('127.0.0.1') &&
        !normalized.replaceFirst('http://', '').startsWith('localhost')) {
      normalized = 'https://${normalized.replaceFirst('http://', '')}';
    }
    return normalized;
  }

  static String _ensureApiSuffix(String normalized) {
    var s = normalized.replaceAll(RegExp(r'/+$'), '');
    if (s.endsWith('/api')) return s;
    return '$s/api';
  }
}