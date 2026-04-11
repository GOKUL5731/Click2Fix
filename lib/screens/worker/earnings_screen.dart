import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_theme.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => context.go('/worker/dashboard')),
        title: const Text('My Earnings'),
      ),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
        // Total earnings
        Container(
          width: double.infinity, padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(20)),
          child: Column(children: [
            Text('Total Earnings', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70)),
            const SizedBox(height: 8),
            Text('â‚¹24,750', style: Theme.of(context).textTheme.displayMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _EarnStat(label: 'This Week', value: 'â‚¹4,200')),
              Container(width: 1, height: 30, color: Colors.white24),
              Expanded(child: _EarnStat(label: 'This Month', value: 'â‚¹12,500')),
              Container(width: 1, height: 30, color: Colors.white24),
              Expanded(child: _EarnStat(label: 'Jobs Done', value: '127')),
            ]),
          ]),
        ),
        const SizedBox(height: 24),
        Row(children: [
          Text('Recent Transactions', style: Theme.of(context).textTheme.headlineSmall),
          const Spacer(),
          TextButton(onPressed: () {}, child: const Text('See All')),
        ]),
        const SizedBox(height: 8),
        ..._transactions.map((t) => Container(
          margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: isDark ? AppColors.cardDark : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? Colors.white10 : AppColors.divider)),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.successGreen.withAlpha(15), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.arrow_downward, color: AppColors.successGreen, size: 18)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.title, style: Theme.of(context).textTheme.titleSmall),
              Text(t.date, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
            ])),
            Text('+${t.amount}', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.successGreen, fontWeight: FontWeight.w700)),
          ]),
        )),
      ])),
    );
  }

  static final _transactions = [
    (title: 'Pipe Repair â€” Priya S.', date: '10 Apr 2026', amount: 'â‚¹450'),
    (title: 'Wiring Fix â€” Karthik R.', date: '09 Apr 2026', amount: 'â‚¹720'),
    (title: 'Tap Replacement â€” Arun M.', date: '08 Apr 2026', amount: 'â‚¹350'),
    (title: 'AC Service â€” Lakshmi J.', date: '06 Apr 2026', amount: 'â‚¹550'),
  ];
}

class _EarnStat extends StatelessWidget {
  const _EarnStat({required this.label, required this.value});
  final String label; final String value;
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
    const SizedBox(height: 2),
    Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
  ]);
}

