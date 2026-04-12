import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

class AuthService {
  AuthService(this._client);

  final ApiClient _client;
  static const _tokenKey = 'click2fix_auth_token';
  static const _roleKey = 'click2fix_user_role';
  static const _phoneKey = 'click2fix_user_phone';
  static const _nameKey = 'click2fix_user_name';

  /// Register a new user or worker
  Future<Map<String, dynamic>> register({
    required String role,
    required String phone,
    String? name,
    String? email,
    String? category,
    int? experience,
  }) async {
    final response = await _client.post('/auth/register', {
      'role': role,
      'phone': phone,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (category != null) 'category': category,
      if (experience != null) 'experience': experience,
    });
    return response.data as Map<String, dynamic>;
  }

  /// Request login OTP
  Future<Map<String, dynamic>> loginWithPhone(String phone, {String role = 'user'}) async {
    final response = await _client.post('/auth/login', {
      'role': role,
      'phone': phone,
    });
    return response.data as Map<String, dynamic>;
  }

  /// Check if user exists
  Future<Map<String, dynamic>> checkUser({String? phone, String? email}) async {
    final response = await _client.post('/auth/check-user', {
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
    });
    return response.data as Map<String, dynamic>;
  }

  /// Verify OTP and get token
  Future<String> verifyOtp(String phone, String otp, {String role = 'user'}) async {
    final response = await _client.post('/auth/verify-otp', {
      'role': role,
      'phone': phone,
      'otp': otp,
    });
    final token = response.data['token'] as String;
    _client.setToken(token);
    return token;
  }

  /// Request upload OTP
  Future<Map<String, dynamic>> requestUploadOtp(String phone) async {
    final response = await _client.post('/auth/request-upload-otp', {'phone': phone});
    return response.data as Map<String, dynamic>;
  }

  /// Verify upload OTP
  Future<String> verifyUploadOtp(String phone, String otp) async {
    final response = await _client.post('/auth/verify-upload-otp', {
      'phone': phone,
      'otp': otp,
    });
    return response.data['uploadToken'] as String;
  }

  /// Save session to local storage
  Future<void> saveSession({
    required String token,
    required String role,
    String? phone,
    String? name,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_roleKey, role);
    if (phone != null) await prefs.setString(_phoneKey, phone);
    if (name != null) await prefs.setString(_nameKey, name);
    _client.setToken(token);
  }

  /// Restore session from local storage
  Future<Map<String, String?>?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null) return null;

    _client.setToken(token);
    return {
      'token': token,
      'role': prefs.getString(_roleKey),
      'phone': prefs.getString(_phoneKey),
      'name': prefs.getString(_nameKey),
    };
  }

  /// Clear session
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_phoneKey);
    await prefs.remove(_nameKey);
    _client.setToken(null);
  }
}
