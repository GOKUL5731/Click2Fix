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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
              : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 28,
              color: isSelected ? Colors.white : AppColors.primary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textDark,
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
    (label: 'AC Repair', icon: Icons.ac_unit, key: 'ac_repair'),
    (label: 'General', icon: Icons.build, key: 'general'),
  ];
}
