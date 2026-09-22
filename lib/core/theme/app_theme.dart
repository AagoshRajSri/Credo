import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'color_tokens.dart';

/// The single source of truth for all Credo theme configuration.
/// Call [CredoTheme.dark] to get the [ThemeData] for the app.
abstract final class CredoTheme {
  // ── Type scale ───────────────────────────────────────────────────────
  // Display / headlines: Space Grotesk (bold, impactful)
  // Body / labels:       Inter (clean, legible at small sizes)

  static TextTheme _buildTextTheme() {
    final spaceGrotesk = GoogleFonts.spaceGroteskTextTheme();
    final inter = GoogleFonts.interTextTheme();

    return TextTheme(
      // Display — score numbers, hero headings
      displayLarge: spaceGrotesk.displayLarge?.copyWith(
        color: CredoColors.textPrimary,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.5,
      ),
      displayMedium: spaceGrotesk.displayMedium?.copyWith(
        color: CredoColors.textPrimary,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.0,
      ),
      displaySmall: spaceGrotesk.displaySmall?.copyWith(
        color: CredoColors.textPrimary,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      // Headlines — section titles, card headings
      headlineLarge: spaceGrotesk.headlineLarge?.copyWith(
        color: CredoColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: spaceGrotesk.headlineMedium?.copyWith(
        color: CredoColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: spaceGrotesk.headlineSmall?.copyWith(
        color: CredoColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      // Title — app bars, dialog titles
      titleLarge: inter.titleLarge?.copyWith(
        color: CredoColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: inter.titleMedium?.copyWith(
        color: CredoColors.textPrimary,
        fontWeight: FontWeight.w500,
      ),
      titleSmall: inter.titleSmall?.copyWith(
        color: CredoColors.textSecondary,
        fontWeight: FontWeight.w500,
      ),
      // Body — primary content
      bodyLarge: inter.bodyLarge?.copyWith(
        color: CredoColors.textPrimary,
      ),
      bodyMedium: inter.bodyMedium?.copyWith(
        color: CredoColors.textSecondary,
      ),
      bodySmall: inter.bodySmall?.copyWith(
        color: CredoColors.textTertiary,
        fontSize: 12,
      ),
      // Label — chips, tags, overlines
      labelLarge: inter.labelLarge?.copyWith(
        color: CredoColors.textPrimary,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
      labelMedium: inter.labelMedium?.copyWith(
        color: CredoColors.textSecondary,
        letterSpacing: 0.5,
      ),
      labelSmall: inter.labelSmall?.copyWith(
        color: CredoColors.textTertiary,
        letterSpacing: 1.0,
      ),
    );
  }

  static ThemeData get dark {
    final textTheme = _buildTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: CredoColors.background,
      colorScheme: const ColorScheme.dark(
        brightness: Brightness.dark,
        primary: CredoColors.accentViolet,
        onPrimary: CredoColors.textPrimary,
        secondary: CredoColors.accentCyan,
        onSecondary: CredoColors.textPrimary,
        surface: CredoColors.surface,
        onSurface: CredoColors.textPrimary,
        error: CredoColors.error,
        onError: CredoColors.textPrimary,
      ),
      textTheme: textTheme,
      // ── AppBar ────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        iconTheme: const IconThemeData(color: CredoColors.textPrimary),
      ),
      // ── Navigation bar (bottom nav) ───────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: CredoColors.surface,
        indicatorColor: CredoColors.accentViolet.withValues(alpha: 0.2),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: CredoColors.accentViolet,
              size: 24,
            );
          }
          return const IconThemeData(
            color: CredoColors.textSecondary,
            size: 24,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return textTheme.labelSmall?.copyWith(
              color: CredoColors.accentViolet,
              fontWeight: FontWeight.w600,
            );
          }
          return textTheme.labelSmall?.copyWith(
            color: CredoColors.textSecondary,
          );
        }),
        elevation: 0,
        height: 68,
      ),
      // ── Card ──────────────────────────────────────────────────────────
      cardTheme: const CardThemeData(
        color: CredoColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      // ── Divider ───────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: CredoColors.textDisabled,
        thickness: 0.5,
        space: 1,
      ),
      // ── Icon ─────────────────────────────────────────────────────────
      iconTheme: const IconThemeData(
        color: CredoColors.textSecondary,
        size: 20,
      ),
      // ── Input / text fields ───────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CredoColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: CredoColors.textDisabled,
            width: 0.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CredoColors.accentViolet),
        ),
        hintStyle: textTheme.bodyMedium,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      // ── Elevated button ───────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: CredoColors.accentViolet,
          foregroundColor: CredoColors.textPrimary,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
          textStyle: textTheme.labelLarge,
        ),
      ),
      // ── Page transitions ──────────────────────────────────────────────
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
