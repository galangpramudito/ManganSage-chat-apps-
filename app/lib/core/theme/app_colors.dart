import 'package:flutter/material.dart';

/// Design tokens — color palette
/// Source: design-spec.md §3 (Skema Warna) + §5 (Avatar palette).
///
/// Filosofi: warm-white & blue-black backgrounds, sapphire blue (#0A84FF)
/// sebagai accent untuk elemen interaktif & bubble pesan terkirim.
class AppColors {
  AppColors._();

  // ─── Light Mode ──────────────────────────────────────────────────────────
  static const Color lightBackground = Color(0xFFF8F9FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFEEF1F6);
  static const Color lightForeground = Color(0xFF0D1117);
  static const Color lightMuted = Color(0xFF8A94A6);
  static const Color lightDivider = Color(0xFFE2E6ED);

  static const Color lightAccent = Color(0xFF0A84FF);
  static const Color lightAccentSoft = Color(0xFFE8F2FF);

  static const Color lightBubbleSent = Color(0xFF0A84FF);
  static const Color lightBubbleSentText = Color(0xFFFFFFFF);
  static const Color lightBubbleReceived = Color(0xFFFFFFFF);
  static const Color lightBubbleReceivedText = Color(0xFF0D1117);
  static const Color lightBubbleReceivedBorder = Color(0xFFE2E6ED);

  static const Color lightOnlineDot = Color(0xFF34C759);
  static const Color lightDestructive = Color(0xFFFF3B30);

  // ─── Dark Mode ───────────────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0D1117);
  static const Color darkSurface = Color(0xFF161B22);
  static const Color darkSurfaceElevated = Color(0xFF21262D);
  static const Color darkForeground = Color(0xFFF0F6FC);
  static const Color darkMuted = Color(0xFF6E7681);
  static const Color darkDivider = Color(0xFF21262D);

  static const Color darkAccent = Color(0xFF2F9EFF);
  static const Color darkAccentSoft = Color(0xFF1A2D45);

  static const Color darkBubbleSent = Color(0xFF2F9EFF);
  static const Color darkBubbleSentText = Color(0xFFFFFFFF);
  static const Color darkBubbleReceived = Color(0xFF21262D);
  static const Color darkBubbleReceivedText = Color(0xFFF0F6FC);
  static const Color darkBubbleReceivedBorder = Color(0xFF30363D);

  static const Color darkOnlineDot = Color(0xFF3DD68C);
  static const Color darkDestructive = Color(0xFFFF453A);

  // ─── Brightness-aware helpers ───────────────────────────────────────────
  static Color accent(Brightness b) =>
      b == Brightness.dark ? darkAccent : lightAccent;
  static Color accentSoft(Brightness b) =>
      b == Brightness.dark ? darkAccentSoft : lightAccentSoft;
  static Color onlineDot(Brightness b) =>
      b == Brightness.dark ? darkOnlineDot : lightOnlineDot;
  static Color destructive(Brightness b) =>
      b == Brightness.dark ? darkDestructive : lightDestructive;
  static Color surfaceElevated(Brightness b) =>
      b == Brightness.dark ? darkSurfaceElevated : lightSurfaceElevated;
  static Color bubbleSent(Brightness b) =>
      b == Brightness.dark ? darkBubbleSent : lightBubbleSent;
  static Color bubbleSentText(Brightness b) =>
      b == Brightness.dark ? darkBubbleSentText : lightBubbleSentText;
  static Color bubbleReceived(Brightness b) =>
      b == Brightness.dark ? darkBubbleReceived : lightBubbleReceived;
  static Color bubbleReceivedText(Brightness b) =>
      b == Brightness.dark ? darkBubbleReceivedText : lightBubbleReceivedText;
  static Color bubbleReceivedBorder(Brightness b) =>
      b == Brightness.dark
          ? darkBubbleReceivedBorder
          : lightBubbleReceivedBorder;

  // ─── Avatar Palette (deterministic, hashCode % 10) ──────────────────────
  // Source: design-spec.md §5 — palet baru, kohesif dengan tema sapphire.
  static const List<Color> avatarPalette = [
    Color(0xFF0A84FF), // sapphire
    Color(0xFF34C759), // emerald
    Color(0xFFFF9F0A), // amber
    Color(0xFFFF375F), // rose
    Color(0xFF5E5CE6), // indigo
    Color(0xFF32ADE6), // sky
    Color(0xFFFF6B35), // tangerine
    Color(0xFF30D158), // mint
    Color(0xFFBF5AF2), // violet
    Color(0xFFAC8E68), // warm sand
  ];
}
