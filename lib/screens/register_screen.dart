import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/app_theme.dart';
import '../providers/session_provider.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/firebase_identity_sync.dart';
import '../widgets/primary_action_button.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isWorker = false;
  bool _isLoading = false;
  String? _selectedCategory;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  final _categories = [
    'Plumbing',
    'Electrical',
    'Carpentry',
    'Cleaning',
    'Painting',
    'Appliance Repair',
    'Gas Leakage',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _registerWithEmailPassword() async {
    if (Firebase.apps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Firebase is not configured. Add google-services.json and rebuild.')),
      );
      return;
    }
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final pass = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }
    if (!email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email')),
      );
      return;
    }
    if (pass.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 8 characters')),
      );
      return;
    }
    if (pass != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }
    if (_isWorker && _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your service category')),
      );
      return;
    }

    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: pass,
      );
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updateDisplayName(name);
        await user.reload();
      }
      if (!mounted) return;
      final digits =
          _phoneController.text.trim().replaceFirst(RegExp(r'^\+?91'), '').replaceAll(RegExp(r'\D'), '');
      await FirebaseIdentitySync.exchangeIdTokenForBackendJwt(
        ref: ref,
        role: _isWorker ? UserRole.worker : UserRole.user,
        explicitPhone: digits.length >= 10 ? digits : null,
        explicitName: name,
        category: _isWorker ? _selectedCategory?.toLowerCase().replaceAll(' ', '_') : null,
      );
      if (!mounted) return;
      setState(() => _isLoading = false);
      router.go(_isWorker ? '/worker/dashboard' : '/home');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      messenger.showSnackBar(SnackBar(content: Text(e.message ?? 'Registration failed')));
    } catch (e) {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      setState(() => _isLoading = false);
      final message = e is ApiException ? e.message : 'Could not complete registration. Try again.';
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    final digits =
        phone.replaceFirst(RegExp(r'^\+?91'), '').replaceAll(RegExp(r'\D'), '');
    if (name.isEmpty || digits.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name and a valid 10-digit phone number')),
      );
      return;
    }

    if (_isWorker && _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your service category')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final client = ref.read(apiClientProvider);
      final authService = AuthService(client);
      await authService.register(
        role: _isWorker ? 'worker' : 'user',
        phone: digits,
        name: name,
        email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
        category: _selectedCategory?.toLowerCase().replaceAll(' ', '_'),
      );

      if (mounted) {
        setState(() => _isLoading = false);
        context.go('/otp', extra: {'phone': digits, 'isWorker': _isWorker});
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        final message = e is ApiException
            ? e.message
            : 'Registration failed. Check your connection and try again.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.go('/login'),
        ),
        title: const Text('Create Account'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Role toggle
            Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _RoleTab(
                      label: 'I need repairs',
                      icon: Icons.home_repair_service,
                      isActive: !_isWorker,
                      onTap: () => setState(() => _isWorker = false),
                    ),
                  ),
                  Expanded(
                    child: _RoleTab(
                      label: 'I\'m a worker',
                      icon: Icons.engineering,
                      isActive: _isWorker,
                      onTap: () => setState(() => _isWorker = true),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Mobile Number',
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
            const SizedBox(height: 16),

            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'Required for email & password signup',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // Worker-specific fields
            if (_isWorker) ...[
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Service Category',
                  prefixIcon: Icon(Icons.build_circle_outlined),
                ),
                hint: const Text('Select category'),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.trustGold.withAlpha(15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.trustGold.withAlpha(40)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: AppColors.trustGold),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'After registration, you\'ll need to upload identity documents (Aadhaar, certificates). Your profile will be reviewed by our admin team before activation.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            const SizedBox(height: 8),
            PrimaryActionButton(
              label: 'Register & Send OTP',
              icon: Icons.app_registration,
              isLoading: _isLoading,
              onPressed: _register,
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'Or sign up with email',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textHint),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'At least 8 characters',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                labelText: 'Confirm password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
            ),
            const SizedBox(height: 16),
            PrimaryActionButton(
              label: 'Create account with email',
              icon: Icons.person_add_alt_1,
              isLoading: _isLoading,
              onPressed: _registerWithEmailPassword,
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Already have an account? Login'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleTab extends StatelessWidget {
  const _RoleTab({required this.label, required this.icon, required this.isActive, required this.onTap});
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
            Text(label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : AppColors.textSecondary,
                )),
          ],
        ),
      ),
    );
  }
}
