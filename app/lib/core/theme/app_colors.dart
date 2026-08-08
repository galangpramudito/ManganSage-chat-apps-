import 'package:flutter/material.dart';

/// Design tokens — Monochrome Clean Esports Minimalist
class AppColors {
  AppColors._();

  // Light & Dark Base
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color backgroundDark  = Color(0xFF0A0A0A);
  
  static const Color foregroundLight = Color(0xFF000000);
  static const Color foregroundDark  = Color(0xFFFFFFFF);

  // Skala Monokrom (Neutral Gray Scale)
  static const Color mono50  = Color(0xFFFAFAFA);
  static const Color mono100 = Color(0xFFF5F5F5);
  static const Color mono200 = Color(0xFFE5E5E5); // Border light
  static const Color mono300 = Color(0xFFD4D4D4);
  static const Color mono400 = Color(0xFFA3A3A3); // Placeholder / text subtle
  static const Color mono500 = Color(0xFF737373);
  static const Color mono600 = Color(0xFF525252);
  static const Color mono700 = Color(0xFF404040); // Secondary text dark
  static const Color mono800 = Color(0xFF262626); // Border dark / Card dark
  static const Color mono900 = Color(0xFF171717); // Dark surface
  static const Color mono950 = Color(0xFF0A0A0A); // Background dark

  // Status Badge Colors (Kehadiran & Absen)
  static const Color statusPresent = Color(0xFF10B981); // Hijau (Hadir)
  static const Color statusLate    = Color(0xFFF59E0B); // Amber / Kuning (Terlambat)
  static const Color statusIzin    = Color(0xFF3B82F6); // Biru (Izin)
  static const Color statusIzinLate= Color(0xFFF97316); // Oranye (Izin Terlambat)

  // Helper methods for backwards compatibility
  static Color accentSoft(Brightness b) =>
      b == Brightness.dark ? mono900 : mono100;

  static const List<Color> avatarPalette = [
    Color(0xFF000000),
    Color(0xFF171717),
    Color(0xFF262626),
    Color(0xFF404040),
    Color(0xFF525252),
    Color(0xFF737373),
    Color(0xFFA3A3A3),
    Color(0xFFD4D4D4),
    Color(0xFFE5E5E5),
    Color(0xFFF5F5F5),
  ];
}


