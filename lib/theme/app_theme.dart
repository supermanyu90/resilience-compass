// app_theme.dart
//
// Dark theme palette for visual continuity with the web app (shown side-by-side in the pitch).
// If the web app's exact palette is available, swap the hex values below to match it.

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const background = Color(0xFF0B1220); // deep navy
  static const surface = Color(0xFF141C2B);
  static const surfaceAlt = Color(0xFF1C2740);
  static const border = Color(0xFF243048);

  static const primary = Color(0xFF3DD6C4); // teal accent (compass)
  static const accent = Color(0xFF6C8CFF); // indigo secondary

  static const textPrimary = Color(0xFFE6ECF5);
  static const textSecondary = Color(0xFF95A3B8);

  // Semantic scale (reused for severity + maturity)
  static const good = Color(0xFF4ADE80); // strong / low severity
  static const warn = Color(0xFFF5B841); // moderate / medium severity
  static const danger = Color(0xFFFF6B6B); // weak / high severity

  /// Colour for a 1–4 maturity score.
  static Color maturity(int score) {
    switch (score) {
      case 4:
        return good;
      case 3:
        return primary;
      case 2:
        return warn;
      default:
        return danger;
    }
  }

  /// Colour for a 0–100 resilience score.
  static Color scoreBand(int score) {
    if (score >= 67) return good;
    if (score >= 34) return warn;
    return danger;
  }
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.surface,
      error: AppColors.danger,
      onPrimary: Color(0xFF04231F),
      onSecondary: Color(0xFF0A1330),
      onSurface: AppColors.textPrimary,
      onError: Color(0xFF2A0A0A),
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Roboto',
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceAlt,
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: const Color(0xFF04231F),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.surfaceAlt,
        selectedColor: AppColors.primary.withValues(alpha: 0.18),
        side: const BorderSide(color: AppColors.border),
        labelStyle: const TextStyle(color: AppColors.textPrimary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ),
      dividerColor: AppColors.border,
    );
  }
}
