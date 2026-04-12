class AppConfig {
  static const appName = 'Click2Fix Admin';
  static const environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://click2fix-backend.onrender.com',
  );
}
