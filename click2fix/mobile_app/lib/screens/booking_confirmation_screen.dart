import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/app_theme.dart';
import '../widgets/primary_action_button.dart';

class BookingConfirmationScreen extends StatelessWidget {
  const BookingConfirmationScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => context.go('/workers'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(color: AppColors.successGreen.withAlpha(20), borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.receipt_long, size: 36, color: AppColors.successGreen),
          ),
          const SizedBox(height: 16),
          Text('Confirm Booking', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text('Review your booking details', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 28),
          // Summary Card
          Container(
            width: double.infinity, padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: isDark ? AppColors.cardDark : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? Colors.white10 : AppColors.divider)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Booking Summary', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              _SumRow(label: 'Issue', value: 'Pipe Leakage'),
              const SizedBox(height: 10), _SumRow(label: 'Category', value: 'Plumbing'),
              const SizedBox(height: 10), _SumRow(label: 'Urgency', value: 'High'),
              const Divider(height: 28),
              _SumRow(label: 'Worker', value: 'Ravi Kumar ✓'),
              const SizedBox(height: 10), _SumRow(label: 'Rating', value: '4.8 ★'),
              const SizedBox(height: 10), _SumRow(label: 'ETA', value: '18 minutes'),
              const Divider(height: 28),
              _SumRow(label: 'Service Fee', value: '₹450'),
              const SizedBox(height: 10), _SumRow(label: 'Platform Fee', value: '₹45'),
              const SizedBox(height: 10),
              Row(children: [
                Text('Total', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                Text('₹495', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primaryBlue, fontWeight: FontWeight.w800)),
              ]),
            ]),
          ),
          const SizedBox(height: 16),
          // Location
          Container(
            width: double.infinity, padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: isDark ? AppColors.cardDark : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? Colors.white10 : AppColors.divider)),
            child: Row(children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.primaryBlue.withAlpha(15), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.location_on, color: AppColors.primaryBlue)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Service Location', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text('Chennai, Tamil Nadu • GPS confirmed', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
              ])),
            ]),
          ),
          const SizedBox(height: 28),
          PrimaryActionButton(label: 'Confirm & Book', icon: Icons.check_circle, onPressed: () => context.go('/tracking')),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => context.go('/workers'), child: const Text('Go Back'))),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}

class _SumRow extends StatelessWidget {
  const _SumRow({required this.label, required this.value});
  final String label; final String value;
  @override
  Widget build(BuildContext context) => Row(children: [
    Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
    const Spacer(), Text(value, style: Theme.of(context).textTheme.titleSmall),
  ]);
}
