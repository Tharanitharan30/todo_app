import 'package:flutter/material.dart';

class AppTheme {
  static Color getAccentColor(String name, {required bool isDark}) {
    switch (name.toLowerCase()) {
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'purple':
        return Colors.deepPurple;
      case 'orange':
        return Colors.orange;
      case 'red':
        return Colors.red;
      case 'default':
      default:
        return isDark ? Colors.white : Colors.black;
    }
  }

  static ThemeData getLight(String accentName) {
    final seedColor = getAccentColor(accentName, isDark: false);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF7F7F7),
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor == Colors.black ? Colors.black : seedColor,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  static ThemeData getDark(String accentName) {
    final seedColor = getAccentColor(accentName, isDark: true);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF101010),
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor == Colors.white ? Colors.white : seedColor,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  static ThemeData get light => getLight('default');
  static ThemeData get dark => getDark('default');
}