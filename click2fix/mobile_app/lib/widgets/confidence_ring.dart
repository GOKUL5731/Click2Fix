import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class ConfidenceRing extends StatelessWidget {
  const ConfidenceRing({
    required this.confidence,
    this.size = 120,
    this.strokeWidth = 10,
    this.label,
    super.key,
  });

  final double confidence;
  final double size;
  final double strokeWidth;
  final String? label;

  Color get _ringColor {
    if (confidence >= 0.8) return AppColors.successGreen;
    if (confidence >= 0.6) return AppColors.trustGold;
    return AppColors.emergencyRed;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background ring
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              progress: 1.0,
              color: _ringColor.withAlpha(30),
              strokeWidth: strokeWidth,
            ),
          ),
          // Foreground ring
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: confidence),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return CustomPaint(
                size: Size(size, size),
                painter: _RingPainter(
                  progress: value,
                  color: _ringColor,
                  strokeWidth: strokeWidth,
                ),
              );
            },
          ),
          // Center text
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: confidence * 100),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Text(
                    '${value.toInt()}%',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: _ringColor,
                        ),
                  );
                },
              ),
              if (label != null)
                Text(
                  label!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: (size.width - strokeWidth) / 2,
    );

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, paint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.color != color;
}
