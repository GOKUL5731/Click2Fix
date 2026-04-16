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
  bool _isEmailMethod = true; // Set to true as default

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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Phone login temporarily unavailable. Please use Email or Google login.')),
    );
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email to reset password')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.forgotPassword(email);
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
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
      Map<String, dynamic> response;

      if (_isLoginMode) {
        response = await _authService.loginWithEmail(
          email: email, 
          password: password, 
          role: role,
        );
      } else {
        response = await _authService.register(
          email: email, 
          password: password, 
          role: role, 
          name: name,
        );
      }

      final token = response['token'] as String;
      final user = response['user'] as Map<String, dynamic>;
      final sessionRole = _isWorker ? UserRole.worker : UserRole.user;
            
      ref.read(sessionProvider.notifier).login(
        token: token, 
        role: sessionRole,
        name: user['name'],
        phone: user['phone'],
      );

      if (mounted) {
        setState(() => _isLoading = false);
        context.go(_isWorker ? '/worker/dashboard' : '/home');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()), 
            backgroundColor: AppColors.emergencyRed,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _submitEmail,
            ),
          ),
        );
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final role = _isWorker ? 'worker' : 'user';
      
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: '926338625536-gbuohg1dtq81n42fnmhefqc5qno94n62.apps.googleusercontent.com',
        scopes: ['email', 'profile'],
      );
      
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = userCredential.user;
      
      if (user == null) throw Exception('Google sign-in failed: No user found');

      final String? idToken = await user.getIdToken(true);
      if (idToken == null) throw Exception('Failed to get ID token');

      final response = await _authService.loginWithGoogle(
        firebaseIdToken: idToken,
        role: role,
        email: user.email ?? googleUser.email,
        name: user.displayName ?? googleUser.displayName,
        photoUrl: user.photoURL,
        firebaseUid: user.uid,
      );
      
      final token = response['token'] as String;
      final userData = response['user'] as Map<String, dynamic>;
      final sessionRole = _isWorker ? UserRole.worker : UserRole.user;
            
      ref.read(sessionProvider.notifier).login(
        token: token,
        role: sessionRole,
        name: userData['name'],
        email: userData['email'],
      );

      if (mounted) {
        setState(() => _isLoading = false);
        context.go(_isWorker ? '/worker/dashboard' : '/home');
      }
    } catch (e) {
      // Ignore if user cancelled
      if (e.toString().contains('cancelled') || e.toString().contains('canceled')) {
        setState(() => _isLoading = false);
        return;
      }
      
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()), 
            backgroundColor: AppColors.emergencyRed,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _signInWithGoogle,
            ),
          ),
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
                    _isEmailMethod ? 'Secure login using email' : 'Phone login temporarily unavailable',
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
                    if (_isLoginMode)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _forgotPassword,
                          child: const Text('Forgot Password?'),
                        ),
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
