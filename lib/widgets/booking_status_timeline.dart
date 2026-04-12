import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class BookingStatusTimeline extends StatelessWidget {
  final String currentStatus;
  
  const BookingStatusTimeline({
    super.key,
    required this.currentStatus,
  });

  int get _currentIndex {
    switch (currentStatus.toLowerCase()) {
      case 'created':
      case 'pending': return 0;
      case 'assigned':
      case 'accepted': return 1;
      case 'on_the_way': return 2;
      case 'in_progress':
      case 'started': return 3;
      case 'completed': return 4;
      default: return 0;
    }
  }

  static const _statuses = [
    'Created',
    'Worker Assigned',
    'On The Way',
    'Work Started',
    'Completed'
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(_statuses.length, (index) {
        final isCompleted = index < _currentIndex;
        final isActive = index == _currentIndex;
        final isLast = index == _statuses.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isActive || isCompleted ? AppColors.primary : AppColors.divider,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isCompleted 
                        ? const Icon(Icons.check, color: Colors.white, size: 14)
                        : (isActive ? const SizedBox(width: 8, height: 8, child: DecoratedBox(decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle))) : null),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: isCompleted ? AppColors.primary : AppColors.divider,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        _statuses[index],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                          color: isActive || isCompleted ? AppColors.textDark : AppColors.textHint,
                        ),
                      ),
                      if (isActive) ...[
                        const SizedBox(height: 4),
                        Text(
                          _getSubtext(index),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  String _getSubtext(int index) {
    switch (index) {
      case 0: return 'Your booking has been received.';
      case 1: return 'A worker has been assigned to your issue.';
      case 2: return 'The worker is heading to your location.';
      case 3: return 'The worker is currently resolving the issue.';
      case 4: return 'The job has been successfully completed.';
      default: return '';
    }
  }
}
