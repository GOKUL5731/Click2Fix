import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/app_theme.dart';
import '../providers/session_provider.dart';
import '../services/auth_service.dart';
import '../widgets/primary_action_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  bool _isWorker = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid phone number')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final role = _isWorker ? 'worker' : 'user';
      final client = ref.read(apiClientProvider);
      final authService = AuthService(client);
      await authService.loginWithPhone(phone, role: role);
      if (mounted) {
        setState(() => _isLoading = false);
        context.go('/otp', extra: {'phone': phone, 'isWorker': _isWorker});
      }
    } catch (e) {
      // Fallback: proceed to OTP screen even if API is unavailable (dev mode)
      if (mounted) {
        setState(() => _isLoading = false);
        context.go('/otp', extra: {'phone': phone, 'isWorker': _isWorker});
      }
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
                    'We\'ll send you a one-time verification code',
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
                  const SizedBox(height: 24),
                  // Phone field
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
                  const SizedBox(height: 28),
                  // Send OTP button
                  PrimaryActionButton(
                    label: 'Send OTP',
                    icon: Icons.sms_outlined,
                    isLoading: _isLoading,
                    onPressed: _sendOtp,
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
