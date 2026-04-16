import 'api_client.dart';

class AuthService {
  AuthService(this._client);
  final ApiClient _client;

  /// Register with email/password
  Future<Map<String, dynamic>> register({
    String? email,
    String? password,
    required String role,
    String? name,
    String? phone,
    String? category,
  }) async {
    final response = await _client.post('/auth/register', {
      'email': email,
      'password': password ?? '',
      'role': role,
      'name': name,
      'phone': phone,
      'category': category,
    });
    return response.data as Map<String, dynamic>;
  }

  /// Login with email/password
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
      'idToken': firebaseIdToken,
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

  /// Get current user (Verify Session)
  Future<Map<String, dynamic>> getMe() async {
    final response = await _client.get('/auth/me');
    return response.data as Map<String, dynamic>;
  }

  /// Legacy helper for phone check (optional)
  Future<Map<String, dynamic>> checkUser({String? phone, String? email}) async {
    final response = await _client.get('/auth/check', queryParameters: {
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
    });
    return response.data as Map<String, dynamic>;
  }

  /// Restores session by verifying the stored token with the backend
  Future<Map<String, dynamic>?> restoreSession() async {
    try {
      final data = await getMe();
      return data;
    } catch (e) {
      return null;
    }
  }

  /// Stubs for compilation in other screens
  Future<void> requestUploadOtp(String phone) async {}
  Future<String> verifyUploadOtp(String phone, String otp) async => 'demo-otp-token';
  Future<String> verifyOtp(String phone, String otp, {required String role}) async => 'demo-token';
  Future<void> saveSession({required String token, required String role, String? phone}) async {}
}
