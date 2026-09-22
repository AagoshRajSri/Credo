import 'package:flutter/services.dart';

/// Thin wrapper around [HapticFeedback] so we can add a
/// "reduce motion" guard in Phase 9 without touching call sites.
///
/// Usage:
///   HapticService.light();   // e.g. button taps
///   HapticService.medium();  // e.g. gauge lands on score
///   HapticService.error();   // e.g. wrong PIN shake
abstract final class HapticService {
  static Future<void> light() => HapticFeedback.lightImpact();
  static Future<void> medium() => HapticFeedback.mediumImpact();
  static Future<void> heavy() => HapticFeedback.heavyImpact();
  static Future<void> error() => HapticFeedback.vibrate();
  static Future<void> selection() => HapticFeedback.selectionClick();
}
