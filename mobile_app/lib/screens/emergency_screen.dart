import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/app_theme.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => context.go('/home')),
        title: const Text('Emergency Fix'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          const SizedBox(height: 20),
          // Big emergency button
          GestureDetector(
            onTap: () {
              // Navigate to upload screen — the emergency toggle will be pre-set
              context.go('/upload');
            },
            child: Container(
              width: 180, height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle, gradient: AppColors.emergencyGradient,
                boxShadow: [BoxShadow(color: AppColors.emergencyRed.withAlpha(80), blurRadius: 40, spreadRadius: 4)],
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.warning_amber_rounded, size: 48, color: Colors.white),
                const SizedBox(height: 8),
                Text('SOS', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
                Text('Tap for help', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
              ]),
            ),
          ),
          const SizedBox(height: 32),
          Text('Emergency Services', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text('For critical issues that need immediate attention', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          _EmergencyType(icon: Icons.local_fire_department, label: 'Gas Leak', desc: 'Dangerous gas leakage detected', color: AppColors.emergencyRed),
          const SizedBox(height: 10),
          _EmergencyType(icon: Icons.flash_on, label: 'Electrical Short', desc: 'Fire hazard - electrical issues', color: const Color(0xFFE65100)),
          const SizedBox(height: 10),
          _EmergencyType(icon: Icons.water_damage, label: 'Water Burst', desc: 'Major pipe burst or flooding', color: AppColors.primaryBlue),
          const SizedBox(height: 10),
          _EmergencyType(icon: Icons.lock_open, label: 'Lockout', desc: 'Locked out of your home', color: AppColors.trustGold),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.emergencyRed.withAlpha(10), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.emergencyRed.withAlpha(30))),
            child: Row(children: [
              const Icon(Icons.info_outline, size: 18, color: AppColors.emergencyRed),
              const SizedBox(width: 10),
              Expanded(child: Text('Emergency requests are prioritized and sent to all nearby workers immediately.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary))),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _EmergencyType extends StatelessWidget {
  const _EmergencyType({required this.icon, required this.label, required this.desc, required this.color});
  final IconData icon; final String label; final String desc; final Color color;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: isDark ? AppColors.cardDark : Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: isDark ? Colors.white10 : AppColors.divider)),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withAlpha(15), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 24)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: Theme.of(context).textTheme.titleSmall),
          Text(desc, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
        ])),
        Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
      ]),
    );
  }
}
