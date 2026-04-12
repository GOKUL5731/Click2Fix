import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/app_theme.dart';
import '../providers/session_provider.dart';
import '../services/api_client.dart';
import '../services/firebase_phone_auth_service.dart';
import '../widgets/primary_action_button.dart';

class RegisterProfileScreen extends ConsumerStatefulWidget {
  const RegisterProfileScreen({
    required this.phone,
    required this.isWorker,
    required this.firebaseToken,
    super.key,
  });

  final String phone;
  final bool isWorker;
  final String firebaseToken;

  @override
  ConsumerState<RegisterProfileScreen> createState() => _RegisterProfileScreenState();
}

class _RegisterProfileScreenState extends ConsumerState<RegisterProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  
  final _apiClient = ApiClient();
  late final _firebaseAuthService = FirebasePhoneAuthService(_apiClient);

  bool _isLoading = false;
  String? _selectedCategory;

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
    _emailController.dispose();
    _firebaseAuthService.dispose();
    super.dispose();
  }

  Future<void> _completeRegistration() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }

    if (widget.isWorker && _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your service category')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final role = widget.isWorker ? 'worker' : 'user';
      
      final backendResponse = await _firebaseAuthService.exchangeForBackendJwt(
        firebaseIdToken: widget.firebaseToken,
        role: role,
        phone: widget.phone,
        name: name,
        category: _selectedCategory?.toLowerCase().replaceAll(' ', '_'),
      ); // Email handles on backend next update or via Google SSO

      final token = backendResponse['token'] as String;
      final sessionRole = widget.isWorker ? UserRole.worker : UserRole.user;
      
      ref.read(sessionProvider.notifier).login(
        token: token,
        role: sessionRole,
        phone: widget.phone,
        name: name,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        context.go(widget.isWorker ? '/worker/dashboard' : '/home');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: $e'), backgroundColor: AppColors.emergencyRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        automaticallyImplyLeading: false, // Don't let them go back to OTP screen
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Just a few more details...',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Your phone number ${widget.phone} is verified!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 32),

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name *',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 20),

            // Worker-specific fields
            if (widget.isWorker) ...[
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Service Category *',
                  prefixIcon: Icon(Icons.build_circle_outlined),
                ),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val),
              ),
              const SizedBox(height: 20),
            ],

            const SizedBox(height: 32),
            PrimaryActionButton(
              label: 'Finish Registration',
              icon: Icons.check_circle_outline,
              isLoading: _isLoading,
              onPressed: _completeRegistration,
            ),
          ],
        ),
      ),
    );
  }
}
