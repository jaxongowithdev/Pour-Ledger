import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFFC4782A);
  static const Color secondaryColor = Color(0xFF8C4A2F);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: const CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        filled: true,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: const CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        filled: true,
      ),
    );
  }

  // Color palette for work items
  static const List<Color> workItemColors = [
    Color(0xFFE0A15A), // Honey
    Color(0xFFC46B4A), // Clay
    Color(0xFF8C5A3C), // Cocoa
    Color(0xFFD4C4A8), // Cream
    Color(0xFF6E8B6A), // Sage
    Color(0xFFB23A48), // Wax red
    Color(0xFFE6C15A), // Gold
    Color(0xFF4E6E6A), // Slate
  ];

  static Color getWorkItemColor(int? colorValue) {
    if (colorValue == null || colorValue < 0 || colorValue >= workItemColors.length) {
      return workItemColors[0];
    }
    return workItemColors[colorValue];
  }
}
