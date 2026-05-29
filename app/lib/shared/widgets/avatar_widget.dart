import 'package:flutter/material.dart';
import '../../core/theme/app_spacing.dart';
import '../utils/initials.dart';

/// Avatar lingkaran: emoji pilihan user (kalau ada), atau inisial deterministik.
///
/// Aturan (design-spec.md §5):
/// - Bentuk: lingkaran penuh
/// - Background: deterministik dari hash nama → konsisten lintas perangkat
/// - Emoji ditaruh di tengah; kalau kosong, pakai inisial 2 huruf
/// - Inner ring `2px solid rgba(255,255,255,0.3)` untuk kesan premium
class AvatarWidget extends StatelessWidget {
  const AvatarWidget({
    super.key,
    required this.name,
    this.emoji,
    this.size = AvatarSize.large,
    this.ringColor,
    this.ringWidth = 0,
  });

  final String name;

  /// Emoji avatar (1–2 karakter). Null/empty → fallback ke inisial.
  final String? emoji;
  final double size;

  /// Ring di LUAR avatar (mis. accent ring untuk profile screen).
  /// Default 0 = tanpa outer ring.
  final Color? ringColor;
  final double ringWidth;

  @override
  Widget build(BuildContext context) {
    final initials = Initials.from(name);
    final bgColor = Initials.colorFor(name);
    final hasEmoji = emoji != null && emoji!.isNotEmpty;

    final inner = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: hasEmoji
                ? Text(emoji!, style: TextStyle(fontSize: size * 0.5))
                : Text(
                    initials,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size * 0.4,
                      fontWeight: FontWeight.w600,
                      height: 1,
                    ),
                  ),
          ),
          // Inner ring rgba(255,255,255,0.3) — premium touch.
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
          ),
        ],
      ),
    );

    if (ringWidth > 0 && ringColor != null) {
      return Container(
        width: size + ringWidth * 2,
        height: size + ringWidth * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: ringColor!, width: ringWidth),
        ),
        padding: EdgeInsets.all(ringWidth),
        child: inner,
      );
    }

    return inner;
  }
}
