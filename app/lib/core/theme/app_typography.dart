import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  // 1. Heading Utama (Montserrat Black Uppercase)
  static TextStyle headingTitle(bool isDark) => GoogleFonts.montserrat(
        fontSize: 24,
        fontWeight: FontWeight.w900,
        letterSpacing: 2.0,
        color: isDark ? Colors.white : Colors.black,
      );

  // 2. Badge & Subtitle (Micro Uppercase with Wide Spacing)
  static TextStyle badgeText(bool isDark) => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 2.5,
        color: isDark ? Colors.white : Colors.black,
      );

  // 3. Body Text
  static TextStyle bodyText(bool isDark) => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: isDark ? const Color(0xFFA3A3A3) : const Color(0xFF525252),
      );

  // 4. Button Text
  static TextStyle buttonText(bool isPrimaryDark) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 2.0,
        color: isPrimaryDark ? Colors.black : Colors.white,
      );

  // Legacy static styles
  static TextStyle screenHeader = GoogleFonts.montserrat(
    fontSize: 20,
    fontWeight: FontWeight.w900,
    letterSpacing: 1.5,
  );

  static TextStyle contactName = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w700,
  );

  static TextStyle messagePreview = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );

  static TextStyle messageBody = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static TextStyle timestamp = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w400,
  );

  static TextStyle profileName = GoogleFonts.montserrat(
    fontSize: 22,
    fontWeight: FontWeight.w900,
    letterSpacing: 1.5,
  );
}

