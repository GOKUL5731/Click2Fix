import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/app_theme.dart';
import '../providers/session_provider.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/firebase_identity_sync.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';

enum _LoginMode { phone, email }

bool _googleSignInInitialized = false;

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isWorker = false;
  bool _isLoading = false;
  _LoginMode _loginMode = _LoginMode.phone;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    final router = GoRouter.of(context);
    setState(() => _isLoading = true);
    
    try {
      final googleAuthService = ref.read(googleAuthProvider);
      final credential = await googleAuthService.signInWithGoogle();
      
      if (credential == null || credential.user == null) {
        setState(() => _isLoading = false);
        return; // User cancelled
      }

      final roleStr = _isWorker ? 'worker' : 'user';
      final response = await googleAuthService.loginWithBackend(
        firebaseUser: credential.user!,
        role: roleStr,
      );

      if (!mounted) return;
      
      ref.read(sessionProvider.notifier).login(
        token: response['token'],
        role: _isWorker ? UserRole.worker : UserRole.user,
        name: credential.user!.displayName ?? response['user']?['name'],
        phone: credential.user!.phoneNumber ?? response['user']?['phone'],
      );

      setState(() => _isLoading = false);
      router.go(_isWorker ? '/worker/dashboard' : '/home');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(e is ApiException ? e.message : 'Google sign-in failed: $e');
    }
  }

  Future<void> _signInWithEmailPassword() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (!email.contains('@') || password.length < 6) {
      _showError('Enter a valid email and password (min 6 characters).');
      return;
    }
    final router = GoRouter.of(context);
    setState(() => _isLoading = true);
    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
        await FirebaseIdentitySync.exchangeIdTokenForBackendJwt(
          ref: ref,
          role: _isWorker ? UserRole.worker : UserRole.user,
        );
      } else {
        // Fallback to backend directly if configured (usually we rely on firebase in this app)
        final client = ref.read(apiClientProvider);
        final res = await client.post('/auth/login', {
          'email': email,
          'password': password,
          'role': _isWorker ? 'worker' : 'user',
        });
        final token = res.data['token'];
        ref.read(sessionProvider.notifier).login(
          token: token,
          role: _isWorker ? UserRole.worker : UserRole.user,
        );
        client.setToken(token);
      }
      if (!mounted) return;
      setState(() => _isLoading = false);
      router.go(_isWorker ? '/worker/dashboard' : '/home');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(e is ApiException ? e.message : 'Sign-in failed.');
    }
  }

  Future<void> _sendOtp() async {
    final raw = _phoneController.text.trim().replaceAll(RegExp(r'\s+'), '');
    final digits = raw.replaceFirst(RegExp(r'^\+?91'), '').replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) {
      _showError('Please enter a valid 10-digit mobile number');
      return;
    }
    final e164 = '+91$digits';
    setState(() => _isLoading = true);
    final role = _isWorker ? 'worker' : 'user';
    final client = ref.read(apiClientProvider);
    final authService = AuthService(client);

    if (Firebase.apps.isNotEmpty && !kIsWeb) {
      try {
        final completer = Completer<String>();
        FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: e164,
          verificationCompleted: (_) {},
          verificationFailed: (e) {
            if (!completer.isCompleted) completer.completeError(e);
          },
          codeSent: (verificationId, _) {
            if (!completer.isCompleted) completer.complete(verificationId);
          },
          codeAutoRetrievalTimeout: (_) {},
          timeout: const Duration(seconds: 120),
        );
        final verificationId = await completer.future.timeout(
          const Duration(seconds: 90),
          onTimeout: () => throw TimeoutException('Verification timed out'),
        );
        if (!mounted) return;
        setState(() => _isLoading = false);
        context.go('/otp', extra: {
          'phone': digits,
          'isWorker': _isWorker,
          'verificationId': verificationId,
          'e164Phone': e164,
        });
        return;
      } catch (e) {
        debugPrint('Firebase SMS failed: $e');
      }
    }

    try {
      await authService.loginWithPhone(digits, role: role);
      if (!mounted) return;
      setState(() => _isLoading = false);
      context.go('/otp', extra: {'phone': digits, 'isWorker': _isWorker});
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(e is ApiException ? e.message : 'Could not send OTP.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              // Logo & Welcome
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.build_circle,
                    size: 48,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Welcome Back',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign in to continue to Click2Fix',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textLight,
                ),
              ),
              const SizedBox(height: 32),
              
              // Role Toggle
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _RoleTab(
                        label: 'Customer',
                        isActive: !_isWorker,
                        onTap: () => setState(() => _isWorker = false),
                      ),
                    ),
                    Expanded(
                      child: _RoleTab(
                        label: 'Worker',
                        isActive: _isWorker,
                        onTap: () => setState(() => _isWorker = true),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Mode Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text('Phone'),
                    selected: _loginMode == _LoginMode.phone,
                    onSelected: (val) {
                      if (val) setState(() => _loginMode = _LoginMode.phone);
                    },
                  ),
                  const SizedBox(width: 12),
                  ChoiceChip(
                    label: const Text('Email'),
                    selected: _loginMode == _LoginMode.email,
                    onSelected: (val) {
                      if (val) setState(() => _loginMode = _LoginMode.email);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Inputs
              if (_loginMode == _LoginMode.phone) ...[
                AppTextField(
                  label: 'Mobile Number',
                  hint: 'Enter your 10-digit number',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                    child: Text('+91', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),
                AppButton(
                  text: 'Send OTP',
                  onPressed: _sendOtp,
                  isLoading: _isLoading,
                ),
              ] else ...[
                AppTextField(
                  label: 'Email',
                  hint: 'you@example.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Password',
                  hint: 'Enter your password',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                const SizedBox(height: 24),
                AppButton(
                  text: 'Sign In',
                  onPressed: _signInWithEmailPassword,
                  isLoading: _isLoading,
                ),
              ],
              
              const SizedBox(height: 32),
              
              // Google Sign In
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _signInWithGoogle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: AppColors.divider.withOpacity(0.5)),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: _isLoading 
                    ? const SizedBox(
                        width: 24, height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ) 
                    : const Icon(Icons.g_mobiledata, size: 28, color: Colors.blue),
                  label: const Text(
                    'Continue with Google',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Don\'t have an account?', style: TextStyle(color: AppColors.textLight)),
                  TextButton(
                    onPressed: () => context.go('/register'),
                    child: const Text('Sign Up', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleTab extends StatelessWidget {
  const _RoleTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : AppColors.textLight,
          ),
        ),
      ),
    );
  }
}
