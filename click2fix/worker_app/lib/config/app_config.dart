class AppConfig {
  static const appName = 'Click2Fix Worker';
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8080');
  static const socketUrl = String.fromEnvironment('SOCKET_URL', defaultValue: 'http://localhost:8080');
}

