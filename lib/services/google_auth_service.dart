import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'api_client.dart';

class GoogleAuthService {
  final ApiClient _client;
  
  GoogleAuthService(this._client);

  bool _initialized = false;

  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (!_initialized) {
        await GoogleSignIn.instance.initialize();
        _initialized = true;
      }
      
      final GoogleSignInAccount? googleUser = await GoogleSignIn.instance.authenticate(
        scopeHint: const ['email', 'profile'],
      );
      
      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: (googleAuth as dynamic).accessToken,
        idToken: googleAuth.idToken,
      );

      return await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      debugPrint('Error during Google Sign in: \$e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> loginWithBackend({
    required User firebaseUser,
    required String role,
  }) async {
    try {
      final response = await _client.post('/auth/google-login', {
        'email': firebaseUser.email ?? '',
        'name': firebaseUser.displayName ?? 'Google User',
        'photoUrl': firebaseUser.photoURL ?? '',
        'firebaseUid': firebaseUser.uid,
        'role': role,
      });

      final data = response.data;
      if (data['token'] == null) {
        throw Exception('No token returned from backend for Google Login');
      }

      return data;
    } catch (e) {
      debugPrint('Error sending Google login to backend: \$e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('Google Sign out error: \$e');
    }
  }
}
