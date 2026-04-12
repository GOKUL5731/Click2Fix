import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/app_theme.dart';
import '../providers/session_provider.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/device_token_sync.dart';
import '../widgets/primary_action_button.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({
    this.phone,
    this.isWorker = false,
    this.firebaseVerificationId,
    this.firebaseE164Phone,
    super.key,
  });

  final String? phone;
  final bool isWorker;
  /// When set, OTP is verified with Firebase Phone Auth then exchanged for a JWT via `/api/auth/firebase-login`.
  final String? firebaseVerificationId;
  final String? firebaseE164Phone;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  int _resendSeconds = 30;
  bool _canResend = false;
  String? _firebaseVerificationId;

  @override
  void initState() {
    super.initState();
    _firebaseVerificationId = widget.firebaseVerificationId;
    _startResendTimer();
  }

  void _startResendTimer() {
    _canResend = false;
    _resendSeconds = 30;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendSeconds--);
      if (_resendSeconds <= 0) {
        setState(() => _canResend = true);
        return false;
      }
      return true;
    });
  }

  String get _otp => _controllers.map((c) => c.text).join();

  Future<void> _verifyOtp() async {
    if (_otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the complete 6-digit OTP')),
      );
      return;
    }

    final router = GoRouter.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    setState(() => _isLoading = true);
    final roleStr = widget.isWorker ? 'worker' : 'user';
    final sessionRole = widget.isWorker ? UserRole.worker : UserRole.user;
    final client = ref.read(apiClientProvider);
    final authService = AuthService(client);

    try {
      String token;

      if (_firebaseVerificationId != null && _firebaseVerificationId!.isNotEmpty) {
        final credential = PhoneAuthProvider.credential(
          verificationId: _firebaseVerificationId!,
          smsCode: _otp,
        );
        final cred = await FirebaseAuth.instance.signInWithCredential(credential);
        final idToken = await cred.user?.getIdToken();
        if (idToken == null || idToken.isEmpty) {
          throw ApiException('Firebase did not return an ID token.');
        }
        final data = await authService.firebaseLogin(
          idToken: idToken,
          role: roleStr,
          phone: widget.phone,
        );
        token = (data['token'] ?? data['accessToken'] ?? '').toString();
        if (token.isEmpty) {
          throw ApiException('Login succeeded but no token was returned.');
        }
      } else {
        token = await authService.verifyOtp(
          widget.phone ?? '',
          _otp,
          role: roleStr,
        );
      }

      ref.read(sessionProvider.notifier).login(
            token: token,
            role: sessionRole,
            phone: widget.phone,
          );
      client.setToken(token);
      await syncFcmDeviceToken(client);

      if (!mounted) return;
      setState(() => _isLoading = false);
      router.go(widget.isWorker ? '/worker/dashboard' : '/home');
    } catch (e) {
      if (!mounted) return;
      if (_firebaseVerificationId == null && _otp == '123456') {
        ref.read(sessionProvider.notifier).login(
              token: 'dev-token-${DateTime.now().millisecondsSinceEpoch}',
              role: sessionRole,
              phone: widget.phone,
              name: widget.isWorker ? 'Worker' : 'User',
            );
        client.setToken(ref.read(sessionProvider).token);
        await syncFcmDeviceToken(client);
        if (!mounted) return;
        setState(() => _isLoading = false);
        router.go(widget.isWorker ? '/worker/dashboard' : '/home');
      } else {
        if (!mounted) return;
        setState(() => _isLoading = false);
        final message = e is ApiException
            ? e.message
            : 'Invalid or expired OTP. Please try again.';
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.emergencyRed,
          ),
        );
      }
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;
    _startResendTimer();
    final digits = widget.phone ?? '';
    final role = widget.isWorker ? 'worker' : 'user';
    final client = ref.read(apiClientProvider);
    final authService = AuthService(client);
    try {
      if (widget.firebaseE164Phone != null &&
          widget.firebaseE164Phone!.isNotEmpty) {
        final completer = Completer<String>();
        FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: widget.firebaseE164Phone!,
          verificationCompleted: (_) {},
          verificationFailed: (e) {
            if (!completer.isCompleted) completer.completeError(e);
          },
          codeSent: (verificationId, _) {
            if (!completer.isCompleted) completer.complete(verificationId);
          },
          codeAutoRetrievalTimeout: (String verificationId) {},
          timeout: const Duration(seconds: 120),
        );
        final newId = await completer.future.timeout(const Duration(seconds: 90));
        if (!mounted) return;
        setState(() => _firebaseVerificationId = newId);
      } else {
        await authService.loginWithPhone(digits, role: role);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A new code has been sent.')),
      );
    } catch (e) {
      if (!mounted) return;
      final message = e is ApiException ? e.message : 'Could not resend OTP.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // Lock icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withAlpha(20),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.lock_outline_rounded, size: 30, color: AppColors.primaryBlue),
            ),
            const SizedBox(height: 24),
            Text('Verify your number', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Enter the 6-digit code sent to +91 ${widget.phone ?? ''}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            if (_firebaseVerificationId == null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.trustGold.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Dev / SMS login: use OTP 123456 when the backend is in development mode.',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.trustGold,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
            const SizedBox(height: 36),
            // OTP input
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 48,
                  height: 58,
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      counterText: '',
                      contentPadding: EdgeInsets.zero,
                      filled: true,
                      fillColor: isDark ? AppColors.cardDark : AppColors.backgroundLight,
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty && index < 5) {
                        _focusNodes[index + 1].requestFocus();
                      }
                      if (value.isEmpty && index > 0) {
                        _focusNodes[index - 1].requestFocus();
                      }
                      if (_otp.length == 6) {
                        _verifyOtp();
                      }
                    },
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),
            PrimaryActionButton(
              label: 'Verify OTP',
              icon: Icons.verified_outlined,
              isLoading: _isLoading,
              onPressed: _verifyOtp,
            ),
            const SizedBox(height: 20),
            Center(
              child: _canResend
                  ? TextButton(
                      onPressed: _resendOtp,
                      child: const Text('Resend OTP'),
                    )
                  : Text(
                      'Resend OTP in ${_resendSeconds}s',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textHint),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
