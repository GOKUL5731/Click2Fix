import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/app_theme.dart';
import '../providers/session_provider.dart';
import '../widgets/category_chip.dart';
import '../widgets/gradient_header.dart';

class HomeDashboardScreen extends ConsumerStatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  ConsumerState<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends ConsumerState<HomeDashboardScreen> {
  DateTime? _lastBackPressTime;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastBackPressTime == null ||
            now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header ─────────────────────────────────
            GradientHeader(
              title: 'Hi, ${session.name ?? 'there'}! 👋',
              subtitle: 'What needs fixing today?',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _HeaderIconBtn(icon: Icons.notifications_outlined, onTap: () => context.go('/notifications')),
                  const SizedBox(width: 8),
                  _HeaderIconBtn(icon: Icons.person_outline, onTap: () => context.go('/profile')),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(20),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, size: 18, color: Colors.white70),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Chennai, Tamil Nadu — GPS location enabled',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                      ),
                    ),
                    const Icon(Icons.my_location, size: 16, color: Colors.white70),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ─── Camera Hero Button ─────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () => context.go('/upload'),
                child: Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withAlpha(60),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Background pattern
                      Positioned(
                        right: -20,
                        bottom: -20,
                        child: Icon(Icons.camera_alt_rounded, size: 140, color: Colors.white.withAlpha(15)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(30),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.camera_alt_rounded, size: 28, color: Colors.white),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Snap Your Problem',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Take a photo and our AI will detect the issue',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
              ),
            ),
            const SizedBox(height: 16),

            // ─── Quick Actions ──────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(child: _QuickAction(icon: Icons.add_a_photo_outlined, label: 'Upload Issue', onTap: () => context.go('/upload'))),
                  const SizedBox(width: 10),
                  Expanded(child: _QuickAction(icon: Icons.history, label: 'My Issues', onTap: () => context.go('/history'))),
                  const SizedBox(width: 10),
                  Expanded(child: _QuickAction(icon: Icons.compare_arrows, label: 'Compare', onTap: () => context.go('/workers'))),
                  const SizedBox(width: 10),
                  Expanded(child: _QuickAction(icon: Icons.settings_outlined, label: 'Settings', onTap: () => context.go('/settings'))),
                ],
              ),
            ).animate().fadeIn(delay: 350.ms),
            const SizedBox(height: 28),

            // ─── Emergency Button ───────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () => context.go('/emergency'),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: AppColors.emergencyGradient,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(color: AppColors.emergencyRed.withAlpha(40), blurRadius: 16, offset: const Offset(0, 6)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Emergency Fix',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Gas leak • Electrical short • Water burst',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 500.ms),
            ),
            const SizedBox(height: 28),

            // ─── Service Categories ─────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Services', style: Theme.of(context).textTheme.headlineSmall),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: ServiceCategories.categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final cat = ServiceCategories.categories[index];
                  return CategoryChip(
                    label: cat.label,
                    icon: cat.icon,
                    onTap: () => context.go('/upload'),
                  );
                },
              ),
            ).animate().fadeIn(delay: 650.ms),
            const SizedBox(height: 28),

            // ─── Active Booking Card ────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Recent Activity', style: Theme.of(context).textTheme.headlineSmall),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.white10 : AppColors.divider),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.successGreen.withAlpha(20),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.check_circle_outline, color: AppColors.successGreen),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('No active bookings', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text(
                            'Take a photo to get started!',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/history'),
                      child: const Text('History'),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 800.ms),
            const SizedBox(height: 40),
          ],
        ),
      ),
    ));
  }
}

class _HeaderIconBtn extends StatelessWidget {
  const _HeaderIconBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? Colors.white10 : AppColors.divider),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: AppColors.primaryBlue),
            const SizedBox(height: 6),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}
