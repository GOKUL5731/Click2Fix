import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';

class AuthService {
  AuthService(this._client);

  final ApiClient _client;
  static const _tokenKey = 'click2fix_auth_token';
  static const _roleKey = 'click2fix_user_role';
  static const _phoneKey = 'click2fix_user_phone';
  static const _nameKey = 'click2fix_user_name';

  Future<Map<String, dynamic>> register({
    required String role,
    required String phone,
    String? name,
    String? email,
    String? category,
    int? experience,
  }) async {
    final response = await _client.post('/api/auth/register', {
      'role': role,
      'phone': phone,
      if (name != null && name.isNotEmpty) 'name': name,
      if (email != null && email.isNotEmpty) 'email': email,
      if (category != null && category.isNotEmpty) 'category': category,
      if (experience != null) 'experience': experience,
    });
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> loginWithPhone(
    String phone, {
    String role = 'user',
  }) async {
    final response = await _client.post('/api/auth/login', {
      'role': role,
      'phone': phone,
    });
    return _asMap(response.data);
  }

  Future<String> verifyOtp(
    String phone,
    String otp, {
    String role = 'user',
  }) async {
    final response = await _client.post('/api/auth/verify-otp', {
      'role': role,
      'phone': phone,
      'otp': otp,
    });
    final data = _asMap(response.data);
    final token = (data['token'] ?? data['accessToken'] ?? '').toString();
    if (token.isEmpty) {
      throw ApiException('Login succeeded but no token was returned.');
    }
    _client.setToken(token);
    return token;
  }

  Future<Map<String, dynamic>> requestUploadOtp(String phone) async {
    final response = await _client.post('/api/auth/request-upload-otp', {
      'phone': phone,
    });
    return _asMap(response.data);
  }

  Future<String> verifyUploadOtp(String phone, String otp) async {
    final response = await _client.post('/api/auth/verify-upload-otp', {
      'phone': phone,
      'otp': otp,
    });
    final data = _asMap(response.data);
    final uploadToken = (data['uploadToken'] ?? data['token'] ?? '').toString();
    if (uploadToken.isEmpty) {
      throw ApiException('Verification succeeded but upload token was missing.');
    }
    return uploadToken;
  }

  Future<Map<String, dynamic>> firebaseLogin({
    required String idToken,
    required String role,
    String? phone,
    String? name,
    String? category,
    int? experience,
  }) async {
    final response = await _client.post('/api/auth/firebase-login', {
      'idToken': idToken,
      'role': role,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (name != null && name.isNotEmpty) 'name': name,
      if (category != null && category.isNotEmpty) 'category': category,
      if (experience != null) 'experience': experience,
    });
    return _asMap(response.data);
  }

  Future<void> saveSession({
    required String token,
    required String role,
    String? phone,
    String? name,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_roleKey, role);
    if (phone != null && phone.isNotEmpty) {
      await prefs.setString(_phoneKey, phone);
    } else {
      await prefs.remove(_phoneKey);
    }
    if (name != null && name.isNotEmpty) {
      await prefs.setString(_nameKey, name);
    } else {
      await prefs.remove(_nameKey);
    }
    _client.setToken(token);
  }

  Future<Map<String, String?>?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null || token.isEmpty) return null;

    _client.setToken(token);
    return {
      'token': token,
      'role': prefs.getString(_roleKey),
      'phone': prefs.getString(_phoneKey),
      'name': prefs.getString(_nameKey),
    };
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_phoneKey);
    await prefs.remove(_nameKey);
    _client.setToken(null);
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map(
        (key, item) => MapEntry(key.toString(), item),
      );
    }
    return <String, dynamic>{};
  }
}