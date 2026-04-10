import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class CategoryChip extends StatelessWidget {
  const CategoryChip({
    required this.label,
    required this.icon,
    this.isSelected = false,
    this.onTap,
    super.key,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryBlue
              : isDark
                  ? AppColors.cardDark
                  : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : (isDark ? Colors.white10 : AppColors.divider),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.primaryBlue.withAlpha(40), blurRadius: 12, offset: const Offset(0, 4))]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 28,
              color: isSelected ? Colors.white : AppColors.primaryBlue,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppColors.textPrimary),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class ServiceCategories {
  static const categories = <({String label, IconData icon, String key})>[
    (label: 'Plumbing', icon: Icons.plumbing, key: 'plumbing'),
    (label: 'Electrical', icon: Icons.electrical_services, key: 'electrical'),
    (label: 'Carpentry', icon: Icons.carpenter, key: 'carpentry'),
    (label: 'Cleaning', icon: Icons.cleaning_services, key: 'cleaning'),
    (label: 'Painting', icon: Icons.format_paint, key: 'painting'),
    (label: 'Appliance', icon: Icons.kitchen, key: 'appliance_repair'),
    (label: 'Gas', icon: Icons.local_fire_department, key: 'gas_leakage'),
    (label: 'General', icon: Icons.build, key: 'general'),
  ];
}
