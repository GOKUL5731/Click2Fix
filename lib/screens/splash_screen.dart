import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/app_theme.dart';
import '../providers/session_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Start auto-login check after animation has started
    Future.delayed(const Duration(milliseconds: 1800), _initApp);
  }

  Future<void> _initApp() async {
    if (!mounted) return;

    // 1. Try restoring saved session
    final session = await ref.read(sessionProvider.notifier).restoreAndReturn();

    if (!mounted) return;

    // 2. Check for in-app updates (non-blocking)
    await _checkForUpdate();

    if (!mounted) return;

    // 3. Route based on session
    if (session != null && session.isLoggedIn) {
      if (session.isWorker) {
        context.go('/worker/dashboard');
      } else {
        context.go('/home');
      }
    } else {
      context.go('/onboarding');
    }
  }

  Future<void> _checkForUpdate() async {
    try {
      const currentVersion = '0.1.0';
      final client = ref.read(apiClientProvider);
      final response = await client.get('/api/app/version');
      final data = response.data as Map<String, dynamic>;
      final latestVersion = data['latestVersion'] as String? ?? currentVersion;
      final forceUpdate = data['forceUpdate'] as bool? ?? false;
      final updateUrl = data['updateUrl'] as String? ?? '';

      if (!mounted) return;

      if (latestVersion != currentVersion && updateUrl.isNotEmpty) {
        await _showUpdateDialog(
          latestVersion: latestVersion,
          updateUrl: updateUrl,
          forceUpdate: forceUpdate,
        );
      }
    } catch (_) {
      // Version check failure is non-critical â€” ignore silently
    }
  }

  Future<void> _showUpdateDialog({
    required String latestVersion,
    required String updateUrl,
    required bool forceUpdate,
  }) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: !forceUpdate,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Update Available ðŸš€'),
        content: Text(
          'A new version ($latestVersion) of Click2Fix is available with bug fixes and improvements.',
        ),
        actions: [
          if (!forceUpdate)
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Later'),
            ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // TODO: Open updateUrl using url_launcher or webview
              debugPrint('Update URL: $updateUrl');
            },
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
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
              // Logo icon
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
              // App name
              Text(
                'Click2Fix',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
              ).animate().fadeIn(delay: 300.ms, duration: 500.ms).slideY(begin: 0.3),
              const SizedBox(height: 8),
              // Tagline
              Text(
                'Click the problem. Fix it instantly.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                      letterSpacing: 0.5,
                    ),
              ).animate().fadeIn(delay: 600.ms, duration: 500.ms),
              const SizedBox(height: 48),
              // Loading indicator
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.white54,
                ),
              ).animate().fadeIn(delay: 900.ms, duration: 500.ms),
            ],
          ),
        ),
      ),
    );
  }
}

