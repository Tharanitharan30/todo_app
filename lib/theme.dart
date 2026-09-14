import 'package:flutter/material.dart';

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
}

class AppTheme {
  // Semantic Colors
  static const Color success = Color(0xFF2E7D32);
  static const Color successLight = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFED6C02);
  static const Color warningLight = Color(0xFFFF9800);
  static const Color error = Color(0xFFD32F2F);
  static const Color errorLight = Color(0xFFEF5350);
  static const Color info = Color(0xFF0288D1);
  static const Color infoLight = Color(0xFF03A9F4);

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
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor == Colors.black ? Colors.black : seedColor,
      brightness: Brightness.light,
      surface: const Color(0xFFF8F9FA),
      surfaceContainerHighest: const Color(0xFFEEEEEE),
      surfaceContainer: const Color(0xFFF1F3F5),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFE9ECEF), width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        elevation: 2,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        elevation: 2,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F3F5),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE9ECEF), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: error, width: 1),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          side: const BorderSide(color: Color(0xFFCED4DA)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFFE9ECEF)),
        ),
        backgroundColor: const Color(0xFFF1F3F5),
        selectedColor: colorScheme.primary.withValues(alpha: 0.15),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: Colors.white,
        height: 64,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.12),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      navigationRailTheme: NavigationRailThemeData(
        elevation: 0,
        backgroundColor: Colors.white,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.12),
        labelType: NavigationRailLabelType.all,
      ),
    );
  }

  static ThemeData getDark(String accentName) {
    final seedColor = getAccentColor(accentName, isDark: true);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor == Colors.white ? Colors.white : seedColor,
      brightness: Brightness.dark,
      surface: const Color(0xFF121212),
      surfaceContainerHighest: const Color(0xFF2C2C2C),
      surfaceContainer: const Color(0xFF1E1E1E),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF1E1E1E),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFF2C2C2C), width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        elevation: 4,
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        elevation: 4,
        backgroundColor: Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF383838), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: errorLight, width: 1),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          side: const BorderSide(color: Color(0xFF444444)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFF383838)),
        ),
        backgroundColor: const Color(0xFF2C2C2C),
        selectedColor: colorScheme.primary.withValues(alpha: 0.25),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: const Color(0xFF1E1E1E),
        height: 64,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.2),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      navigationRailTheme: NavigationRailThemeData(
        elevation: 0,
        backgroundColor: const Color(0xFF1E1E1E),
        indicatorColor: colorScheme.primary.withValues(alpha: 0.2),
        labelType: NavigationRailLabelType.all,
      ),
    );
  }

  static ThemeData get light => getLight('default');
  static ThemeData get dark => getDark('default');
}
