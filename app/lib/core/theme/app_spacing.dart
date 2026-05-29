/// Design tokens — spacing & radius
/// Source: design-spec.md §9 (Spacing & Layout System)
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

class AppRadius {
  AppRadius._();

  static const double bubble = 20;
  static const double input = 24;
  static const double card = 12;
  static const double badge = 10;
  // avatar = 50% (lingkaran penuh) — gunakan BoxShape.circle di widget
}

/// Avatar size — design-spec.md §5
class AvatarSize {
  AvatarSize._();

  /// Daftar kontak / Inbox
  static const double large = 48;

  /// Di dalam chat room
  static const double small = 28;

  /// Layar Profil — hero avatar
  static const double profile = 88;
}
