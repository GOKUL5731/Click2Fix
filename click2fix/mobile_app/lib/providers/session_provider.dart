import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class SessionNotifier extends StateNotifier<Session> {
  SessionNotifier() : super(const Session());

  void login({required String token, required UserRole role, String? phone, String? name}) {
    state = Session(token: token, role: role, phone: phone, name: name);
  }

  void logout() {
    state = const Session();
  }
}

final sessionProvider = StateNotifierProvider<SessionNotifier, Session>((ref) {
  return SessionNotifier();
});
