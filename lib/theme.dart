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

class NeumorphicColors {
  static const Color lightBackground = Color(0xFFE8ECF1);
  static const Color lightSurface = Color(0xFFE8ECF1);
  static const Color lightTextPrimary = Color(0xFF2D3748);
  static const Color lightTextSecondary = Color(0xFF718096);
  static const Color lightDarkShadow = Color(0xFFA3B1C6);
  static const Color lightLightHighlight = Color(0xFFFFFFFF);

  static const Color darkBackground = Color(0xFF1E2228);
  static const Color darkSurface = Color(0xFF1E2228);
  static const Color darkTextPrimary = Color(0xFFE2E8F0);
  static const Color darkTextSecondary = Color(0xFFA0AEC0);
  static const Color darkDarkShadow = Color(0xFF121519);
  static const Color darkLightHighlight = Color(0xFF2A2F38);
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
        return isDark ? const Color(0xFFE2E8F0) : const Color(0xFF2D3748);
    }
  }

  static List<BoxShadow> getRaisedShadows(
    BuildContext context, {
    double distance = 4,
    double blur = 8,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return [
        BoxShadow(
          color: NeumorphicColors.darkDarkShadow.withValues(alpha: 0.8),
          offset: Offset(distance, distance),
          blurRadius: blur,
        ),
        BoxShadow(
          color: NeumorphicColors.darkLightHighlight.withValues(alpha: 0.5),
          offset: Offset(-distance, -distance),
          blurRadius: blur,
        ),
      ];
    } else {
      return [
        BoxShadow(
          color: NeumorphicColors.lightDarkShadow.withValues(alpha: 0.5),
          offset: Offset(distance, distance),
          blurRadius: blur,
        ),
        BoxShadow(
          color: NeumorphicColors.lightLightHighlight.withValues(alpha: 0.9),
          offset: Offset(-distance, -distance),
          blurRadius: blur,
        ),
      ];
    }
  }

  static Color getSurfaceColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? NeumorphicColors.darkSurface
        : NeumorphicColors.lightSurface;
  }

  static Color getBackgroundColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? NeumorphicColors.darkBackground
        : NeumorphicColors.lightBackground;
  }

  static ThemeData getLight(String accentName) {
    final seedColor = getAccentColor(accentName, isDark: false);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
      surface: NeumorphicColors.lightSurface,
      surfaceContainerHighest: const Color(0xFFDEE4EB),
      surfaceContainer: NeumorphicColors.lightSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: NeumorphicColors.lightBackground,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: NeumorphicColors.lightTextPrimary,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: NeumorphicColors.lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: NeumorphicColors.lightSurface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFD6DEE7), width: 0.5),
        ),
      ),
      dialogTheme: DialogThemeData(
        elevation: 0,
        backgroundColor: NeumorphicColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFD6DEE7), width: 0.5),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: NeumorphicColors.lightTextPrimary,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        elevation: 0,
        backgroundColor: NeumorphicColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: NeumorphicColors.lightSurface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD1D9E6), width: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: error, width: 1),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: const BorderSide(color: Color(0xFFC4D0DF)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFFD6DEE7)),
        ),
        backgroundColor: NeumorphicColors.lightSurface,
        selectedColor: colorScheme.primary.withValues(alpha: 0.15),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: NeumorphicColors.lightSurface,
        height: 68,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.15),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      navigationRailTheme: NavigationRailThemeData(
        elevation: 0,
        backgroundColor: NeumorphicColors.lightSurface,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.15),
        labelType: NavigationRailLabelType.all,
      ),
    );
  }

  static ThemeData getDark(String accentName) {
    final seedColor = getAccentColor(accentName, isDark: true);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
      surface: NeumorphicColors.darkSurface,
      surfaceContainerHighest: const Color(0xFF272C34),
      surfaceContainer: NeumorphicColors.darkSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: NeumorphicColors.darkBackground,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: NeumorphicColors.darkTextPrimary,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: NeumorphicColors.darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: NeumorphicColors.darkSurface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF282D36), width: 0.5),
        ),
      ),
      dialogTheme: DialogThemeData(
        elevation: 0,
        backgroundColor: NeumorphicColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF282D36), width: 0.5),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: NeumorphicColors.darkTextPrimary,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        elevation: 0,
        backgroundColor: NeumorphicColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: NeumorphicColors.darkSurface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2A2F38), width: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: errorLight, width: 1),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: const BorderSide(color: Color(0xFF323843)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFF282D36)),
        ),
        backgroundColor: NeumorphicColors.darkSurface,
        selectedColor: colorScheme.primary.withValues(alpha: 0.25),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: NeumorphicColors.darkSurface,
        height: 68,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.2),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      navigationRailTheme: NavigationRailThemeData(
        elevation: 0,
        backgroundColor: NeumorphicColors.darkSurface,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.2),
        labelType: NavigationRailLabelType.all,
      ),
    );
  }

  static ThemeData get light => getLight('default');
  static ThemeData get dark => getDark('default');
}
