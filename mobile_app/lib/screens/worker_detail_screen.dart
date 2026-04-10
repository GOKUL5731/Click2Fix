import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/app_theme.dart';
import '../widgets/star_rating.dart';
import '../widgets/primary_action_button.dart';

class WorkerDetailScreen extends StatelessWidget {
  const WorkerDetailScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => context.go('/workers'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          // Avatar
          Container(width: 90, height: 90, decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(24)),
            child: const Center(child: Text('R', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w700)))),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('Ravi Kumar', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(width: 8),
            const Icon(Icons.verified, color: AppColors.primaryBlue, size: 22),
          ]),
          const SizedBox(height: 4),
          Text('Expert Plumber • 8 years experience', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          const StarRating(rating: 4.8, size: 28),
          const SizedBox(height: 4),
          Text('4.8 (127 reviews)', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 28),
          // Stats
          Row(children: [
            Expanded(child: _StatBox(label: 'Trust Score', value: '92', color: AppColors.primaryBlue)),
            const SizedBox(width: 10),
            Expanded(child: _StatBox(label: 'Distance', value: '2.4 km', color: AppColors.successGreen)),
            const SizedBox(width: 10),
            Expanded(child: _StatBox(label: 'Arrival', value: '18 min', color: AppColors.trustGold)),
          ]),
          const SizedBox(height: 20),
          // Quote
          Container(
            width: double.infinity, padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: isDark ? AppColors.cardDark : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? Colors.white10 : AppColors.divider)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Quotation', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              _DetailRow(label: 'Price', value: '₹450'),
              const SizedBox(height: 8), _DetailRow(label: 'Arrival Time', value: '18 minutes'),
              const SizedBox(height: 8), _DetailRow(label: 'Message', value: '"I can fix this pipe leak in 30-45 minutes."'),
            ]),
          ),
          const SizedBox(height: 20),
          // Reviews
          Container(
            width: double.infinity, padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: isDark ? AppColors.cardDark : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? Colors.white10 : AppColors.divider)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Recent Reviews', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 14),
              _ReviewItem(name: 'Priya S.', rating: 5, comment: 'Excellent work! Fixed my pipe in 20 minutes.'),
              const Divider(height: 20),
              _ReviewItem(name: 'Karthik R.', rating: 4, comment: 'Good service, was slightly late.'),
            ]),
          ),
          const SizedBox(height: 28),
          PrimaryActionButton(label: 'Book This Worker', icon: Icons.check_circle, onPressed: () => context.go('/booking-confirmation')),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value, required this.color});
  final String label; final String value; final Color color;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withAlpha(15), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withAlpha(40))),
      child: Column(children: [
        Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: color, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: isDark ? Colors.white60 : AppColors.textSecondary)),
      ]),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label; final String value;
  @override
  Widget build(BuildContext context) => Row(children: [
    Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
    const Spacer(), Flexible(child: Text(value, style: Theme.of(context).textTheme.titleSmall, textAlign: TextAlign.end)),
  ]);
}

class _ReviewItem extends StatelessWidget {
  const _ReviewItem({required this.name, required this.rating, required this.comment});
  final String name; final int rating; final String comment;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      CircleAvatar(radius: 16, backgroundColor: AppColors.primaryBlue.withAlpha(30), child: Text(name[0], style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w600, fontSize: 14))),
      const SizedBox(width: 10),
      Text(name, style: Theme.of(context).textTheme.titleSmall),
      const Spacer(),
      StarRating(rating: rating.toDouble(), size: 14),
    ]),
    const SizedBox(height: 8),
    Text(comment, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
  ]);
}
