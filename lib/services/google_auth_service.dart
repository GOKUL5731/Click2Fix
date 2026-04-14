import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'api_client.dart';

class GoogleAuthService {
  final ApiClient _client;

  GoogleAuthService(this._client);

  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await GoogleSignIn.instance.initialize(
        serverClientId: '926338625536-gbuohg1dtq81n42fnmhefqc5qno94n62.apps.googleusercontent.com',
      );
      _initialized = true;
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      await _ensureInitialized();
      final GoogleSignInAccount? googleUser = await GoogleSignIn.instance.authenticate();

      if (googleUser == null) {
        return null; // User cancelled
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: null, // As of 7.2.0 accessToken moved to authorizationForScopes but idToken is sufficient for Firebase
        idToken: googleAuth.idToken,
      );

      return await FirebaseAuth.instance.signInWithCredential(credential);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }
      debugPrint('Google Sign in Exception: $e');
      rethrow;
    } catch (e) {
      debugPrint('Error during Google Sign in: $e');
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
      debugPrint('Error sending Google login to backend: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _ensureInitialized();
      await GoogleSignIn.instance.signOut();
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('Google Sign out error: $e');
    }
  }
}
