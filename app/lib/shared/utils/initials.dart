import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Util untuk sistem inisial avatar deterministik.
/// Source: design-spec.md §5 (Avatar & Identitas Pengguna)
class Initials {
  Initials._();

  /// Ambil 2 huruf pertama dari nama depan + nama belakang.
  /// "Andi Pratama" -> "AP"
  /// "Budi"         -> "B"
  static String from(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';

    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.characters.first.toUpperCase();
    }
    final first = parts.first.characters.first;
    final last = parts.last.characters.first;
    return '$first$last'.toUpperCase();
  }

  /// Warna background deterministik berdasarkan hash nama.
  /// Sama di semua perangkat untuk user yang sama.
  static Color colorFor(String name) {
    final hash = name.hashCode.abs();
    return AppColors.avatarPalette[hash % AppColors.avatarPalette.length];
  }
}
