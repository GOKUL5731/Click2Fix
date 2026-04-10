import 'package:flutter/material.dart';

// ─── Brand Palette ────────────────────────────────────────────────
class AppColors {
  static const primaryBlue = Color(0xFF1976D2);
  static const primaryBlueDark = Color(0xFF1565C0);
  static const primaryBlueLight = Color(0xFF42A5F5);
  static const successGreen = Color(0xFF2E7D32);
  static const emergencyRed = Color(0xFFD32F2F);
  static const emergencyRedLight = Color(0xFFEF5350);
  static const trustGold = Color(0xFFF9A825);
  static const trustGoldLight = Color(0xFFFFD54F);
  static const backgroundLight = Color(0xFFF5F7FA);
  static const backgroundDark = Color(0xFF121212);
  static const surfaceDark = Color(0xFF1E1E2C);
  static const cardDark = Color(0xFF252540);
  static const textPrimary = Color(0xFF1A1A2E);
  static const textSecondary = Color(0xFF6B7280);
  static const textHint = Color(0xFF9CA3AF);
  static const divider = Color(0xFFE5E7EB);

  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF1976D2), Color(0xFF1565C0), Color(0xFF0D47A1)],
  );
  static const emergencyGradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFFD32F2F), Color(0xFFC62828), Color(0xFFB71C1C)],
  );
  static const goldGradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFFF9A825), Color(0xFFF57F17)],
  );
  static const darkGradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF1E1E2C), Color(0xFF16213E)],
  );
}

const _fontFamily = 'Segoe UI';

class AppTheme {
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryBlue,
      primary: AppColors.primaryBlue,
      secondary: AppColors.trustGold,
      error: AppColors.emergencyRed,
      surface: Colors.white,
    );
    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      textTheme: base.textTheme.apply(fontFamily: _fontFamily),
      appBarTheme: const AppBarTheme(
        elevation: 0, centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        titleTextStyle: TextStyle(fontFamily: _fontFamily, fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        elevation: 0, color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppColors.divider.withAlpha(128))),
      ),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontFamily: _fontFamily, fontSize: 15, fontWeight: FontWeight.w600),
      )),
      outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide(color: AppColors.primaryBlue.withAlpha(100)),
      )),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.divider)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.divider)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.emergencyRed)),
        hintStyle: const TextStyle(fontFamily: _fontFamily, fontSize: 14, color: AppColors.textHint),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1, space: 1),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        indicatorColor: AppColors.primaryBlue.withAlpha(30),
      ),
    );
  }

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryBlue, brightness: Brightness.dark,
      primary: AppColors.primaryBlueLight, secondary: AppColors.trustGold,
      error: AppColors.emergencyRedLight, surface: AppColors.surfaceDark,
    );
    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      textTheme: base.textTheme.apply(fontFamily: _fontFamily),
      appBarTheme: const AppBarTheme(
        elevation: 0, centerTitle: false,
        backgroundColor: Colors.transparent, foregroundColor: Colors.white,
        titleTextStyle: TextStyle(fontFamily: _fontFamily, fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
      ),
      cardTheme: CardThemeData(
        elevation: 0, color: AppColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.white.withAlpha(20))),
      ),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      )),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: AppColors.cardDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withAlpha(20))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withAlpha(20))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primaryBlueLight, width: 2)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        indicatorColor: AppColors.primaryBlueLight.withAlpha(30),
      ),
    );
  }
}
