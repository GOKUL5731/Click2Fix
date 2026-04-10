class AppConfig {
  static const appName = 'Click2Fix Worker';
  static const environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8080');
  static const socketUrl = String.fromEnvironment('SOCKET_URL', defaultValue: 'http://localhost:8080');
  static const googleMapsApiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY', defaultValue: '');
}
