import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminColors {
  static const primaryBlue = Color(0xFF0F4C81);
  static const accentOrange = Color(0xFFFF7A18);
  static const successGreen = Color(0xFF0B8F6A);
  static const emergencyRed = Color(0xFFD64545);
  static const trustGold = Color(0xFFE7B10A);
  static const surfaceCream = Color(0xFFF8F5EF);
  static const slateInk = Color(0xFF1E2737);
  static const cardFog = Color(0xFFFFFCF8);
  static const midnight = Color(0xFF11161F);
}

class AdminTheme {
  static final _baseLight = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AdminColors.primaryBlue,
      primary: AdminColors.primaryBlue,
      secondary: AdminColors.accentOrange,
      surface: AdminColors.cardFog,
      brightness: Brightness.light,
    ),
  );

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: _baseLight.colorScheme,
        scaffoldBackgroundColor: AdminColors.surfaceCream,
        textTheme: GoogleFonts.soraTextTheme(_baseLight.textTheme).apply(
          bodyColor: AdminColors.slateInk,
          displayColor: AdminColors.slateInk,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: AdminColors.slateInk,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          color: AdminColors.cardFog,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20))),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: AdminColors.primaryBlue, width: 1.5),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AdminColors.primaryBlue,
            foregroundColor: Colors.white,
            minimumSize: const Size(120, 48),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: Colors.white,
          side: BorderSide.none,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      );

  static final _baseDark = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AdminColors.accentOrange,
      primary: AdminColors.accentOrange,
      secondary: AdminColors.primaryBlue,
      surface: AdminColors.midnight,
      brightness: Brightness.dark,
    ),
  );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: _baseDark.colorScheme,
        textTheme: GoogleFonts.soraTextTheme(_baseDark.textTheme),
        cardTheme: const CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20))),
        ),
      );
}
