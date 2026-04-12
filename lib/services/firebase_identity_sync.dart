import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/session_provider.dart';
import 'api_client.dart';
import 'auth_service.dart';
import 'device_token_sync.dart';

/// After [FirebaseAuth] sign-in (Google, email/password, etc.), exchanges the ID token for your API JWT.
class FirebaseIdentitySync {
  static Future<void> exchangeIdTokenForBackendJwt({
    required WidgetRef ref,
    required UserRole role,
    String? explicitPhone,
    String? explicitName,
    String? category,
    int? experience,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw ApiException('No Firebase user session.');
    }
    final idToken = await user.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw ApiException('Could not read Firebase ID token.');
    }
    final client = ref.read(apiClientProvider);
    final authService = AuthService(client);
    final roleStr = role == UserRole.worker ? 'worker' : 'user';
    final data = await authService.firebaseLogin(
      idToken: idToken,
      role: roleStr,
      phone: explicitPhone ?? user.phoneNumber,
      name: explicitName ?? user.displayName,
      category: category,
      experience: experience,
    );
    final token = (data['token'] ?? data['accessToken'] ?? '').toString();
    if (token.isEmpty) {
      throw ApiException('Login succeeded but no token was returned.');
    }
    client.setToken(token);
    final name = explicitName ??
        user.displayName ??
        user.email?.split('@').first;
    await ref.read(sessionProvider.notifier).login(
          token: token,
          role: role,
          phone: user.phoneNumber ?? explicitPhone,
          name: name,
        );
    await syncFcmDeviceToken(client);
  }
}
