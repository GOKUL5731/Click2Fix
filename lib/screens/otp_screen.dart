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
import '../widgets/app_button.dart';

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
    if (_otp.length < 6) return;

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
        if (idToken == null) throw ApiException('Failed to get Firebase token.');
        final data = await authService.firebaseLogin(
          idToken: idToken,
          role: roleStr,
          phone: widget.phone,
        );
        token = (data['token'] ?? data['accessToken']).toString();
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
      context.go(widget.isWorker ? '/worker/dashboard' : '/home');
    } catch (e) {
      if (!mounted) return;
      // Allow fallback code '123456' for local testing
      if (_firebaseVerificationId == null && _otp == '123456') {
        ref.read(sessionProvider.notifier).login(
              token: 'dev-token',
              role: sessionRole,
              phone: widget.phone,
            );
        context.go(widget.isWorker ? '/worker/dashboard' : '/home');
        return;
      }
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            const Text(
              'Verify Number',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter the 6-digit code sent to +91 ${widget.phone ?? ''}',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 48,
                  height: 56,
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      counterText: '',
                      contentPadding: EdgeInsets.zero,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.divider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.divider),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
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
            const SizedBox(height: 48),
            AppButton(
              text: 'Verify OTP',
              onPressed: _verifyOtp,
              isLoading: _isLoading,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Didn\'t receive code?', style: TextStyle(color: AppColors.textLight)),
                TextButton(
                  onPressed: _canResend ? _startResendTimer : null,
                  child: Text(
                    _canResend ? 'Resend' : 'Resend in ${_resendSeconds}s',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _canResend ? AppColors.primary : AppColors.textHint,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
