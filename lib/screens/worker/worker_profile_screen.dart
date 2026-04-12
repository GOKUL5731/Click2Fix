import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_theme.dart';
import '../../providers/session_provider.dart';
import '../../widgets/star_rating.dart';
import '../../services/google_auth_service.dart';

class WorkerProfileScreen extends ConsumerWidget {
  const WorkerProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => context.go('/worker/dashboard')),
        title: const Text('My Profile'),
      ),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
        Container(width: 80, height: 80, decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(22)),
          child: Center(child: Text((session.name ?? 'W')[0], style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700)))),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(session.name ?? 'Worker', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(width: 8), const Icon(Icons.verified, color: AppColors.primaryBlue, size: 22),
        ]),
        const SizedBox(height: 4),
        Text('Expert Plumber • Member since 2024', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 12),
        const StarRating(rating: 4.8, size: 24), const SizedBox(height: 4),
        Text('4.8 (127 reviews)', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: _StatCard(label: 'Trust Score', value: '92', color: AppColors.primaryBlue)),
          const SizedBox(width: 10),
          Expanded(child: _StatCard(label: 'Jobs Done', value: '127', color: AppColors.successGreen)),
          const SizedBox(width: 10),
          Expanded(child: _StatCard(label: 'Total Earned', value: '₹24.7K', color: AppColors.trustGold)),
        ]),
        const SizedBox(height: 20),
        _InfoTile(icon: Icons.phone, label: 'Phone', value: '+91 ${session.phone ?? '9876543211'}', isDark: isDark),
        _InfoTile(icon: Icons.badge, label: 'Aadhaar', value: '•••• •••• 4589', isDark: isDark),
        _InfoTile(icon: Icons.build, label: 'Skills', value: 'Plumbing, Pipe Fitting', isDark: isDark),
        _InfoTile(icon: Icons.location_on, label: 'Service Area', value: 'Chennai — 10 km radius', isDark: isDark),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, child: OutlinedButton.icon(
          onPressed: () async { 
            await ref.read(googleAuthProvider).signOut();
            await ref.read(sessionProvider.notifier).logout(); 
            if (context.mounted) context.go('/login'); 
          },
          icon: const Icon(Icons.logout, color: AppColors.emergencyRed),
          label: const Text('Logout', style: TextStyle(color: AppColors.emergencyRed)),
          style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.emergencyRed), padding: const EdgeInsets.all(14)),
        )),
      ])),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.color});
  final String label; final String value; final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: color.withAlpha(15), borderRadius: BorderRadius.circular(14)),
    child: Column(children: [
      Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color, fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary)),
    ]),
  );
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.label, required this.value, required this.isDark});
  final IconData icon; final String label; final String value; final bool isDark;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: isDark ? AppColors.cardDark : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? Colors.white10 : AppColors.divider)),
    child: Row(children: [
      Icon(icon, size: 20, color: AppColors.primaryBlue), const SizedBox(width: 14),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary)),
        Text(value, style: Theme.of(context).textTheme.titleSmall),
      ]),
    ]),
  );
}
