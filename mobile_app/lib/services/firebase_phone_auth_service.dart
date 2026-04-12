import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'api_client.dart';

/// Result returned once Firebase phone verification completes.
class FirebasePhoneResult {
  const FirebasePhoneResult({
    required this.firebaseIdToken,
    required this.firebaseUid,
    this.phoneNumber,
  });
  final String firebaseIdToken;
  final String firebaseUid;
  final String? phoneNumber;
}

/// Service that wraps Firebase Phone Authentication.
///
/// Flow:
///  1. Call [sendOtp] → Firebase sends SMS to the phone number.
///  2. User enters code.
///  3. Call [verifyOtp] → Firebase verifies + returns [FirebasePhoneResult].
///  4. Caller exchanges `firebaseIdToken` with backend `/auth/firebase-login`.
class FirebasePhoneAuthService {
  FirebasePhoneAuthService(this._apiClient);

  final ApiClient _apiClient;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _verificationId;
  int? _resendToken;
  late final StreamController<String> _statusController =
      StreamController.broadcast();

  /// Live status messages ("Sending OTP…", "OTP sent!", etc.)
  Stream<String> get statusStream => _statusController.stream;

  // ── Send OTP ────────────────────────────────────────────────────────

  /// Starts phone verification for [phoneNumber] (E.164 format, e.g. +919876543210).
  ///
  /// Returns `true` when OTP was dispatched successfully.
  Future<void> sendOtp(
    String phoneNumber, {
    required void Function(String verificationId) onCodeSent,
    required void Function(String errorMessage) onError,
    void Function(PhoneAuthCredential credential)? onAutoVerified,
  }) async {
    _statusController.add('Sending OTP…');

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        forceResendingToken: _resendToken,

        // Auto-retrieved (Android only)
        verificationCompleted: (PhoneAuthCredential credential) async {
          _statusController.add('OTP auto-verified!');
          onAutoVerified?.call(credential);
        },

        // Verification failed
        verificationFailed: (FirebaseAuthException e) {
          final msg = _friendlyFirebaseError(e);
          _statusController.add('Error: $msg');
          onError(msg);
        },

        // Code sent successfully
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          _statusController.add('OTP sent!');
          onCodeSent(verificationId);
        },

        // Timeout
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      final msg = 'Failed to send OTP: ${e.toString()}';
      _statusController.add(msg);
      onError(msg);
    }
  }

  // ── Verify OTP ──────────────────────────────────────────────────────

  /// Verifies [otp] against the previously sent code.
  /// Returns a [FirebasePhoneResult] containing the ID token to exchange for a JWT.
  Future<FirebasePhoneResult> verifyOtp(String otp) async {
    if (_verificationId == null) {
      throw Exception('No active OTP session. Please request a new OTP.');
    }

    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: otp,
    );

    return _signInWithCredential(credential);
  }

  /// Sign in with a [PhoneAuthCredential] (e.g. from auto-verification).
  Future<FirebasePhoneResult> signInWithCredential(PhoneAuthCredential credential) =>
      _signInWithCredential(credential);

  Future<FirebasePhoneResult> _signInWithCredential(AuthCredential credential) async {
    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user == null) throw Exception('Firebase sign-in returned no user.');

    final idToken = await user.getIdToken(true); // force-refresh
    if (idToken == null) throw Exception('Could not obtain Firebase ID token.');

    return FirebasePhoneResult(
      firebaseIdToken: idToken,
      firebaseUid: user.uid,
      phoneNumber: user.phoneNumber,
    );
  }

  // ── Exchange Firebase ID token for backend JWT ──────────────────────

  /// Sends the Firebase ID token to the backend and returns the backend JWT.
  Future<Map<String, dynamic>> exchangeForBackendJwt({
    required String firebaseIdToken,
    required String role,
    String? phone,
    String? name,
    String? category,
  }) async {
    final response = await _apiClient.post('/auth/firebase-login', {
      'idToken': firebaseIdToken,
      'role': role,
      if (phone != null) 'phone': phone,
      if (name != null) 'name': name,
      if (category != null) 'category': category,
    });
    return response.data as Map<String, dynamic>;
  }

  // ── Google Sign In ──────────────────────────────────────────────────

  /// Sign in with Google and return the backend JWT.
  Future<Map<String, dynamic>> signInWithGoogle({
    required String role,
  }) async {
    final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) throw Exception('Google Sign-In cancelled.');

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user == null) throw Exception('Firebase sign-in returned no user.');

    final idToken = await user.getIdToken(true);
    if (idToken == null) throw Exception('Could not obtain Firebase ID token.');

    // Exchange Firebase token for backend JWT
    final response = await _apiClient.post('/auth/google-login', {
      'role': role,
      'email': user.email ?? googleUser.email,
      'name': user.displayName ?? googleUser.displayName,
      'photoUrl': user.photoURL,
      'firebaseUid': user.uid,
    });
    return response.data as Map<String, dynamic>;
  }

  // ── Sign out ────────────────────────────────────────────────────────

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Firebase sign out error: $e');
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────

  String _friendlyFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'Invalid phone number. Use format: +91XXXXXXXXXX';
      case 'too-many-requests':
        return 'Too many OTP requests. Please wait a few minutes and try again.';
      case 'quota-exceeded':
        return 'Daily SMS quota exceeded. Please try again tomorrow.';
      case 'invalid-verification-code':
        return 'Incorrect OTP. Please check and try again.';
      case 'session-expired':
        return 'OTP expired. Please request a new one.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      case 'app-not-authorized':
        return 'App not authorized for Firebase. Contact support.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }

  void dispose() {
    _statusController.close();
  }
}
