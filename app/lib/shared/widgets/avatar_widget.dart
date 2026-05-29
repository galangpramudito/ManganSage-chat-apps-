import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_spacing.dart';
import '../utils/initials.dart';

/// Avatar lingkaran dengan inisial deterministik (atau foto profil bila ada).
///
/// Aturan (design-spec.md §5):
/// - Bentuk: lingkaran penuh
/// - Inisial: 2 huruf (1 huruf untuk nama 1 kata)
/// - Background: deterministik dari hash nama → konsisten lintas perangkat
/// - Inner ring `2px solid rgba(255,255,255,0.3)` untuk kesan premium
/// - Teks inisial putih
class AvatarWidget extends StatelessWidget {
  const AvatarWidget({
    super.key,
    required this.name,
    this.photoUrl,
    this.size = AvatarSize.large,
    this.ringColor,
    this.ringWidth = 0,
  });

  final String name;
  final String? photoUrl;
  final double size;

  /// Ring di LUAR avatar (mis. accent ring untuk profile screen).
  /// Default 0 = tanpa outer ring.
  final Color? ringColor;
  final double ringWidth;

  @override
  Widget build(BuildContext context) {
    final initials = Initials.from(name);
    final bgColor = Initials.colorFor(name);

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
          // Foto atau inisial.
          photoUrl != null && photoUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: photoUrl!,
                  fit: BoxFit.cover,
                  fadeInDuration: const Duration(milliseconds: 200),
                  placeholder: (_, _) => _initialsLayer(initials),
                  errorWidget: (_, _, _) => _initialsLayer(initials),
                )
              : _initialsLayer(initials),
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

  Widget _initialsLayer(String initials) {
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.4,
          fontWeight: FontWeight.w600,
          height: 1,
        ),
      ),
    );
  }
}
