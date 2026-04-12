import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/app_theme.dart';
import '../providers/session_provider.dart';
import '../services/firebase_phone_auth_service.dart';
import '../widgets/primary_action_button.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({
    this.phone,
    this.isWorker = false,
    this.isLoginMode = true,
    this.verificationId,
    this.firebaseAuthService,
    super.key,
  });

  final String? phone;
  final bool isWorker;
  final bool isLoginMode;
  final String? verificationId;
  final FirebasePhoneAuthService? firebaseAuthService;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  int _resendSeconds = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    _canResend = false;
    _resendSeconds = 60;
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

    if (widget.firebaseAuthService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Auth service unavailable.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Verify OTP with Firebase
      final result = await widget.firebaseAuthService!.verifyOtp(_otp);

      if (!widget.isLoginMode) {
        // Must complete profile!
        if (!mounted) return;
        setState(() => _isLoading = false);
        context.go('/register-profile', extra: {
          'phone': result.phoneNumber ?? widget.phone,
          'isWorker': widget.isWorker,
          'firebaseToken': result.firebaseIdToken,
        });
        return;
      }

      // 2. Exchange Firebase ID token for Backend JWT (Login Mode)
      final role = widget.isWorker ? 'worker' : 'user';
      final backendResponse = await widget.firebaseAuthService!.exchangeForBackendJwt(
        firebaseIdToken: result.firebaseIdToken,
        role: role,
        phone: result.phoneNumber ?? widget.phone,
      );

      final token = backendResponse['token'] as String;
      final sessionRole = widget.isWorker ? UserRole.worker : UserRole.user;
      
      // 3. Save Session
      ref.read(sessionProvider.notifier).login(
        token: token,
        role: sessionRole,
        phone: result.phoneNumber ?? widget.phone,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);
      context.go(widget.isWorker ? '/worker/dashboard' : '/home');
      
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.emergencyRed,
        ),
      );
    }
  }

  Future<void> _resendOtp() async {
    if (widget.firebaseAuthService == null || widget.phone == null) return;
    
    _startResendTimer();
    
    await widget.firebaseAuthService!.sendOtp(
      widget.phone!,
      onCodeSent: (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OTP resent!')),
          );
        }
      },
      onAutoVerified: (_) {}, // Handled by LoginScreen usually
      onError: (msg) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: AppColors.emergencyRed),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () {
            widget.firebaseAuthService?.dispose();
            context.go('/login');
          },
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
              'Enter the 6-digit code sent via SMS to ${widget.phone ?? ''}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 36),
            // StreamBuilder for status
            if (widget.firebaseAuthService != null)
              StreamBuilder<String>(
                stream: widget.firebaseAuthService!.statusStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();
                  final msg = snapshot.data!;
                  final isError = msg.startsWith('Error:');
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Text(
                      msg,
                      style: TextStyle(
                        color: isError ? AppColors.emergencyRed : AppColors.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
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
