import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Bundling ThemeData light & dark sesuai design-spec.md §3.
///
/// Mapping ke Material ColorScheme (untuk konsumsi widget Flutter standar):
/// - `primary` = accent (sapphire) — tombol, link, elemen aktif
/// - `surface` = background utama
/// - `surfaceContainerHigh` = surface (kartu)
/// - `surfaceContainerHighest` = surface-elevated (input, search)
class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: const ColorScheme.light(
        surface: AppColors.lightBackground,
        onSurface: AppColors.lightForeground,
        surfaceContainerHigh: AppColors.lightSurface,
        surfaceContainerHighest: AppColors.lightSurfaceElevated,
        primary: AppColors.lightAccent,
        onPrimary: Colors.white,
        primaryContainer: AppColors.lightAccentSoft,
        onPrimaryContainer: AppColors.lightAccent,
        secondary: AppColors.lightMuted,
        outline: AppColors.lightDivider,
        error: AppColors.lightDestructive,
      ),
      dividerColor: AppColors.lightDivider,
      textTheme: _textTheme(AppColors.lightForeground, AppColors.lightMuted),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightSurface,
        foregroundColor: AppColors.lightForeground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.screenHeader,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        elevation: 0,
        height: 64,
        indicatorColor: AppColors.lightAccentSoft,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: s.contains(WidgetState.selected)
                ? AppColors.lightAccent
                : AppColors.lightMuted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            size: 24,
            color: s.contains(WidgetState.selected)
                ? AppColors.lightAccent
                : AppColors.lightMuted,
          ),
        ),
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.darkBackground,
        onSurface: AppColors.darkForeground,
        surfaceContainerHigh: AppColors.darkSurface,
        surfaceContainerHighest: AppColors.darkSurfaceElevated,
        primary: AppColors.darkAccent,
        onPrimary: Colors.white,
        primaryContainer: AppColors.darkAccentSoft,
        onPrimaryContainer: AppColors.darkAccent,
        secondary: AppColors.darkMuted,
        outline: AppColors.darkDivider,
        error: AppColors.darkDestructive,
      ),
      dividerColor: AppColors.darkDivider,
      textTheme: _textTheme(AppColors.darkForeground, AppColors.darkMuted),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkForeground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.screenHeader,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        height: 64,
        indicatorColor: AppColors.darkAccentSoft,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: s.contains(WidgetState.selected)
                ? AppColors.darkAccent
                : AppColors.darkMuted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            size: 24,
            color: s.contains(WidgetState.selected)
                ? AppColors.darkAccent
                : AppColors.darkMuted,
          ),
        ),
      ),
    );
  }

  static TextTheme _textTheme(Color foreground, Color muted) {
    return TextTheme(
      titleLarge: AppTypography.screenHeader.copyWith(color: foreground),
      titleMedium: AppTypography.contactName.copyWith(color: foreground),
      bodyLarge: AppTypography.messageBody.copyWith(color: foreground),
      bodyMedium: AppTypography.messagePreview.copyWith(color: muted),
      labelSmall: AppTypography.timestamp.copyWith(color: muted),
    );
  }
}
