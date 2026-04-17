import 'package:flutter/material.dart';

class AppTheme {
  // Colors
  static const Color darkWood = Color(0xFF3E2723);
  static const Color woodBrown = Color(0xFF5D4037);
  static const Color lightWood = Color(0xFF8D6E63);
  static const Color parchment = Color(0xFFF5F5DC);
  static const Color forestGreen = Color(0xFF2E7D32);
  static const Color gold = Color(0xFFFFD700);

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: darkWood,
      colorScheme: ColorScheme.fromSeed(
        seedColor: darkWood,
        primary: darkWood,
        secondary: gold,
      ),
      scaffoldBackgroundColor: parchment,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkWood,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkWood,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
