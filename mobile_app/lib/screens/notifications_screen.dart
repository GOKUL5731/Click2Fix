import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/app_theme.dart';
import '../providers/session_provider.dart';
import '../services/api_client.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final client = ApiClient()
        ..setToken(ref.read(sessionProvider).token);
      final response = await client.get('/notifications');
      final data = response.data;
      List<dynamic> list = [];
      if (data is List) {
        list = data;
      } else if (data is Map && data['notifications'] is List) {
        list = data['notifications'] as List;
      }
      if (mounted) setState(() => _notifications = list);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  IconData _iconFor(String? type) {
    switch (type) {
      case 'booking_confirmed':
        return Icons.check_circle;
      case 'worker_nearby':
        return Icons.person_pin_circle;
      case 'payment':
        return Icons.currency_rupee;
      case 'rating':
        return Icons.star;
      case 'offer':
        return Icons.local_offer;
      default:
        return Icons.notifications;
    }
  }

  Color _colorFor(String? type) {
    switch (type) {
      case 'booking_confirmed':
        return AppColors.successGreen;
      case 'worker_nearby':
        return AppColors.primaryBlue;
      case 'payment':
        return AppColors.trustGold;
      case 'rating':
        return AppColors.trustGold;
      case 'offer':
        return AppColors.primaryBlue;
      default:
        return AppColors.primaryBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: _loadNotifications,
            child: const Text('Refresh'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off,
                          size: 56, color: AppColors.textHint),
                      const SizedBox(height: 16),
                      Text(_error!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _loadNotifications,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.notifications_off_outlined,
                              size: 56, color: AppColors.textHint),
                          const SizedBox(height: 16),
                          Text('No notifications yet',
                              style: Theme.of(context).textTheme.titleMedium),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final n =
                            _notifications[index] as Map<String, dynamic>? ??
                                {};
                        final type = n['type'] as String?;
                        final isRead = n['isRead'] as bool? ?? true;
                        final icon = _iconFor(type);
                        final color = _colorFor(type);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isRead
                                ? (isDark ? AppColors.cardDark : Colors.white)
                                : (isDark
                                    ? AppColors.primaryBlue.withAlpha(10)
                                    : AppColors.primaryBlue.withAlpha(8)),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isRead
                                  ? (isDark
                                      ? Colors.white10
                                      : AppColors.divider)
                                  : AppColors.primaryBlue.withAlpha(30),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: color.withAlpha(15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(icon, size: 20, color: color),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Expanded(
                                        child: Text(
                                          n['title'] as String? ??
                                              'Notification',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                fontWeight: isRead
                                                    ? FontWeight.w500
                                                    : FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                      if (!isRead)
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppColors.primaryBlue,
                                          ),
                                        ),
                                    ]),
                                    const SizedBox(height: 4),
                                    Text(
                                      n['message'] as String? ??
                                          n['body'] as String? ??
                                          '',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                              color: AppColors.textSecondary),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      n['createdAt'] as String? ?? '',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                              color: AppColors.textHint),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}
