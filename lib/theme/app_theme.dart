import 'package:flutter/material.dart';

// Burgundy + Coral palette.
class AppColors {
  AppColors._();

  static const burgundy900 = Color(0xFF5B1111);
  static const burgundy700 = Color(0xFF8F1D1D);
  static const red600 = Color(0xFFC62828);
  static const coral500 = Color(0xFFF04444);
  static const coral300 = Color(0xFFFF7A7A);
  static const background = Color(0xFFFAF7F7);

  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [burgundy900, burgundy700, red600, coral500, coral300],
  );

  static const severityLow = Color(0xFF4C8C4A);
  static const severityModerate = Color(0xFFD08A1E);
  static const severityHigh = coral500;
  static const severityCritical = burgundy900;
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.red600,
      primary: AppColors.red600,
      secondary: AppColors.coral500,
      surface: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shadowColor: AppColors.burgundy900.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.burgundy900.withValues(alpha: 0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.burgundy900.withValues(alpha: 0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.red600, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.red600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontWeight: FontWeight.bold, color: AppColors.burgundy900),
        titleLarge: TextStyle(fontWeight: FontWeight.w700, color: AppColors.burgundy900),
        bodyMedium: TextStyle(color: Color(0xFF3A2323)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.burgundy900,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

Color severityColor(String severity) {
  switch (severity.toLowerCase()) {
    case 'low':
      return AppColors.severityLow;
    case 'moderate':
      return AppColors.severityModerate;
    case 'high':
      return AppColors.severityHigh;
    case 'critical':
      return AppColors.severityCritical;
    default:
      return AppColors.severityModerate;
  }
}
