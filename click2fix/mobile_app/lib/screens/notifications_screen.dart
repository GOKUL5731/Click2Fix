import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static const _notifs = [
    (icon: Icons.check_circle, color: AppColors.successGreen, title: 'Booking Confirmed', body: 'Ravi Kumar accepted your booking.', time: '2 min ago', isRead: false),
    (icon: Icons.person, color: AppColors.primaryBlue, title: 'Worker Nearby', body: 'Ravi Kumar is 2 km away and arriving in 18 min.', time: '5 min ago', isRead: false),
    (icon: Icons.star, color: AppColors.trustGold, title: 'Rate Your Service', body: 'How was your recent plumbing service?', time: '2 hours ago', isRead: true),
    (icon: Icons.local_offer, color: AppColors.primaryBlue, title: 'Special Offer', body: '20% off on electrical services this week!', time: '1 day ago', isRead: true),
    (icon: Icons.shield, color: AppColors.successGreen, title: 'Account Verified', body: 'Your phone number has been verified successfully.', time: '3 days ago', isRead: true),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => context.go('/home')),
        title: const Text('Notifications'),
        actions: [TextButton(onPressed: () {}, child: const Text('Mark all read'))],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16), itemCount: _notifs.length,
        itemBuilder: (context, index) {
          final n = _notifs[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: n.isRead ? (isDark ? AppColors.cardDark : Colors.white) : (isDark ? AppColors.primaryBlue.withAlpha(10) : AppColors.primaryBlue.withAlpha(8)),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: n.isRead ? (isDark ? Colors.white10 : AppColors.divider) : AppColors.primaryBlue.withAlpha(30)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: n.color.withAlpha(15), borderRadius: BorderRadius.circular(10)),
                child: Icon(n.icon, size: 20, color: n.color)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(n.title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w700))),
                  if (!n.isRead) Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryBlue)),
                ]),
                const SizedBox(height: 4),
                Text(n.body, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Text(n.time, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textHint)),
              ])),
            ]),
          );
        },
      ),
    );
  }
}
