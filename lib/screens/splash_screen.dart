import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_theme.dart';
import '../providers/session_provider.dart';
import '../services/device_token_sync.dart';

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

    if (session != null && session.isLoggedIn) {
      final client = ref.read(apiClientProvider);
      client.setToken(session.token);
      await syncFcmDeviceToken(client);
    }

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
      final info = await PackageInfo.fromPlatform();
      final currentVersion = info.version;

      String? rcLatest;
      String? rcUrl;
      var rcForce = false;
      if (Firebase.apps.isNotEmpty) {
        try {
          final rc = FirebaseRemoteConfig.instance;
          await rc.setConfigSettings(
            RemoteConfigSettings(
              fetchTimeout: const Duration(seconds: 12),
              minimumFetchInterval: const Duration(hours: 1),
            ),
          );
          await rc.setDefaults({
            'latest_app_version': currentVersion,
            'app_update_url': '',
            'force_update': false,
          });
          await rc.fetchAndActivate();
          rcLatest = rc.getString('latest_app_version');
          rcUrl = rc.getString('app_update_url');
          rcForce = rc.getBool('force_update');
        } catch (e) {
          debugPrint('Remote Config fetch skipped: $e');
        }
      }

      final client = ref.read(apiClientProvider);
      Map<String, dynamic> data;
      try {
        final response = await client.get('/api/app/version');
        data = Map<String, dynamic>.from(response.data as Map);
      } catch (_) {
        final response = await client.get('/api/app/');
        data = Map<String, dynamic>.from(response.data as Map);
      }

      if (!mounted) return;

      var latestVersion = data['latestVersion'] as String? ?? currentVersion;
      var updateUrl = (data['updateUrl'] as String?)?.trim() ?? '';
      var forceUpdate = data['forceUpdate'] as bool? ?? false;

      if (rcLatest != null && rcLatest.isNotEmpty && _compareSemver(rcLatest, latestVersion) > 0) {
        latestVersion = rcLatest;
      }
      if (rcUrl != null && rcUrl.trim().isNotEmpty) {
        updateUrl = rcUrl.trim();
      }
      forceUpdate = forceUpdate || rcForce;

      final needsUpdate =
          updateUrl.isNotEmpty && _compareSemver(latestVersion, currentVersion) > 0;

      if (needsUpdate) {
        await _showUpdateDialog(
          latestVersion: latestVersion,
          updateUrl: updateUrl,
          forceUpdate: forceUpdate,
        );
      }
    } catch (e) {
      debugPrint('Version check skipped: $e');
    }
  }

  /// Lexical semver-style compare (major.minor.patch+).
  int _compareSemver(String a, String b) {
    List<int> parts(String v) {
      final core = v.split('+').first.split('-').first;
      return core
          .split('.')
          .map((s) => int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
          .toList();
    }

    final pa = parts(a);
    final pb = parts(b);
    for (var i = 0; i < 4; i++) {
      final va = i < pa.length ? pa[i] : 0;
      final vb = i < pb.length ? pb[i] : 0;
      if (va != vb) return va.compareTo(vb);
    }
    return 0;
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
        title: const Text('Update available'),
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
            onPressed: () async {
              Navigator.of(ctx).pop();
              final uri = Uri.tryParse(updateUrl);
              if (uri != null && await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: const Text('Update now'),
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

