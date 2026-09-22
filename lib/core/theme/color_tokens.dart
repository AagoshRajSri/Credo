// Color tokens for the Credo design system.
// Based on a deep charcoal/black base with a violet → cyan accent gradient.
import 'package:flutter/material.dart';

/// Core palette — all values are `const` so they can be used in
/// `const` widget constructors throughout the app.
abstract final class CredoColors {
  // ── Base surfaces ───────────────────────────────────────────────────
  static const Color background = Color(0xFF0A0A0F);
  static const Color surface = Color(0xFF12121A);
  static const Color surfaceVariant = Color(0xFF1A1A26);
  static const Color surfaceHighlight = Color(0xFF22223A);

  // ── Glass overlay ────────────────────────────────────────────────────
  /// Use as fill on glass cards (BackdropFilter).
  static const Color glassFill = Color(0x0FFFFFFF);
  static const Color glassBorderStart = Color(0x30FFFFFF);
  static const Color glassBorderEnd = Color(0x08FFFFFF);

  // ── Accent gradient: violet → cyan ───────────────────────────────────
  static const Color accentViolet = Color(0xFF7C3AED);
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color accentMid = Color(0xFF3B82F6); // midpoint blue

  // ── Text ─────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF4F4F5);
  static const Color textSecondary = Color(0xFF71717A);
  static const Color textTertiary = Color(0xFF3F3F46);
  static const Color textDisabled = Color(0xFF27272A);

  // ── Semantic ─────────────────────────────────────────────────────────
  static const Color error = Color(0xFFEF4444);
  static const Color errorSurface = Color(0x22EF4444);
  static const Color success = Color(0xFF22C55E);
  static const Color successSurface = Color(0x2222C55E);
  static const Color warning = Color(0xFFF59E0B);

  // ── Chart palette ────────────────────────────────────────────────────
  static const List<Color> chartPalette = [
    Color(0xFF7C3AED), // violet
    Color(0xFF06B6D4), // cyan
    Color(0xFF3B82F6), // blue
    Color(0xFF22C55E), // green
    Color(0xFFF59E0B), // amber
    Color(0xFFEC4899), // pink
    Color(0xFF14B8A6), // teal
  ];

  // ── Gradient helpers ─────────────────────────────────────────────────
  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentViolet, accentCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradientVertical = LinearGradient(
    colors: [accentViolet, accentCyan],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient glassBorderGradient = LinearGradient(
    colors: [glassBorderStart, glassBorderEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
