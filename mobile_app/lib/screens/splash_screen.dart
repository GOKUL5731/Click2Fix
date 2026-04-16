import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
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
  String _statusText = 'Connecting to server…';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Small delay for animation
    await Future.delayed(const Duration(milliseconds: 800));

    // 1. Check for app update
    await _checkVersion();

    // 2. Restore and verify session
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
            email: sessionData['email'] ?? sessionData['email'], // Backward compatibility
            name: sessionData['name'],
          );
      _navigate(ref.read(sessionProvider));
    } else {
      _navigate(const Session());
    }
  }

  Future<void> _checkVersion() async {
    if (!mounted) return;
    setState(() => _statusText = 'Checking for updates…');
    try {
      final client = ApiClient();
      final response = await client.get('/app/version');
      final data = response.data as Map<String, dynamic>?;
      if (data == null) return;

      final latestCode = data['latestVersionCode'] as int? ?? 0;
      final forceUpdate = data['forceUpdate'] as bool? ?? false;
      final updateUrl = data['updateUrl'] as String? ?? '';

      if (latestCode > AppConfig.appVersionCode && mounted) {
        await _showUpdateDialog(updateUrl, force: forceUpdate);
      }
      if (mounted) setState(() => _statusText = 'Loading…');
    } catch (_) {
      // Backend unreachable — proceed without update check
      if (mounted) setState(() => _statusText = 'Loading…');
    }
  }

  Future<void> _showUpdateDialog(String updateUrl, {bool force = false}) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: !force,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Available'),
        content: const Text(
            'A new version of Click2Fix is available. Update now for the best experience.'),
        actions: [
          if (!force)
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Later'),
            ),
          FilledButton(
            onPressed: () async {
              final uri = Uri.tryParse(updateUrl);
              if (uri != null && await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
  }

  void _navigate(Session session) {
    if (session.isLoggedIn) {
      if (session.isWorker) {
        context.go('/worker/dashboard');
      } else {
        context.go('/home');
      }
    } else {
      context.go('/onboarding');
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
              )
                  .animate()
                  .scale(begin: const Offset(0.5, 0.5), duration: 600.ms, curve: Curves.elasticOut)
                  .fadeIn(duration: 400.ms),
              const SizedBox(height: 28),
              Text(
                'Click2Fix',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
              ).animate().fadeIn(delay: 300.ms, duration: 500.ms).slideY(begin: 0.3),
              const SizedBox(height: 8),
              Text(
                AppConfig.tagline,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                      letterSpacing: 0.5,
                    ),
              ).animate().fadeIn(delay: 600.ms, duration: 500.ms),
              const SizedBox(height: 48),
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white54),
              ).animate().fadeIn(delay: 900.ms, duration: 500.ms),
              const SizedBox(height: 16),
              Text(
                _statusText,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.white54),
              ).animate().fadeIn(delay: 1000.ms),
            ],
          ),
        ),
      ),
    );
  }
}
