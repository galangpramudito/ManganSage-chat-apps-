import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  // Light Theme
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.backgroundLight,
    primaryColor: Colors.black,
    fontFamily: GoogleFonts.inter().fontFamily,
    colorScheme: const ColorScheme.light(
      surface: AppColors.backgroundLight,
      onSurface: AppColors.foregroundLight,
      surfaceContainerHigh: AppColors.mono50,
      surfaceContainerHighest: AppColors.mono100,
      primary: Colors.black,
      onPrimary: Colors.white,
      secondary: AppColors.mono700,
      outline: AppColors.mono200,
      error: Colors.red,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.backgroundLight,
      foregroundColor: AppColors.foregroundLight,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: AppTypography.headingTitle(false).copyWith(fontSize: 18),
    ),
    cardTheme: CardThemeData(
      color: AppColors.backgroundLight,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.mono200, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: AppColors.mono50,
      border: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.mono200),
        borderRadius: BorderRadius.all(Radius.circular(4)),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.mono200),
        borderRadius: BorderRadius.all(Radius.circular(4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.black, width: 1.5),
        borderRadius: BorderRadius.all(Radius.circular(4)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.backgroundLight,
      elevation: 0,
      height: 64,
      indicatorColor: AppColors.mono100,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          color: s.contains(WidgetState.selected) ? Colors.black : AppColors.mono400,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          size: 22,
          color: s.contains(WidgetState.selected) ? Colors.black : AppColors.mono400,
        ),
      ),
    ),
  );

  // Dark Theme
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.backgroundDark,
    primaryColor: Colors.white,
    fontFamily: GoogleFonts.inter().fontFamily,
    colorScheme: const ColorScheme.dark(
      surface: AppColors.backgroundDark,
      onSurface: AppColors.foregroundDark,
      surfaceContainerHigh: AppColors.mono900,
      surfaceContainerHighest: AppColors.mono800,
      primary: Colors.white,
      onPrimary: Colors.black,
      secondary: AppColors.mono400,
      outline: AppColors.mono800,
      error: Colors.redAccent,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.backgroundDark,
      foregroundColor: AppColors.foregroundDark,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: AppTypography.headingTitle(true).copyWith(fontSize: 18),
    ),
    cardTheme: CardThemeData(
      color: AppColors.mono900,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.mono800, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: AppColors.mono900,
      border: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.mono800),
        borderRadius: BorderRadius.all(Radius.circular(4)),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.mono800),
        borderRadius: BorderRadius.all(Radius.circular(4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white, width: 1.5),
        borderRadius: BorderRadius.all(Radius.circular(4)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.backgroundDark,
      elevation: 0,
      height: 64,
      indicatorColor: AppColors.mono800,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          color: s.contains(WidgetState.selected) ? Colors.white : AppColors.mono700,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          size: 22,
          color: s.contains(WidgetState.selected) ? Colors.white : AppColors.mono700,
        ),
      ),
    ),
  );

  static ThemeData light() => lightTheme;
  static ThemeData dark() => darkTheme;
}

