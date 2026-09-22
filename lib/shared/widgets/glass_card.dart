import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/color_tokens.dart';
import '../../core/constants/app_constants.dart';

/// A frosted-glass card used throughout the app.
///
/// Phase 1 — static version: correct blur, gradient border, inner shadow.
/// Phase 5 — adds tilt-parallax on pointer move and entrance animations.
///
/// Usage:
/// ```dart
/// GlassCard(
///   child: Text('Hello'),
/// )
/// ```
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppConstants.spacingM),
    this.borderRadius = AppConstants.radiusLarge,
    this.width,
    this.height,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: _GlassCardSurface(
        borderRadius: borderRadius,
        width: width,
        height: height,
        padding: padding,
        child: child,
      ),
    );
  }
}

class _GlassCardSurface extends StatelessWidget {
  const _GlassCardSurface({
    required this.child,
    required this.borderRadius,
    required this.padding,
    this.width,
    this.height,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: radius,
        // Gradient border simulated via a Container with gradient decoration
        // wrapping the card. The inner container provides the background.
        gradient: const LinearGradient(
          colors: [
            CredoColors.glassBorderStart,
            CredoColors.glassBorderEnd,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      // 1px border inset
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.glassBorderWidth),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            borderRadius - AppConstants.glassBorderWidth,
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: AppConstants.glassBlurSigma,
              sigmaY: AppConstants.glassBlurSigma,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: CredoColors.glassFill,
                borderRadius: BorderRadius.circular(
                  borderRadius - AppConstants.glassBorderWidth,
                ),
                // Subtle inner shadow to lift the card off the background
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x18000000),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Color(0x08FFFFFF),
                    blurRadius: 1,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              padding: padding,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
