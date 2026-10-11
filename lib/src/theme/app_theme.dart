import 'package:flutter/material.dart';

/// Tsuzuri design tokens and theme configurations.
///
/// Implements three explicit theme modes:
/// 1. System (default)
/// 2. Light (#fcfcfc canvas)
/// 3. Dark (#000000 AMOLED pure black canvas)
class AppTheme {
  // Light Palette
  static const Color lightCanvas = Color(0xFFFCFCFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSubtle = Color(0xFFF4F4F5);
  static const Color lightHover = Color(0xFFEBEBEE);
  static const Color lightBorder = Color(0xFFE4E4E7);
  static const Color lightBorderStrong = Color(0xFFD4D4D8);
  static const Color lightTextPrimary = Color(0xFF18181B);
  static const Color lightTextSecondary = Color(0xFF52525B);
  static const Color lightTextMuted = Color(0xFF71717A);
  static const Color lightLink = Color(0xFF0969DA);

  // AMOLED Dark Palette (True #000000 Pure Black)
  static const Color amoledCanvas = Color(0xFF000000);
  static const Color amoledSurface = Color(0xFF040404);
  static const Color amoledSubtle = Color(0xFF0D0D0F);
  static const Color amoledHover = Color(0xFF16161A);
  static const Color amoledBorder = Color(0xFF1C1C20);
  static const Color amoledBorderStrong = Color(0xFF2C2C32);
  static const Color amoledTextPrimary = Color(0xFFF4F4F5);
  static const Color amoledTextSecondary = Color(0xFFA1A1AA);
  static const Color amoledTextMuted = Color(0xFF71717A);
  static const Color amoledLink = Color(0xFF58A6FF);
  static const Color dangerColor = Color(0xFFDC2626);

  /// Light theme data
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightCanvas,
      colorScheme: const ColorScheme.light(
        surface: lightSurface,
        onSurface: lightTextPrimary,
        primary: lightTextPrimary,
        onPrimary: lightSurface,
        outline: lightBorder,
        outlineVariant: lightBorderStrong,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightCanvas,
        foregroundColor: lightTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: lightTextPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: lightBorder,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: lightTextPrimary, size: 20),
    );
  }

  /// True AMOLED pure black dark theme data
  static ThemeData get amoledDarkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: amoledCanvas,
      colorScheme: const ColorScheme.dark(
        surface: amoledSurface,
        onSurface: amoledTextPrimary,
        primary: amoledTextPrimary,
        onPrimary: amoledCanvas,
        outline: amoledBorder,
        outlineVariant: amoledBorderStrong,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: amoledCanvas,
        foregroundColor: amoledTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: amoledTextPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: amoledBorder,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: amoledTextPrimary, size: 20),
    );
  }
}

