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
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';

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

  bool _isWorker = false;
  bool _isLoading = false;
  String? _selectedCategory;
  bool _obscurePassword = true;

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
    super.dispose();
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

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final digits = phone.replaceFirst(RegExp(r'^\+?91'), '').replaceAll(RegExp(r'\D'), '');
    final email = _emailController.text.trim();
    final pass = _passwordController.text;

    if (name.isEmpty || digits.length < 10) {
      _showError('Please enter your name and a valid 10-digit phone number');
      return;
    }
    if (_isWorker && _selectedCategory == null) {
      _showError('Please select your service category');
      return;
    }

    setState(() => _isLoading = true);
    
    // Fallback if password is provided, try Firebase Auth directly
    if (email.contains('@') && pass.length >= 6 && Firebase.apps.isNotEmpty) {
      try {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: pass);
        await FirebaseAuth.instance.currentUser?.updateDisplayName(name);
        await FirebaseIdentitySync.exchangeIdTokenForBackendJwt(
          ref: ref,
          role: _isWorker ? UserRole.worker : UserRole.user,
          explicitPhone: digits,
          explicitName: name,
          category: _isWorker ? _selectedCategory?.toLowerCase().replaceAll(' ', '_') : null,
        );
        if (!mounted) return;
        setState(() => _isLoading = false);
        context.go(_isWorker ? '/worker/dashboard' : '/home');
        return;
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showError(e is FirebaseAuthException ? (e.message ?? 'Registration failed') : 'Registration failed');
        return;
      }
    }

    // Default API auth
    try {
      final client = ref.read(apiClientProvider);
      final authService = AuthService(client);
      await authService.register(
        role: _isWorker ? 'worker' : 'user',
        phone: digits,
        name: name,
        email: email.isNotEmpty ? email : null,
        category: _isWorker ? _selectedCategory?.toLowerCase().replaceAll(' ', '_') : null,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);
      context.go('/otp', extra: {'phone': digits, 'isWorker': _isWorker});
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(e is ApiException ? e.message : 'Registration failed. Check connection.');
    }
  }

  Future<void> _signInWithGoogle() async {
    final router = GoRouter.of(context);
    setState(() => _isLoading = true);
    
    try {
      final googleAuthService = ref.read(googleAuthProvider);
      final credential = await googleAuthService.signInWithGoogle();
      
      if (credential == null || credential.user == null) {
        setState(() => _isLoading = false);
        return;
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
      _showError(e is ApiException ? e.message : 'Google sign-in failed: \${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            AppTextField(
              label: 'Full Name',
              hint: 'John Doe',
              controller: _nameController,
              prefixIcon: const Icon(Icons.person_outline),
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
            AppTextField(
              label: 'Email (Optional)',
              hint: 'you@example.com',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: const Icon(Icons.email_outlined),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Password (Optional)',
              hint: 'Set an account password',
              controller: _passwordController,
              obscureText: _obscurePassword,
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            
            if (_isWorker) ...[
              const SizedBox(height: 16),
              const Text(
                'Service Category',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                ),
                hint: const Text('Select category'),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val),
              ),
            ],
            
            const SizedBox(height: 32),
            AppButton(
              text: 'Register',
              onPressed: _register,
              isLoading: _isLoading,
            ),
            
            const SizedBox(height: 24),
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
                const Text('Already have an account?', style: TextStyle(color: AppColors.textLight)),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Login', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
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
