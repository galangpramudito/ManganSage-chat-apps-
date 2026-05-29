import 'package:flutter/material.dart';

/// Design tokens — typography
/// Source: design-spec.md §2 (Tipografi)
///
/// Font utama: Inter (open-source, mendekati feel SF Pro).
/// NOTE: Pastikan font Inter sudah ditambahkan di pubspec.yaml + assets.
class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Inter';

  /// Header layar — Inter Bold 20
  static const TextStyle screenHeader = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  /// Nama kontak — Inter SemiBold 16
  static const TextStyle contactName = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  /// Preview pesan — Inter Regular 13 (muted)
  static const TextStyle messagePreview = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );

  /// Isi pesan (bubble) — Inter Regular 15
  static const TextStyle messageBody = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
  );

  /// Timestamp — Inter Regular 11 (muted)
  static const TextStyle timestamp = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w400,
  );

  /// Indikator status — 11
  static const TextStyle statusIndicator = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w400,
  );

  /// Header layar profil — Inter Bold 22
  static const TextStyle profileName = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.bold,
  );
}
