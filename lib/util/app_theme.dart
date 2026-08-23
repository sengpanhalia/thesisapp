import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppThemes {
  // The USEA Smart Inventory system's brand navy, from the web app's
  // public/css/style.css (--brand #0b0c7f, --brand-dark #08096b), so the
  // phone app and the system it talks to read as one product. Everything
  // below seeds from these two, so the whole app follows.
  static const Color _accent = Color(0xFF0B0C7F);
  static const Color _accentDeep = Color(0xFF08096B);
  static const Color _lightBg = Colors.white;        // pure white page background
  static const Color _lightSurface = Colors.white;
  static const Color _textDark = Color(0xFF3D2B1F);

  static const Color _darkBg = Color(0xFF1C1713);
  static const Color _darkSurface = Color(0xFF241B16);
  static const Color _textLight = Color(0xFFF4E2CC);

  static PopupMenuThemeData _popupMenuTheme({
    required Color backgroundColor,
    required Color borderColor,
    required Color textColor,
  }) {
    return PopupMenuThemeData(
      color: backgroundColor,
      surfaceTintColor: backgroundColor,
      elevation: 10,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      menuPadding: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: borderColor),
      ),
      textStyle: GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
    );
  }

  // Light Theme
  static final light = ThemeData(
    primaryColor: _accent,
    scaffoldBackgroundColor: _lightBg,
    brightness: Brightness.light,
    appBarTheme: const AppBarTheme(
      backgroundColor: _lightBg,
      elevation: 0,
      foregroundColor: _textDark,
      titleTextStyle: TextStyle(
        color: _textDark,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: _textDark),
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: _accent,
      brightness: Brightness.light,
      primary: _accent,
      secondary: _accentDeep,
      surface: _lightSurface,
    ),
    cardColor: _lightSurface,
    textTheme: ThemeData.light()
        .textTheme
        .apply(bodyColor: _textDark, displayColor: _textDark),
    popupMenuTheme: _popupMenuTheme(
      backgroundColor: Colors.white,
      borderColor: const Color(0xFFF0E1D1),
      textColor: _textDark,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: _lightBg,
      selectedItemColor: _accent,
      unselectedItemColor: Color(0xFF9A9288),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(foregroundColor: _accent),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF1F2F5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
  );
  // Dart Theme
  static final dart = ThemeData(
    primaryColor: _accent,
    scaffoldBackgroundColor: _darkBg,
    brightness: Brightness.dark,
    appBarTheme: const AppBarTheme(
      backgroundColor: _darkBg,
      elevation: 0,
      foregroundColor: _textLight,
      titleTextStyle: TextStyle(
        color: _textLight,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: _textLight),
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: _accent,
      brightness: Brightness.dark,
      primary: _accent,
      secondary: _accentDeep,
      surface: _darkSurface,
    ),
    cardColor: _darkSurface,
    textTheme: ThemeData.dark()
        .textTheme
        .apply(bodyColor: _textLight, displayColor: _textLight),
    popupMenuTheme: _popupMenuTheme(
      backgroundColor: const Color(0xFF2B211B),
      borderColor: const Color(0xFF3A2E28),
      textColor: _textLight,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: _darkBg,
      selectedItemColor: _accent,
      unselectedItemColor: Color(0xFF9A9288),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(foregroundColor: _accent),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2A1F19),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
  );
}