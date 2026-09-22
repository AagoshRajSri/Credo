/// App-wide constants — durations, radii, spacing, breakpoints.
/// All values are `const` so they can be used in `const` widget constructors.
abstract final class AppConstants {
  // ── Animation durations ───────────────────────────────────────────────
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 600);
  static const Duration durationVerySlow = Duration(milliseconds: 1200);

  /// Score gauge reveal duration — deliberately long for drama.
  static const Duration durationGaugeReveal = Duration(milliseconds: 1800);

  // ── Border radii ──────────────────────────────────────────────────────
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 14.0;
  static const double radiusLarge = 20.0;
  static const double radiusXL = 28.0;
  static const double radiusFull = 999.0;

  // ── Spacing / padding ─────────────────────────────────────────────────
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // ── Glass card ────────────────────────────────────────────────────────
  static const double glassBlurSigma = 12.0;
  static const double glassOpacity = 0.06;
  static const double glassBorderWidth = 0.8;

  // ── Bottom nav ────────────────────────────────────────────────────────
  static const double navBarHeight = 68.0;

  // ── Breakpoints ───────────────────────────────────────────────────────
  static const double breakpointTablet = 600.0;
  static const double breakpointDesktop = 1024.0;

  // ── Credit score ─────────────────────────────────────────────────────
  static const int scoreMin = 300;
  static const int scoreMax = 900;
  static const int scorePoor = 550;
  static const int scoreFair = 650;
  static const int scoreGood = 750;
  static const int scoreExcellent = 800;
}
