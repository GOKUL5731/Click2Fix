import 'api_client.dart';

class AuthService {
  AuthService(this._client);

  final ApiClient _client;

  Future<void> loginWithPhone(String phone) async {
    await _client.post('/auth/login', {'role': 'user', 'phone': phone});
  }

  Future<String> verifyOtp(String phone, String otp) async {
    final response = await _client.post('/auth/verify-otp', {'role': 'user', 'phone': phone, 'otp': otp});
    return response.data['token'] as String;
  }
}

