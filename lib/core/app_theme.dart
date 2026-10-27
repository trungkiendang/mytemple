import 'package:flutter/material.dart';

class AppTheme {
  // Colors
  static const Color darkWood = Color(0xFF3E2723);
  static const Color woodBrown = Color(0xFF5D4037);
  static const Color lightWood = Color(0xFF8D6E63);
  static const Color parchment = Color(0xFFF5F5DC);
  static const Color forestGreen = Color(0xFF2E7D32);
  static const Color gold = Color(0xFFFFD700);
  // Accents shared with the 3D models (lacquer red, antique gold, cream ivory)
  static const Color vermilion = Color(0xFFB23A24);
  static const Color antiqueGold = Color(0xFFC9A227);
  static const Color ivory = Color(0xFFFFFBEF);

  static ThemeData get theme {
    final scheme = ColorScheme.fromSeed(
      seedColor: darkWood,
      primary: darkWood,
      secondary: antiqueGold,
      tertiary: vermilion,
      surface: ivory,
    );
    return ThemeData(
      useMaterial3: true,
      primaryColor: darkWood,
      colorScheme: scheme,
      scaffoldBackgroundColor: parchment,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkWood,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: woodBrown.withValues(alpha: 0.08)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: woodBrown.withValues(alpha: 0.16),
        side: BorderSide(color: woodBrown.withValues(alpha: 0.2)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        labelStyle: const TextStyle(color: darkWood, fontWeight: FontWeight.w500),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: antiqueGold, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkWood,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkWood,
        indicatorColor: antiqueGold,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
              fontSize: 12,
              fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
              color: states.contains(WidgetState.selected) ? antiqueGold : Colors.white70,
            )),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              size: 26,
              color: states.contains(WidgetState.selected) ? darkWood : Colors.white70,
            )),
      ),
    );
  }
}
