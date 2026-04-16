import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_theme.dart';
import '../providers/session_provider.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  String _statusText = 'Click2Fix';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Small delay for animation
    await Future.delayed(const Duration(milliseconds: 1200));

    // Restore and verify session
    setState(() => _statusText = 'Verifying session…');
    final authService = AuthService(ApiClient());
    final sessionData = await authService.restoreSession();

    if (!mounted) return;

    if (sessionData != null) {
      final roleStr = sessionData['role'];
      UserRole role = UserRole.none;
      if (roleStr == 'user') role = UserRole.user;
      if (roleStr == 'worker') role = UserRole.worker;

      ref.read(sessionProvider.notifier).login(
            token: sessionData['token']!,
            role: role,
            phone: sessionData['phone'],
            email: sessionData['email'],
            name: sessionData['name'],
          );
      _navigate(ref.read(sessionProvider));
    } else {
      _navigate(const Session());
    }
  }

  void _navigate(Session session) {
    if (session.isLoggedIn) {
      if (session.isWorker) {
        context.go('/worker/dashboard');
      } else {
        context.go('/home');
      }
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(40),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(Icons.build_circle, size: 52, color: AppColors.primaryBlue),
              ).animate().scale(begin: const Offset(0.5, 0.5), duration: 600.ms, curve: Curves.elasticOut).fadeIn(duration: 400.ms),
              const SizedBox(height: 28),
              Text(
                'Click2Fix',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
              ).animate().fadeIn(delay: 300.ms, duration: 500.ms).slideY(begin: 0.3),
              const SizedBox(height: 48),
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white54),
              ).animate().fadeIn(delay: 900.ms, duration: 500.ms),
              const SizedBox(height: 16),
              Text(
                _statusText,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white54),
              ).animate().fadeIn(delay: 1000.ms),
            ],
          ),
        ),
      ),
    );
  }
}
