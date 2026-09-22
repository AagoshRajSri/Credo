import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/theme/color_tokens.dart';
import '../../core/utils/extensions.dart';

/// Ambient gradient background — 3 soft blurred colour blobs.
///
/// Phase 1 — static: blobs are fixed in position.
/// Phase 5 — each blob gets its own slow [AnimatedBuilder] loop so they drift
///            independently, creating a living atmosphere without triggering
///            unnecessary repaints of foreground content (wrapped in
///            [RepaintBoundary]).
///
/// Place this as the lowest layer in a [Stack] behind all foreground content.
///
/// ```dart
/// Stack(
///   children: [
///     const GradientBackground(),
///     YourForegroundContent(),
///   ],
/// )
/// ```
class GradientBackground extends StatefulWidget {
  const GradientBackground({super.key});

  @override
  State<GradientBackground> createState() => _GradientBackgroundState();
}

class _GradientBackgroundState extends State<GradientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion && _ctrl.isAnimating) {
      _ctrl.stop();
    } else if (!context.reduceMotion && !_ctrl.isAnimating) {
      _ctrl.repeat();
    }

    return RepaintBoundary(
      child: SizedBox.expand(
        child: Stack(
          children: [
            Container(color: CredoColors.background),
            AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) {
                final t = _ctrl.value;
                // Blob 1: slow circle
                final x1 = -0.8 + 0.15 * math.cos(2 * math.pi * t);
                final y1 = -0.7 + 0.15 * math.sin(2 * math.pi * t);
                
                // Blob 2: figure-8
                final x2 = 0.9 + 0.1 * math.sin(4 * math.pi * t);
                final y2 = 0.8 + 0.1 * math.sin(2 * math.pi * t);

                // Blob 3: reverse circle
                final x3 = 0.1 + 0.1 * math.cos(2 * math.pi * (1 - t));
                final y3 = 0.1 + 0.1 * math.sin(2 * math.pi * (1 - t));

                return Stack(
                  children: [
                    _GlowBlob(
                      color: CredoColors.accentViolet,
                      alignment: Alignment(x1, y1),
                      size: 320,
                      opacity: 0.18,
                    ),
                    _GlowBlob(
                      color: CredoColors.accentCyan,
                      alignment: Alignment(x2, y2),
                      size: 280,
                      opacity: 0.14,
                    ),
                    _GlowBlob(
                      color: CredoColors.accentMid,
                      alignment: Alignment(x3, y3),
                      size: 200,
                      opacity: 0.08,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// A single glowing radial-gradient blob.
class _GlowBlob extends StatelessWidget {
  const _GlowBlob({
    required this.color,
    required this.alignment,
    required this.size,
    required this.opacity,
  });

  final Color color;
  final Alignment alignment;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
