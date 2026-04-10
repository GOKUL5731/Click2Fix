import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class GradientHeader extends StatelessWidget {
  const GradientHeader({
    required this.title,
    this.subtitle,
    this.height = 200,
    this.gradient,
    this.trailing,
    this.leading,
    this.child,
    super.key,
  });

  final String title;
  final String? subtitle;
  final double height;
  final LinearGradient? gradient;
  final Widget? trailing;
  final Widget? leading;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      decoration: BoxDecoration(
        gradient: gradient ?? AppColors.primaryGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: (gradient?.colors.first ?? AppColors.primaryBlue).withAlpha(60),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 12)],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white70,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            if (child != null) ...[const SizedBox(height: 16), child!],
          ],
        ),
      ),
    );
  }
}
