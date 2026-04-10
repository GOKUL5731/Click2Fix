import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/app_theme.dart';
import '../providers/session_provider.dart';
import '../widgets/gradient_header.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: SingleChildScrollView(child: Column(children: [
        GradientHeader(
          title: session.name ?? 'User',
          subtitle: '+91 ${session.phone ?? '9876543210'}',
          leading: Container(width: 52, height: 52, decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(16)),
            child: Center(child: Text((session.name ?? 'U')[0], style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)))),
          trailing: IconButton(onPressed: () {}, icon: const Icon(Icons.edit, color: Colors.white, size: 20)),
        ),
        Padding(padding: const EdgeInsets.all(20), child: Column(children: [
          _ProfileTile(icon: Icons.person, label: 'Full Name', value: session.name ?? 'Demo User'),
          _ProfileTile(icon: Icons.phone, label: 'Phone', value: '+91 ${session.phone ?? '9876543210'}'),
          _ProfileTile(icon: Icons.email, label: 'Email', value: 'user@click2fix.com'),
          _ProfileTile(icon: Icons.location_on, label: 'Default Address', value: 'Chennai, Tamil Nadu'),
          const SizedBox(height: 20),
          _MenuTile(icon: Icons.history, label: 'Booking History', onTap: () => context.go('/history')),
          _MenuTile(icon: Icons.notifications, label: 'Notifications', onTap: () => context.go('/notifications')),
          _MenuTile(icon: Icons.settings, label: 'Settings', onTap: () => context.go('/settings')),
          _MenuTile(icon: Icons.help_outline, label: 'Help & Support', onTap: () {}),
          const SizedBox(height: 16),
          _MenuTile(icon: Icons.logout, label: 'Logout', color: AppColors.emergencyRed, onTap: () {
            ref.read(sessionProvider.notifier).logout();
            context.go('/login');
          }),
        ])),
      ])),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({required this.icon, required this.label, required this.value});
  final IconData icon; final String label; final String value;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: isDark ? AppColors.cardDark : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? Colors.white10 : AppColors.divider)),
      child: Row(children: [
        Icon(icon, size: 20, color: AppColors.primaryBlue),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(value, style: Theme.of(context).textTheme.titleSmall),
        ]),
      ]),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.icon, required this.label, required this.onTap, this.color});
  final IconData icon; final String label; final VoidCallback onTap; final Color? color;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: isDark ? AppColors.cardDark : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? Colors.white10 : AppColors.divider)),
        child: Row(children: [
          Icon(icon, size: 20, color: color ?? AppColors.textSecondary),
          const SizedBox(width: 14),
          Text(label, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: color)),
          const Spacer(),
          Icon(Icons.chevron_right, size: 20, color: AppColors.textHint),
        ]),
      ),
    );
  }
}
