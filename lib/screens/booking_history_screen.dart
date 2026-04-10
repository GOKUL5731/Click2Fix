import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/app_theme.dart';

class BookingHistoryScreen extends StatelessWidget {
  const BookingHistoryScreen({super.key});

  static const _bookings = [
    (id: 'BK-1024', issue: 'Pipe Leakage', worker: 'Ravi Kumar', date: '10 Apr 2026', amount: '₹495', status: 'Completed'),
    (id: 'BK-1023', issue: 'Wiring Short Circuit', worker: 'Anil Raj', date: '08 Apr 2026', amount: '₹720', status: 'Completed'),
    (id: 'BK-1022', issue: 'AC Not Cooling', worker: 'Suresh M', date: '02 Apr 2026', amount: '₹550', status: 'Completed'),
    (id: 'BK-1021', issue: 'Door Lock Broken', worker: 'Kumar S', date: '28 Mar 2026', amount: '₹350', status: 'Cancelled'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => context.go('/home')),
        title: const Text('Booking History'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16), itemCount: _bookings.length,
        itemBuilder: (context, index) {
          final b = _bookings[index];
          final isCancelled = b.status == 'Cancelled';
          return Container(
            margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: isDark ? AppColors.cardDark : Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: isDark ? Colors.white10 : AppColors.divider)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: (isCancelled ? AppColors.emergencyRed : AppColors.successGreen).withAlpha(15), borderRadius: BorderRadius.circular(12)),
                  child: Icon(isCancelled ? Icons.cancel : Icons.check_circle, color: isCancelled ? AppColors.emergencyRed : AppColors.successGreen, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(b.issue, style: Theme.of(context).textTheme.titleSmall),
                  Text(b.worker, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                ])),
                Text(b.amount, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Text(b.id, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textHint)),
                const SizedBox(width: 12),
                Text(b.date, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textHint)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: (isCancelled ? AppColors.emergencyRed : AppColors.successGreen).withAlpha(15), borderRadius: BorderRadius.circular(12)),
                  child: Text(b.status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isCancelled ? AppColors.emergencyRed : AppColors.successGreen)),
                ),
              ]),
            ]),
          );
        },
      ),
    );
  }
}
