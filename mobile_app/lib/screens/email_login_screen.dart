import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/app_theme.dart';
import '../providers/session_provider.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/firebase_phone_auth_service.dart';
import '../widgets/primary_action_button.dart';

class EmailLoginScreen extends ConsumerStatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  ConsumerState<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends ConsumerState<EmailLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController(); // For registration

  final _apiClient = ApiClient();
  late final _authService = AuthService(_apiClient);
  late final _firebaseAuthService = FirebasePhoneAuthService(_apiClient);
  
  bool _isWorker = false;
  bool _isLoading = false;
  bool _isLoginMode = true; // true = Login, false = Register

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _firebaseAuthService.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a valid email and 6+ char password')),
      );
      return;
    }

    if (!_isLoginMode && name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide your name to register')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check if user exists to guide them correctly
      final checkRes = await _authService.checkUser(email: email);
      final exists = checkRes['exists'] == true;

      // Validate states before calling heavy Firebase actions
      if (_isLoginMode && !exists) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account not found. Please register first.')),
        );
        return;
      } else if (!_isLoginMode && exists) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account already exists. Please login.')),
        );
        return;
      }

      final role = _isWorker ? 'worker' : 'user';
      Map<String, dynamic> backendResponse;

      if (_isLoginMode) {
        backendResponse = await _firebaseAuthService.signInWithEmail(
          email: email,
          password: password,
          role: role,
        );
      } else {
        backendResponse = await _firebaseAuthService.registerWithEmail(
          email: email,
          password: password,
          role: role,
          name: name,
        );
      }

      final token = backendResponse['token'] as String;
      final sessionRole = _isWorker ? UserRole.worker : UserRole.user;
            
      ref.read(sessionProvider.notifier).login(
        token: token,
        role: sessionRole,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        context.go(_isWorker ? '/worker/dashboard' : '/home');
      }

    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Authentication failed: $e'), backgroundColor: AppColors.emergencyRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Email Login'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isLoginMode ? 'Welcome back' : 'Create an Account',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in securely with email & password',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 30),
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

            if (!_isLoginMode) ...[
               TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 20),
            ],

            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 10),
            
            // Register / Login Switcher
            Center(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _isLoginMode = !_isLoginMode;
                  });
                },
                child: Text(
                  _isLoginMode 
                      ? 'New user? Register here' 
                      : 'Already have an account? Login',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            PrimaryActionButton(
              label: _isLoginMode ? 'Login' : 'Register',
              icon: _isLoginMode ? Icons.login : Icons.person_add,
              isLoading: _isLoading,
              onPressed: _submit,
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
