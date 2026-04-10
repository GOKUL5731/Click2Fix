import 'package:flutter/material.dart';

class AdminColors {
  static const primaryBlue = Color(0xFF1976D2);
  static const successGreen = Color(0xFF2E7D32);
  static const emergencyRed = Color(0xFFD32F2F);
  static const trustGold = Color(0xFFF9A825);
  static const backgroundLight = Color(0xFFF5F7FA);
}

class AdminTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AdminColors.primaryBlue),
        scaffoldBackgroundColor: AdminColors.backgroundLight,
        cardTheme: const CardThemeData(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(seedColor: AdminColors.primaryBlue, brightness: Brightness.dark),
        cardTheme: const CardThemeData(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
        ),
      );
}

