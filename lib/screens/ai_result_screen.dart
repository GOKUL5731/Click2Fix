import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../config/app_theme.dart';
import '../widgets/confidence_ring.dart';
import '../widgets/urgency_badge.dart';
import '../widgets/primary_action_button.dart';

class AiResultScreen extends StatelessWidget {
  const AiResultScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => context.go('/upload')), title: const Text('AI Detection Result')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Center(child: const ConfidenceRing(confidence: 0.95, size: 140, strokeWidth: 12, label: 'Confidence')).animate().fadeIn(duration: 600.ms),
          const SizedBox(height: 28),
          Container(
            width: double.infinity, padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: isDark ? AppColors.cardDark : Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: isDark ? Colors.white10 : AppColors.divider)),
            child: Column(children: [
              Row(children: [
                Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.primaryBlue.withAlpha(15), borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.plumbing, size: 28, color: AppColors.primaryBlue)),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Plumbing', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text('Pipe leakage detected', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                ])),
                const UrgencyBadge(level: 'high', large: true),
              ]),
              const SizedBox(height: 20), const Divider(), const SizedBox(height: 16),
              _Row(icon: Icons.category, label: 'Category', value: 'Plumbing'),
              const SizedBox(height: 12), _Row(icon: Icons.speed, label: 'Confidence', value: '95%'),
              const SizedBox(height: 12), _Row(icon: Icons.priority_high, label: 'Urgency', value: 'High'),
              const SizedBox(height: 12), _Row(icon: Icons.access_time, label: 'Est. Time', value: '30–60 min'),
            ]),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05),
          const SizedBox(height: 20),
          Container(
            width: double.infinity, padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(gradient: AppColors.goldGradient, borderRadius: BorderRadius.circular(20)),
            child: Row(children: [
              const Icon(Icons.currency_rupee, size: 32, color: Colors.white),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Estimated Price', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white70)),
                const SizedBox(height: 4),
                Text('₹300 – ₹600', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
              ])),
            ]),
          ).animate().fadeIn(delay: 500.ms),
          const SizedBox(height: 20),
          Container(
            width: double.infinity, padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.primaryBlue.withAlpha(10), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.primaryBlue.withAlpha(30))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [const Icon(Icons.auto_awesome, size: 16, color: AppColors.primaryBlue), const SizedBox(width: 8),
                Text('AI Explanation', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.primaryBlue))]),
              const SizedBox(height: 8),
              Text('• Matched keywords: pipe, leak, water\n• Urgency elevated: water leak present\n• Model: heuristic-mvp-v1',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, height: 1.6)),
            ]),
          ),
          const SizedBox(height: 28),
          PrimaryActionButton(label: 'Find Nearby Workers', icon: Icons.search, onPressed: () => context.go('/workers')),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => context.go('/upload'), child: const Text('Upload Again'))),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, required this.value});
  final IconData icon; final String label; final String value;
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 18, color: AppColors.textSecondary), const SizedBox(width: 10),
    Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
    const Spacer(), Text(value, style: Theme.of(context).textTheme.titleSmall),
  ]);
}
