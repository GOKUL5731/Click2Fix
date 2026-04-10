import 'api_client.dart';
import 'push_notification_service.dart';

class AuthService {
  AuthService(this._client, this._pushNotificationService);

  final ApiClient _client;
  final PushNotificationService _pushNotificationService;

  Future<void> loginWithPhone(String phone) async {
    await _client.post('/auth/login', {'role': 'user', 'phone': phone});
  }

  Future<String> verifyOtp(String phone, String otp) async {
    final response = await _client
        .post('/auth/verify-otp', {'role': 'user', 'phone': phone, 'otp': otp});
    final token = response.data['token'] as String;
    await _pushNotificationService.registerDeviceToken(
        apiClient: _client, authToken: token, appVariant: 'mobile');
    return token;
  }
}
