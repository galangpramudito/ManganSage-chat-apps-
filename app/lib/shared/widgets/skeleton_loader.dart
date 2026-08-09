import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Lightweight animated skeleton loader widget.
/// Provides smooth pulsing opacity effect for loading states without heavy dependencies.
class SkeletonLoader extends StatefulWidget {
  const SkeletonLoader({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = 4,
    this.margin,
  });

  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? AppColors.mono800 : AppColors.mono200;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          decoration: BoxDecoration(
            color: baseColor.withValues(alpha: _animation.value),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

/// Pre-built skeleton card representing a schedule or list item.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key, this.height = 72});
  final double height;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.mono900 : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: isDark ? AppColors.mono800 : AppColors.mono200),
      ),
      child: Row(
        children: [
          const SkeletonLoader(width: 36, height: 36, borderRadius: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                SkeletonLoader(width: 140, height: 14),
                SizedBox(height: 8),
                SkeletonLoader(width: 80, height: 10),
              ],
            ),
          ),
          const SkeletonLoader(width: 54, height: 20, borderRadius: 2),
        ],
      ),
    );
  }
}
