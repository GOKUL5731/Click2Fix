import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_client.dart';

enum UserRole { user, worker, none }

class Session {
  const Session({this.token, this.role = UserRole.none, this.phone, this.name});
  final String? token;
  final UserRole role;
  final String? phone;
  final String? name;
  bool get isLoggedIn => token != null && role != UserRole.none;
  bool get isUser => role == UserRole.user;
  bool get isWorker => role == UserRole.worker;
}

/// Shared ApiClient instance — injected into all services.
/// The SessionNotifier updates the token on login/logout.
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

class SessionNotifier extends StateNotifier<Session> {
  SessionNotifier(this._apiClient) : super(const Session()) {
    _restoreSession();
  }

  final ApiClient _apiClient;

  static const _tokenKey = 'click2fix_auth_token';
  static const _roleKey = 'click2fix_user_role';
  static const _phoneKey = 'click2fix_user_phone';
  static const _nameKey = 'click2fix_user_name';

  /// Restore saved session from SharedPreferences on app start.
  Future<bool> _restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      if (token == null) return false;

      final roleStr = prefs.getString(_roleKey) ?? 'none';
      final role = _parseRole(roleStr);
      if (role == UserRole.none) return false;

      _apiClient.setToken(token);
      state = Session(
        token: token,
        role: role,
        phone: prefs.getString(_phoneKey),
        name: prefs.getString(_nameKey),
      );
      return true;
    } catch (e) {
      debugPrint('Failed to restore session: $e');
      return false;
    }
  }

  /// Restore session and return whether one was found (for splash screen redirect).
  Future<Session?> restoreAndReturn() async {
    final found = await _restoreSession();
    return found ? state : null;
  }

  UserRole _parseRole(String roleStr) {
    switch (roleStr) {
      case 'user':
        return UserRole.user;
      case 'worker':
        return UserRole.worker;
      default:
        return UserRole.none;
    }
  }

  void login({required String token, required UserRole role, String? phone, String? name}) {
    _apiClient.setToken(token);
    state = Session(token: token, role: role, phone: phone, name: name);
    _persistSession(token, role, phone, name);
  }

  void logout() {
    _apiClient.setToken(null);
    state = const Session();
    _clearSession();
  }

  Future<void> _persistSession(String token, UserRole role, String? phone, String? name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_roleKey, role.name);
      if (phone != null) await prefs.setString(_phoneKey, phone);
      if (name != null) await prefs.setString(_nameKey, name);
    } catch (e) {
      debugPrint('Failed to persist session: $e');
    }
  }

  Future<void> _clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_roleKey);
      await prefs.remove(_phoneKey);
      await prefs.remove(_nameKey);
    } catch (e) {
      debugPrint('Failed to clear session: $e');
    }
  }
}

final sessionProvider = StateNotifierProvider<SessionNotifier, Session>((ref) {
  final client = ref.read(apiClientProvider);
  return SessionNotifier(client);
});
