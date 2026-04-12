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
import '../widgets/primary_action_button.dart';

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
    if (Firebase.apps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Firebase is not configured. Add google-services.json and rebuild.')),
      );
      return;
    }
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isLoading = true);
    try {
      if (!_googleSignInInitialized) {
        await GoogleSignIn.instance.initialize();
        _googleSignInInitialized = true;
      }
      final googleUser = await GoogleSignIn.instance.authenticate(
        scopeHint: const ['email', 'profile'],
      );
      final googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: null,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      if (!mounted) return;
      await FirebaseIdentitySync.exchangeIdTokenForBackendJwt(
        ref: ref,
        role: _isWorker ? UserRole.worker : UserRole.user,
      );
      if (!mounted) return;
      setState(() => _isLoading = false);
      router.go(_isWorker ? '/worker/dashboard' : '/home');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      messenger.showSnackBar(SnackBar(content: Text(e.message ?? 'Google sign-in failed')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      final message = e is ApiException ? e.message : 'Google sign-in failed. Check Firebase and backend setup.';
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _signInWithEmailPassword() async {
    if (Firebase.apps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Firebase is not configured.')),
      );
      return;
    }
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (!email.contains('@') || password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid email and password (min 6 characters).')),
      );
      return;
    }
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      if (!mounted) return;
      await FirebaseIdentitySync.exchangeIdTokenForBackendJwt(
        ref: ref,
        role: _isWorker ? UserRole.worker : UserRole.user,
      );
      if (!mounted) return;
      setState(() => _isLoading = false);
      router.go(_isWorker ? '/worker/dashboard' : '/home');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      messenger.showSnackBar(SnackBar(content: Text(e.message ?? 'Sign-in failed')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      final message = e is ApiException ? e.message : 'Sign-in failed.';
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final resetEmailController = TextEditingController(text: _emailController.text.trim());
    bool? submitted;
    String? emailToReset;
    try {
      submitted = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Reset password'),
          content: TextField(
            controller: resetEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'you@example.com',
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Send link')),
          ],
        ),
      );
      if (submitted == true) {
        emailToReset = resetEmailController.text.trim();
      }
    } finally {
      resetEmailController.dispose();
    }
    if (emailToReset == null || !mounted) return;
    final email = emailToReset;
    if (!email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid email address.')),
      );
      return;
    }
    if (Firebase.apps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Firebase is not configured.')),
      );
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('If an account exists for that email, you will receive reset instructions.')),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Could not send reset email')),
      );
    }
  }

  Future<void> _sendOtp() async {
    final raw = _phoneController.text.trim().replaceAll(RegExp(r'\s+'), '');
    final digits = raw.replaceFirst(RegExp(r'^\+?91'), '').replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 10-digit mobile number')),
      );
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
          verificationCompleted: (PhoneAuthCredential credential) {},
          verificationFailed: (FirebaseAuthException e) {
            if (!completer.isCompleted) {
              completer.completeError(e);
            }
          },
          codeSent: (String verificationId, int? resendToken) {
            if (!completer.isCompleted) {
              completer.complete(verificationId);
            }
          },
          codeAutoRetrievalTimeout: (String verificationId) {},
          timeout: const Duration(seconds: 120),
        );
        final verificationId = await completer.future.timeout(
          const Duration(seconds: 90),
          onTimeout: () => throw TimeoutException('Firebase phone verification timed out'),
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
        debugPrint('Firebase SMS unavailable, using backend: $e');
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
      final message = e is ApiException ? e.message : 'Could not send OTP. Check your connection and try again.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(32, 60, 32, 40),
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Column(
                children: [
                  // Logo
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 20, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: const Icon(Icons.build_circle, size: 38, color: AppColors.primaryBlue),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Welcome to Click2Fix',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Click the problem. Fix it instantly.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),
            // Form
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Login or Register',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _loginMode == _LoginMode.phone
                        ? 'We\'ll send you a one-time verification code'
                        : 'Sign in with the email and password you used to register',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 28),
                  // Role toggle
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: _RoleTab(label: 'I need a fix', icon: Icons.home_repair_service, isActive: !_isWorker, onTap: () => setState(() => _isWorker = false))),
                        Expanded(child: _RoleTab(label: 'I\'m a worker', icon: Icons.engineering, isActive: _isWorker, onTap: () => setState(() => _isWorker = true))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SegmentedButton<_LoginMode>(
                    segments: const [
                      ButtonSegment(
                        value: _LoginMode.phone,
                        label: Text('Phone OTP'),
                        icon: Icon(Icons.phone_android, size: 18),
                      ),
                      ButtonSegment(
                        value: _LoginMode.email,
                        label: Text('Email'),
                        icon: Icon(Icons.email_outlined, size: 18),
                      ),
                    ],
                    selected: {_loginMode},
                    onSelectionChanged: (s) => setState(() => _loginMode = s.first),
                    multiSelectionEnabled: false,
                  ),
                  const SizedBox(height: 20),
                  if (_loginMode == _LoginMode.phone) ...[
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: Theme.of(context).textTheme.bodyLarge,
                      decoration: InputDecoration(
                        labelText: 'Mobile Number',
                        hintText: '9876543210',
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(left: 16, right: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('🇮🇳', style: TextStyle(fontSize: 20)),
                              SizedBox(width: 6),
                              Text('+91', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                      ),
                    ),
                    const SizedBox(height: 24),
                    PrimaryActionButton(
                      label: 'Send OTP',
                      icon: Icons.sms_outlined,
                      isLoading: _isLoading,
                      onPressed: _sendOtp,
                    ),
                  ] else ...[
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isLoading ? null : _showForgotPasswordDialog,
                        child: const Text('Forgot password?'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    PrimaryActionButton(
                      label: 'Sign in',
                      icon: Icons.login,
                      isLoading: _isLoading,
                      onPressed: _signInWithEmailPassword,
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'Or continue with',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textHint),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _signInWithGoogle,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: const Text(
                              'G',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF4285F4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text('Continue with Google'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Divider
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Demo Mode',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textHint),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Quick demo buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ref.read(sessionProvider.notifier).login(
                                  token: 'demo-user-token',
                                  role: UserRole.user,
                                  phone: '9876543210',
                                  name: 'Demo User',
                                );
                            context.go('/home');
                          },
                          icon: const Icon(Icons.person, size: 18),
                          label: const Text('Demo User'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ref.read(sessionProvider.notifier).login(
                                  token: 'demo-worker-token',
                                  role: UserRole.worker,
                                  phone: '9876543211',
                                  name: 'Demo Worker',
                                );
                            context.go('/worker/dashboard');
                          },
                          icon: const Icon(Icons.engineering, size: 18),
                          label: const Text('Demo Worker'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Register link
                  Center(
                    child: TextButton(
                      onPressed: () => context.go('/register'),
                      child: const Text('New user? Register here'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Footer
                  Center(
                    child: Text(
                      'By continuing, you agree to our Terms of Service\nand Privacy Policy',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textHint),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleTab extends StatelessWidget {
  const _RoleTab({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isActive ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
