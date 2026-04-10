import 'package:flutter/material.dart';

import '../config/admin_theme.dart';

class KpiCard extends StatelessWidget {
  const KpiCard({
    required this.label,
    required this.value,
    this.delta = '+0%',
    this.positive = true,
    super.key,
  });

  final String label;
  final String value;
  final String delta;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final color =
        positive ? AdminColors.successGreen : AdminColors.emergencyRed;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(positive ? Icons.trending_up : Icons.trending_down,
                    size: 16, color: color),
                const SizedBox(width: 4),
                Text(
                  delta,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
