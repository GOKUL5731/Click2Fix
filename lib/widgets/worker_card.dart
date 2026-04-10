import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class WorkerCard extends StatelessWidget {
  const WorkerCard({
    required this.name,
    required this.category,
    required this.rating,
    required this.trustScore,
    required this.price,
    required this.distance,
    required this.eta,
    this.isVerified = true,
    this.onTap,
    this.onBook,
    super.key,
  });

  final String name;
  final String category;
  final double rating;
  final int trustScore;
  final String price;
  final String distance;
  final String eta;
  final bool isVerified;
  final VoidCallback? onTap;
  final VoidCallback? onBook;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white10 : AppColors.divider),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withAlpha(8),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: Theme.of(context).textTheme.titleLarge,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isVerified) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.verified, color: AppColors.primaryBlue, size: 18),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                // Price
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    price,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.successGreen,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Stats row
            Row(
              children: [
                _StatChip(
                  icon: Icons.star_rounded,
                  iconColor: AppColors.trustGold,
                  label: rating.toStringAsFixed(1),
                ),
                const SizedBox(width: 12),
                _StatChip(
                  icon: Icons.shield_outlined,
                  iconColor: AppColors.primaryBlue,
                  label: 'Trust $trustScore',
                ),
                const SizedBox(width: 12),
                _StatChip(
                  icon: Icons.location_on_outlined,
                  iconColor: AppColors.textSecondary,
                  label: distance,
                ),
                const SizedBox(width: 12),
                _StatChip(
                  icon: Icons.access_time_rounded,
                  iconColor: AppColors.textSecondary,
                  label: eta,
                ),
              ],
            ),
            if (onBook != null) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onBook,
                  child: const Text('Book Now'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label, this.iconColor});

  final IconData icon;
  final String label;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: iconColor),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
