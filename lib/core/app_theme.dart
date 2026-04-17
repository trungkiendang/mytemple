import 'package:flutter/material.dart';

class AppTheme {
  static const Color woodBrown = Color(0xFF8B4513);
  static const Color lightWood = Color(0xFFD2B48C);
  static const Color darkWood = Color(0xFF5D2906);
  static const Color forestGreen = Color(0xFF228B22);
  static const Color parchment = Color(0xFFF5F5DC);

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: woodBrown,
        primary: woodBrown,
        secondary: forestGreen,
        surface: parchment,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: darkWood,
      ),
      scaffoldBackgroundColor: parchment,
      appBarTheme: const AppBarTheme(
        backgroundColor: woodBrown,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: darkWood, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(color: darkWood),
        bodyMedium: TextStyle(color: darkWood),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: woodBrown,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
