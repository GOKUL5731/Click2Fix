import 'package:flutter/material.dart';

class ActionButton extends StatelessWidget {
  const ActionButton({required this.label, required this.onPressed, this.color, super.key});

  final String label;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        style: color == null ? null : FilledButton.styleFrom(backgroundColor: color),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}

