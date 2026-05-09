import 'package:flutter/material.dart';

class AeternaColors {
  AeternaColors._();

  static const Color navy = Color(0xFF0A1628);
  static const Color navyLight = Color(0xFF1A2B44);
  static const Color navyDeep = Color(0xFF060E1A);
  static const Color gold = Color(0xFFC9A458);
  static const Color goldLight = Color(0xFFE8C57A);
  static const Color offWhite = Color(0xFFFAFAF8);
  static const Color muted = Color(0xFF4A5568);
  static const Color label = Color(0xFFA0AEC0);
  static const Color border = Color(0xFF2D3748);
  static const Color success = Color(0xFF48BB78);
  static const Color warning = Color(0xFFED8936);
  static const Color danger = Color(0xFFFC8181);
}

class AeternaTheme {
  AeternaTheme._();

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AeternaColors.navy,
      colorScheme: const ColorScheme.dark(
        primary: AeternaColors.gold,
        secondary: AeternaColors.goldLight,
        surface: AeternaColors.navyLight,
        onPrimary: AeternaColors.navy,
        onSecondary: AeternaColors.navy,
        onSurface: AeternaColors.offWhite,
        error: AeternaColors.danger,
      ),
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor: AeternaColors.navy,
        foregroundColor: AeternaColors.offWhite,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AeternaColors.offWhite,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: AeternaColors.navyLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AeternaColors.border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AeternaColors.gold,
          foregroundColor: AeternaColors.navy,
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          minimumSize: const Size(double.infinity, 52),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AeternaColors.gold,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AeternaColors.navyLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AeternaColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AeternaColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AeternaColors.gold, width: 2),
        ),
        labelStyle: const TextStyle(color: AeternaColors.label),
        hintStyle: const TextStyle(color: AeternaColors.muted),
      ),
      dividerTheme: const DividerThemeData(
        color: AeternaColors.border,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AeternaColors.navyLight,
        contentTextStyle: const TextStyle(
          color: AeternaColors.offWhite,
          fontFamily: 'Inter',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class AeternaText {
  AeternaText._();

  static const TextStyle headline = TextStyle(
    fontFamily: 'Inter',
    fontSize: 28,
    fontWeight: FontWeight.w900,
    color: AeternaColors.offWhite,
    letterSpacing: -0.8,
  );

  static const TextStyle title = TextStyle(
    fontFamily: 'Inter',
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: AeternaColors.offWhite,
    letterSpacing: -0.4,
  );

  static const TextStyle subtitle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AeternaColors.offWhite,
  );

  static const TextStyle body = TextStyle(
    fontFamily: 'Inter',
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AeternaColors.label,
    height: 1.5,
  );

  static const TextStyle label = TextStyle(
    fontFamily: 'DMM',
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AeternaColors.gold,
    letterSpacing: 1.5,
  );

  static const TextStyle mono = TextStyle(
    fontFamily: 'DMM',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AeternaColors.label,
  );
}
