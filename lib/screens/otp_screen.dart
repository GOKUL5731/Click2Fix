import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/app_theme.dart';
import '../providers/session_provider.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../widgets/primary_action_button.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({this.phone, this.isWorker = false, super.key});

  final String? phone;
  final bool isWorker;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final _apiClient = ApiClient();
  late final _authService = AuthService(_apiClient);
  bool _isLoading = false;
  int _resendSeconds = 30;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
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

    setState(() => _isLoading = true);
    final role = widget.isWorker ? 'worker' : 'user';

    try {
      // Try real API verification
      final token = await _authService.verifyOtp(
        widget.phone ?? '',
        _otp,
        role: role,
      );

      final sessionRole = widget.isWorker ? UserRole.worker : UserRole.user;
      await _authService.saveSession(
        token: token,
        role: role,
        phone: widget.phone,
      );
      ref.read(sessionProvider.notifier).login(
            token: token,
            role: sessionRole,
            phone: widget.phone,
          );

      if (!mounted) return;
      setState(() => _isLoading = false);
      context.go(widget.isWorker ? '/worker/dashboard' : '/home');
    } catch (e) {
      // Fallback to dev mode OTP (123456)
      if (!mounted) return;
      if (_otp == '123456') {
        final sessionRole = widget.isWorker ? UserRole.worker : UserRole.user;
        ref.read(sessionProvider.notifier).login(
              token: 'dev-token-${DateTime.now().millisecondsSinceEpoch}',
              role: sessionRole,
              phone: widget.phone,
              name: widget.isWorker ? 'Worker' : 'User',
            );
        setState(() => _isLoading = false);
        context.go(widget.isWorker ? '/worker/dashboard' : '/home');
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid OTP. Use 123456 for demo.'),
            backgroundColor: AppColors.emergencyRed,
          ),
        );
      }
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
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.trustGold.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Demo OTP: 123456',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.trustGold,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
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
                      onPressed: () {
                        _startResendTimer();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('OTP resent!')),
                        );
                      },
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
