import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_client.dart';

enum UserRole { user, worker, none }

class Session {
  const Session({
    this.token,
    this.role = UserRole.none,
    this.phone,
    this.name,
    this.isRestoring = false,
  });

  final String? token;
  final UserRole role;
  final String? phone;
  final String? name;
  final bool isRestoring;

  bool get isLoggedIn => token != null && token!.isNotEmpty && role != UserRole.none;
  bool get isUser => role == UserRole.user;
  bool get isWorker => role == UserRole.worker;

  Session copyWith({
    String? token,
    UserRole? role,
    String? phone,
    String? name,
    bool? isRestoring,
    bool clearPhone = false,
    bool clearName = false,
  }) {
    return Session(
      token: token ?? this.token,
      role: role ?? this.role,
      phone: clearPhone ? null : (phone ?? this.phone),
      name: clearName ? null : (name ?? this.name),
      isRestoring: isRestoring ?? this.isRestoring,
    );
  }
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

class SessionNotifier extends StateNotifier<Session> {
  SessionNotifier(this._apiClient)
      : super(const Session(isRestoring: true)) {
    restoreSession();
  }

  final ApiClient _apiClient;

  static const _tokenKey = 'click2fix_auth_token';
  static const _roleKey = 'click2fix_user_role';
  static const _phoneKey = 'click2fix_user_phone';
  static const _nameKey = 'click2fix_user_name';

  Future<bool> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      final roleStr = prefs.getString(_roleKey);

      if (token == null || token.isEmpty || roleStr == null) {
        state = const Session(isRestoring: false);
        return false;
      }

      final role = _parseRole(roleStr);
      if (role == UserRole.none) {
        await _clearSession();
        state = const Session(isRestoring: false);
        return false;
      }

      _apiClient.setToken(token);
      state = Session(
        token: token,
        role: role,
        phone: prefs.getString(_phoneKey),
        name: prefs.getString(_nameKey),
        isRestoring: false,
      );
      return true;
    } catch (error) {
      debugPrint('Failed to restore session: $error');
      state = const Session(isRestoring: false);
      return false;
    }
  }

  Future<Session?> restoreAndReturn() async {
    final found = await restoreSession();
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

  Future<void> login({
    required String token,
    required UserRole role,
    String? phone,
    String? name,
  }) async {
    _apiClient.setToken(token);
    state = Session(
      token: token,
      role: role,
      phone: phone,
      name: name,
      isRestoring: false,
    );
    await _persistSession(token, role, phone, name);
  }

  Future<void> updateProfile({String? phone, String? name}) async {
    state = state.copyWith(
      phone: phone,
      name: name,
      isRestoring: false,
    );
    if (!state.isLoggedIn || state.token == null) return;
    await _persistSession(state.token!, state.role, state.phone, state.name);
  }

  Future<void> logout() async {
    _apiClient.setToken(null);
    state = const Session(isRestoring: false);
    await _clearSession();
  }

  Future<void> _persistSession(
    String token,
    UserRole role,
    String? phone,
    String? name,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_roleKey, role.name);
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
    } catch (error) {
      debugPrint('Failed to persist session: $error');
    }
  }

  Future<void> _clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_roleKey);
      await prefs.remove(_phoneKey);
      await prefs.remove(_nameKey);
    } catch (error) {
      debugPrint('Failed to clear session: $error');
    }
  }
}

final sessionProvider = StateNotifierProvider<SessionNotifier, Session>((ref) {
  final client = ref.read(apiClientProvider);
  return SessionNotifier(client);
});