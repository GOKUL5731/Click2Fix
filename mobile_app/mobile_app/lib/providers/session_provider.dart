import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import '../services/socket_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

enum UserRole { user, worker, none }

class Session {
  const Session({this.token, this.role = UserRole.none, this.phone, this.email, this.name});
  final String? token;
  final UserRole role;
  final String? phone;
  final String? email;
  final String? name;
  bool get isLoggedIn => token != null && role != UserRole.none;
  bool get isUser => role == UserRole.user;
  bool get isWorker => role == UserRole.worker;
}

class SessionNotifier extends StateNotifier<Session> {
  SessionNotifier() : super(const Session()) {
    _restoreSession();
  }

  static const _tokenKey = 'click2fix_auth_token';
  static const _roleKey = 'click2fix_user_role';
  static const _phoneKey = 'click2fix_user_phone';
  static const _emailKey = 'click2fix_user_email';
  static const _nameKey = 'click2fix_user_name';

  Future<void> _restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      if (token == null) return;

      final roleStr = prefs.getString(_roleKey) ?? 'none';
      UserRole role;
      switch (roleStr) {
        case 'user':
          role = UserRole.user;
          break;
        case 'worker':
          role = UserRole.worker;
          break;
        default:
          role = UserRole.none;
      }

      state = Session(
        token: token,
        role: role,
        phone: prefs.getString(_phoneKey),
        email: prefs.getString(_emailKey),
        name: prefs.getString(_nameKey),
      );
      
// SocketService().connect(token);
    } catch (e) {
      debugPrint('Failed to restore session: $e');
    }
  }

  void login({required String token, required UserRole role, String? phone, String? email, String? name}) {
    state = Session(token: token, role: role, phone: phone, email: email, name: name);
    _persistSession(token, role, phone, email, name);
// SocketService().connect(token);
  }

  void logout() {
    state = const Session();
    _clearSession();
// SocketService().disconnect();
    
    // Sign out from Firebase and Google
    FirebaseAuth.instance.signOut().catchError((_) {});
    GoogleSignIn().signOut().catchError((_) {});
  }

  Future<void> _persistSession(String token, UserRole role, String? phone, String? email, String? name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_roleKey, role.name);
      if (phone != null) await prefs.setString(_phoneKey, phone);
      if (email != null) await prefs.setString(_emailKey, email);
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
      await prefs.remove(_emailKey);
      await prefs.remove(_nameKey);
    } catch (e) {
      debugPrint('Failed to clear session: $e');
    }
  }
}

final sessionProvider = StateNotifierProvider<SessionNotifier, Session>((ref) {
  return SessionNotifier();
});
