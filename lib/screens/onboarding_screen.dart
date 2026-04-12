import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../config/app_theme.dart';
import '../widgets/app_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  static const _pages = <({String title, String subtitle, IconData icon, Color color})>[
    (
      title: 'Click',
      subtitle: 'Snap a photo of your household problem — leaking pipe, broken fan, wall crack. Our AI instantly detects the issue.',
      icon: Icons.camera_alt_rounded,
      color: AppColors.primary,
    ),
    (
      title: 'Compare',
      subtitle: 'Get matched with verified nearby workers. Compare by price, rating, distance, arrival time, and trust score.',
      icon: Icons.compare_arrows_rounded,
      color: AppColors.accent,
    ),
    (
      title: 'Fix',
      subtitle: 'Book instantly, track live, chat with worker, pay securely, and rate the service. That simple!',
      icon: Icons.success,
      color: AppColors.success,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Skip', style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold)),
              ),
            ),
            // Pages
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon circle
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: page.color.withOpacity(0.1),
                          ),
                          child: Icon(page.icon, size: 64, color: page.color),
                        ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
                        const SizedBox(height: 40),
                        Text(
                          page.title,
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textDark),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 200.ms),
                        const SizedBox(height: 16),
                        Text(
                          page.subtitle,
                          style: const TextStyle(fontSize: 16, color: AppColors.textLight, height: 1.6),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 400.ms),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Dots indicator
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 28 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index ? AppColors.primary : AppColors.divider,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            // Button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                  icon: _currentPage == _pages.length - 1 ? const Icon(Icons.arrow_forward, color: Colors.white) : null,
                  onPressed: () {
                    if (_currentPage < _pages.length - 1) {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      context.go('/login');
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
