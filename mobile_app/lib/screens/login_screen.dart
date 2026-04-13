import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/app_theme.dart';
import '../providers/session_provider.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/firebase_phone_auth_service.dart';
import '../widgets/primary_action_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  final _apiClient = ApiClient();
  late final _authService = AuthService(_apiClient);
  late final _firebaseAuthService = FirebasePhoneAuthService(_apiClient);
  
  bool _isWorker = false;
  bool _isLoading = false;
  bool _isLoginMode = true; // true = Login, false = Register
  bool _isEmailMethod = false; // Toggle between Phone and Email

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _firebaseAuthService.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 10-digit phone number')),
      );
      return;
    }
    
    final countryCode = phone.startsWith('+') ? '' : '+91';
    final fullPhone = '$countryCode$phone';

    setState(() => _isLoading = true);

    try {
      // Pre-check user existence to guide them properly
      final checkRes = await _authService.checkUser(phone: fullPhone);
      final exists = checkRes['exists'] == true;

      // Prevent sending OTP if they are on the wrong flow to save SMS costs
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

      await _firebaseAuthService.sendOtp(
        fullPhone,
        onCodeSent: (verificationId) {
          if (mounted) {
            setState(() => _isLoading = false);
            context.go('/otp', extra: {
              'phone': fullPhone,
              'isWorker': _isWorker,
              'isLoginMode': _isLoginMode,
              'verificationId': verificationId,
              'firebaseAuthService': _firebaseAuthService,
            });
          }
        },
        onAutoVerified: (credential) async {
          try {
            final result = await _firebaseAuthService.signInWithCredential(credential);
            
            if (!_isLoginMode) {
              // Registration: redirect to complete profile
              if (mounted) {
                setState(() => _isLoading = false);
                context.go('/register-profile', extra: {
                  'phone': result.phoneNumber ?? fullPhone,
                  'isWorker': _isWorker,
                  'firebaseToken': result.firebaseIdToken,
                });
              }
              return;
            }

            // Login: exchange token directly
            final role = _isWorker ? 'worker' : 'user';
            final backendResponse = await _firebaseAuthService.exchangeForBackendJwt(
              firebaseIdToken: result.firebaseIdToken,
              role: role,
              phone: result.phoneNumber,
            );
            
            final token = backendResponse['token'] as String;
            final sessionRole = _isWorker ? UserRole.worker : UserRole.user;
            
            ref.read(sessionProvider.notifier).login(
              token: token,
              role: sessionRole,
              phone: result.phoneNumber,
            );

            if (mounted) {
              setState(() => _isLoading = false);
              context.go(_isWorker ? '/worker/dashboard' : '/home');
            }
          } catch (e) {
            if (mounted) {
              setState(() => _isLoading = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Verification failed: $e')),
              );
            }
          }
        },
        onError: (msg) {
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(msg), backgroundColor: AppColors.emergencyRed),
            );
          }
        },
      );
    } catch (e) {
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Network error. Check your connection.')),
        );
      }
    }
  }

  Future<void> _submitEmail() async {
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
      final role = _isWorker ? 'worker' : 'user';
      Map<String, dynamic> backendResponse;

      if (_isLoginMode) {
        backendResponse = await _firebaseAuthService.signInWithEmail(
          email: email, password: password, role: role,
        );
      } else {
        backendResponse = await _firebaseAuthService.registerWithEmail(
          email: email, password: password, role: role, name: name,
        );
      }

      final token = backendResponse['token'] as String;
      final sessionRole = _isWorker ? UserRole.worker : UserRole.user;
            
      ref.read(sessionProvider.notifier).login(token: token, role: sessionRole);

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

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final role = _isWorker ? 'worker' : 'user';
      final response = await _firebaseAuthService.signInWithGoogle(role: role);
      
      final token = response['token'] as String;
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
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.emergencyRed),
        );
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
            const SizedBox(height: 30),
            // Form
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isLoginMode ? 'Login to continue' : 'Register a new account',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We\'ll send you a secure OTP via SMS',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),
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
                  const SizedBox(height: 10),
                  
                  // Authentication Method Switcher
                  Center(
                    child: TextButton(
                      onPressed: () => setState(() => _isEmailMethod = !_isEmailMethod),
                      child: Text(
                        _isEmailMethod ? 'Use Phone Number instead' : 'Use Email & Password instead',
                        style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primaryBlue),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (!_isEmailMethod) ...[
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
                  ] else ...[
                    if (!_isLoginMode) ...[
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined)),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
                    ),
                  ],
                  
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
                  
                  const SizedBox(height: 10),
                  
                  // Submit button
                  PrimaryActionButton(
                    label: _isLoginMode ? 'Login' : 'Register',
                    icon: _isEmailMethod ? Icons.email_outlined : Icons.sms_outlined,
                    isLoading: _isLoading,
                    onPressed: _isEmailMethod ? _submitEmail : _sendOtp,
                  ),
                  
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textHint),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  PrimaryActionButton(
                    label: 'Continue with Google',
                    icon: Icons.g_mobiledata,
                    isLoading: _isLoading,
                    onPressed: _signInWithGoogle,
                  ),
                  
                  const SizedBox(height: 40),
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
