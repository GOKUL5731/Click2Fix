class AppConfig {
  static const appName = 'Click2Fix';
  static const tagline = 'Click the problem. Fix it instantly.';

  /// REST base URL — all API calls go to /api/*
  static const String apiBaseUrl = 'https://click2fix-backend.onrender.com/api';

  /// WebSocket / Socket.IO URL (no /api suffix)
  static const String socketUrl = 'https://click2fix-backend.onrender.com';

  /// Pass at build time via --dart-define=GOOGLE_MAPS_API_KEY=...
  static const String googleMapsApiKey =
      String.fromEnvironment('GOOGLE_MAPS_API_KEY', defaultValue: '');

  /// App version must match pubspec.yaml
  static const String appVersion = '0.1.1';
  static const int appVersionCode = 2;
}