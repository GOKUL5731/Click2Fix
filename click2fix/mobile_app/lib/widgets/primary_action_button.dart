import 'package:flutter/material.dart';

class PrimaryActionButton extends StatelessWidget {
  const PrimaryActionButton({
    required this.label,
    required this.onPressed,
    this.backgroundColor,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        style: backgroundColor == null ? null : FilledButton.styleFrom(backgroundColor: backgroundColor),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}

