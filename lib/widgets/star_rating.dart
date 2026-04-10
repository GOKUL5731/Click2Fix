import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class StarRating extends StatelessWidget {
  const StarRating({
    required this.rating,
    this.maxRating = 5,
    this.size = 24,
    this.onChanged,
    this.activeColor,
    super.key,
  });

  final double rating;
  final int maxRating;
  final double size;
  final ValueChanged<double>? onChanged;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final color = activeColor ?? AppColors.trustGold;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxRating, (index) {
        final starValue = index + 1.0;
        IconData icon;
        Color starColor;

        if (rating >= starValue) {
          icon = Icons.star_rounded;
          starColor = color;
        } else if (rating >= starValue - 0.5) {
          icon = Icons.star_half_rounded;
          starColor = color;
        } else {
          icon = Icons.star_outline_rounded;
          starColor = AppColors.textHint;
        }

        return GestureDetector(
          onTap: onChanged != null ? () => onChanged!(starValue) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(icon, size: size, color: starColor),
          ),
        );
      }),
    );
  }
}
