import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'app_button.dart';

class ErrorWidgetDisplay extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorWidgetDisplay({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              AppButton(
                text: 'Retry',
                onPressed: onRetry,
                isOutlined: true,
              ),
            ]
          ],
        ),
      ),
    );
  }
}
