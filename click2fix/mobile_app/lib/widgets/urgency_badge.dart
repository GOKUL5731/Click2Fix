import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class UrgencyBadge extends StatelessWidget {
  const UrgencyBadge({required this.level, this.large = false, super.key});

  final String level;
  final bool large;

  Color get _color {
    switch (level.toLowerCase()) {
      case 'critical':
        return AppColors.emergencyRed;
      case 'high':
        return const Color(0xFFE65100);
      case 'medium':
        return AppColors.trustGold;
      case 'low':
        return AppColors.successGreen;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData get _icon {
    switch (level.toLowerCase()) {
      case 'critical':
        return Icons.warning_amber_rounded;
      case 'high':
        return Icons.priority_high_rounded;
      case 'medium':
        return Icons.schedule_rounded;
      case 'low':
        return Icons.check_circle_outline_rounded;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 14 : 10,
        vertical: large ? 8 : 5,
      ),
      decoration: BoxDecoration(
        color: _color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: large ? 18 : 14, color: _color),
          const SizedBox(width: 5),
          Text(
            level[0].toUpperCase() + level.substring(1),
            style: TextStyle(
              fontSize: large ? 13 : 11,
              fontWeight: FontWeight.w600,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }
}
