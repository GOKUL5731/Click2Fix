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
    required String email,
    required String password,
    String? name,
    String? phone,
    String? category,
    int? experience,
  }) async {
    final response = await _client.post('/auth/register', {
      'role': role,
      'email': email,
      'password': password,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (category != null) 'category': category,
      if (experience != null) 'experience': experience,
    });
    return response.data as Map<String, dynamic>;
  }

  /// Login with email and password
  Future<Map<String, dynamic>> loginWithEmail({
    required String email,
    required String password,
    required String role,
  }) async {
    final response = await _client.post('/auth/login', {
      'email': email,
      'password': password,
      'role': role,
    });
    return response.data as Map<String, dynamic>;
  }

  /// Login with Google
  Future<Map<String, dynamic>> loginWithGoogle({
    required String firebaseIdToken,
    required String role,
    required String email,
    String? name,
    String? photoUrl,
    required String firebaseUid,
  }) async {
    final response = await _client.post('/auth/google-login', {
      'role': role,
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'firebaseUid': firebaseUid,
      'idToken': firebaseIdToken, // For backend verification
    });
    return response.data as Map<String, dynamic>;
  }

  /// Forgot password
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await _client.post('/auth/forgot-password', {
      'email': email,
    });
    return response.data as Map<String, dynamic>;
  }

  /// Get current user profile
  Future<Map<String, dynamic>> getMe() async {
    final response = await _client.get('/auth/me');
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

  /// Restore session from local storage and verify it
  Future<Map<String, String?>?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final role = prefs.getString(_roleKey);
    
    if (token == null || role == null) return null;

    _client.setToken(token);
    
    try {
      // Verify token with backend
      await getMe();
      
      return {
        'token': token,
        'role': role,
        'phone': prefs.getString(_phoneKey),
        'name': prefs.getString(_nameKey),
      };
    } catch (e) {
      // Token invalid or expired
      await logout();
      return null;
    }
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
