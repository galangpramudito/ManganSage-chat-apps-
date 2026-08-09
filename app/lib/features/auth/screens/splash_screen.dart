import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Animated splash screen — logo Mangan dengan animasi draw stroke-by-stroke
/// + floating ambient + teks "MANGAN" fade-in (Montserrat Bold).
///
/// Timeline:
///   0.0–0.3s : Bowl/face shape draws
///   0.3–0.5s : Horizontal dividing line draws
///   0.5–1.0s : Fork prongs + base curve draw
///   1.0–1.5s : "MANGAN" text fades in
///   Terus    : Ambient float loop
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _drawController;
  late final AnimationController _floatController;
  late final AnimationController _textController;

  // Draw sub-animations (staggered).
  late final Animation<double> _bowlProgress;
  late final Animation<double> _lineProgress;
  late final Animation<double> _forkProgress;

  // Text fade.
  late final Animation<double> _textOpacity;

  // Ambient float.
  late final Animation<double> _floatOffset;
  
  // Timeout fallback
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    // Main draw: 2 seconds total, staggered.
    _drawController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Bowl: 0%–30%
    _bowlProgress = CurvedAnimation(
      parent: _drawController,
      curve: const Interval(0.0, 0.30, curve: Curves.easeInOut),
    );

    // Line: 25%–50%
    _lineProgress = CurvedAnimation(
      parent: _drawController,
      curve: const Interval(0.25, 0.50, curve: Curves.easeInOut),
    );

    // Fork: 45%–100%
    _forkProgress = CurvedAnimation(
      parent: _drawController,
      curve: const Interval(0.45, 1.0, curve: Curves.easeInOut),
    );

    // Ambient float: infinite loop.
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );
    _floatOffset = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(
        parent: _floatController,
        curve: Curves.easeInOut,
      ),
    );

    // Text fade-in: starts after draw finishes.
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _textOpacity = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeIn,
    );

    // Start the animation sequence.
    _drawController.forward();
    _floatController.repeat(reverse: true);

    // Fade text in after logo draw completes.
    _drawController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _textController.forward();
      }
    });

    // Fallback timeout: if auth takes > 5 seconds, navigate to login
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && !_navigated) {
        _navigated = true;
        context.go('/login');
      }
    });
  }

  @override
  void dispose() {
    _navigated = true;
    _drawController.dispose();
    _floatController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final bgColor = brightness == Brightness.dark
        ? const Color(0xFF0D1117)
        : const Color(0xFFF8F9FB);
    final strokeColor = brightness == Brightness.dark
        ? const Color(0xFFF0F6FC)
        : const Color(0xFF2D3132);
    final textColor = brightness == Brightness.dark
        ? const Color(0xFF6E7681)
        : const Color(0xFF8A94A6);

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo with ambient float.
            AnimatedBuilder(
              animation: Listenable.merge(
                  [_drawController, _floatController]),
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _floatOffset.value),
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child: CustomPaint(
                      painter: _ManganLogoPainter(
                        bowlProgress: _bowlProgress.value,
                        lineProgress: _lineProgress.value,
                        forkProgress: _forkProgress.value,
                        strokeColor: strokeColor,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            // "MANGAN" text with fade in.
            FadeTransition(
              opacity: _textOpacity,
              child: Text(
                'MANGAN',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: 6,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// CustomPainter yang menggambar logo Mangan (bowl + line + fork)
/// dengan animasi draw stroke berdasarkan progress 0.0–1.0.
class _ManganLogoPainter extends CustomPainter {
  _ManganLogoPainter({
    required this.bowlProgress,
    required this.lineProgress,
    required this.forkProgress,
    required this.strokeColor,
  });

  final double bowlProgress;
  final double lineProgress;
  final double forkProgress;
  final Color strokeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Scale the viewBox (500x400) to fit our widget size.
    // The logo group is translated to (140, 150) in the SVG.
    // Internal coords: 0–220 wide, -100 to 150 tall.
    // We'll normalize to fit the widget.
    final scaleX = size.width / 260; // some padding
    final scaleY = size.height / 260;
    final scale = math.min(scaleX, scaleY);
    final offsetX = (size.width - 220 * scale) / 2;
    final offsetY = (size.height - 200 * scale) / 2 + 40 * scale;

    canvas.save();
    canvas.translate(offsetX, offsetY);
    canvas.scale(scale);

    // ─── Bowl/Face Shape ────────────────────────────────────────────
    if (bowlProgress > 0) {
      final bowlPath = Path()
        ..moveTo(0, 0)
        ..lineTo(0, 60)
        ..cubicTo(0, 150, 220, 150, 220, 60)
        ..lineTo(220, 0)
        ..lineTo(170, 50)
        ..lineTo(50, 50)
        ..close();

      _drawPathProgress(canvas, bowlPath, paint, bowlProgress);
    }

    // ─── Horizontal Dividing Line ───────────────────────────────────
    if (lineProgress > 0) {
      final linePath = Path()
        ..moveTo(0, 50)
        ..lineTo(220, 50);

      _drawPathProgress(canvas, linePath, paint, lineProgress);
    }

    // ─── Fork Symbol ────────────────────────────────────────────────
    if (forkProgress > 0) {
      // Fork is centered at x=110, y=40 in the SVG local coords.
      canvas.save();
      canvas.translate(110, 40);

      // Center prong (handle).
      final centerProng = Path()
        ..moveTo(0, 0)
        ..lineTo(0, -100);
      _drawPathProgress(canvas, centerProng, paint, forkProgress);

      // Left prong.
      final leftProng = Path()
        ..moveTo(-35, -50)
        ..lineTo(-35, -100);
      _drawPathProgress(canvas, leftProng, paint, forkProgress);

      // Right prong.
      final rightProng = Path()
        ..moveTo(35, -50)
        ..lineTo(35, -100);
      _drawPathProgress(canvas, rightProng, paint, forkProgress);

      // Fork base curve.
      final baseCurve = Path()
        ..moveTo(-35, -50)
        ..cubicTo(-35, -20, 35, -20, 35, -50);
      _drawPathProgress(canvas, baseCurve, paint, forkProgress);

      canvas.restore();
    }

    canvas.restore();
  }

  /// Draw a partial path based on `progress` (0.0–1.0).
  void _drawPathProgress(
    Canvas canvas,
    Path path,
    Paint paint,
    double progress,
  ) {
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      final length = metric.length * progress;
      final extracted = metric.extractPath(0, length);
      canvas.drawPath(extracted, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ManganLogoPainter old) {
    return old.bowlProgress != bowlProgress ||
        old.lineProgress != lineProgress ||
        old.forkProgress != forkProgress ||
        old.strokeColor != strokeColor;
  }
}
