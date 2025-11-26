import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFFFF7A18);
  static const Color secondary = Color(0xFFFFB347);

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFFF6F7FB),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFF1F1F23),
        elevation: 0,
      ),
      textTheme: base.textTheme.copyWith(
        headlineLarge: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1F1F23),
        ),
        headlineSmall: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1F1F23),
        ),
        titleMedium: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF6C6F8C),
        ),
        bodyMedium: const TextStyle(
          fontSize: 14,
          color: Color(0xFF6C6F8C),
        ),
        bodySmall: const TextStyle(
          fontSize: 12,
          letterSpacing: 1.2,
          color: Color(0xFF6C6F8C),
        ),
      ),
      sliderTheme: base.sliderTheme.copyWith(
        trackHeight: 4,
        activeTrackColor: primary,
        inactiveTrackColor: Colors.grey.shade300,
        thumbColor: primary,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
        overlayShape: SliderComponentShape.noOverlay,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        ),
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFF111218),
      textTheme: base.textTheme.copyWith(
        headlineLarge: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        headlineSmall: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        titleMedium: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFFB3B7D3),
        ),
        bodyMedium: const TextStyle(
          fontSize: 14,
          color: Color(0xFF9EA2BD),
        ),
        bodySmall: const TextStyle(
          fontSize: 12,
          letterSpacing: 1.2,
          color: Color(0xFF9EA2BD),
        ),
      ),
      sliderTheme: base.sliderTheme.copyWith(
        trackHeight: 4,
        activeTrackColor: secondary,
        inactiveTrackColor: Colors.white24,
        thumbColor: secondary,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: secondary,
          foregroundColor: Colors.black,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        ),
      ),
    );
  }
}

