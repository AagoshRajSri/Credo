import 'package:flutter/material.dart';
import '../theme/color_tokens.dart';

/// Convenience extensions on [BuildContext] so widgets can access
/// theme data, size info, and responsive helpers without ceremony.
extension BuildContextX on BuildContext {
  // ── Theme shortcuts ────────────────────────────────────────────────
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  // ── Screen size ───────────────────────────────────────────────────
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  // ── Responsive helpers ────────────────────────────────────────────
  bool get isTablet => screenWidth >= 600;
  bool get isDesktop => screenWidth >= 1024;

  // ── Motion preference ─────────────────────────────────────────────
  /// True when the user has enabled "reduce motion" in system settings.
  /// All animated widgets should check this and jump to final state when true.
  bool get reduceMotion => MediaQuery.of(this).disableAnimations;

  // ── Padding / insets ──────────────────────────────────────────────
  EdgeInsets get viewPadding => MediaQuery.viewPaddingOf(this);
  double get bottomPadding => MediaQuery.viewPaddingOf(this).bottom;
  double get topPadding => MediaQuery.viewPaddingOf(this).top;
}

/// Convenience extensions on [Color].
extension ColorX on Color {
  /// Returns this color with the given opacity multiplied into its alpha.
  Color withOpacityValue(double opacity) =>
      withValues(alpha: opacity);
}

/// Convenience extensions on [num] for spacing.
extension CredoSpacing on num {
  SizedBox get vSpace => SizedBox(height: toDouble());
  SizedBox get hSpace => SizedBox(width: toDouble());
}

/// Formats a credit score into a human-readable label.
String creditScoreLabel(int score) {
  if (score >= 800) return 'Excellent';
  if (score >= 750) return 'Good';
  if (score >= 650) return 'Fair';
  return 'Poor';
}

/// Returns the accent color appropriate for a given credit score.
Color creditScoreColor(int score) {
  if (score >= 750) return CredoColors.success;
  if (score >= 650) return CredoColors.warning;
  return CredoColors.error;
}
