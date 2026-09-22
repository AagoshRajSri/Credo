import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/color_tokens.dart';
import '../../core/constants/app_constants.dart';

/// Shimmer loading placeholders.
///
/// Each placeholder matches the exact dimensions of the real widget it
/// replaces so there is no layout jump when real data loads.
/// Swapped in via `AsyncValue.when(loading: ...)` from Riverpod providers.
///
/// Phase 1 — widgets are defined here but not yet used in screens.
/// Phase 7 — integrate with AsyncValue.when in every screen.

// ── Base shimmer wrapper ──────────────────────────────────────────────────
class _CredoShimmer extends StatelessWidget {
  const _CredoShimmer({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: CredoColors.surfaceVariant,
      highlightColor: CredoColors.surfaceHighlight,
      child: child,
    );
  }
}

// ── Shimmer placeholder primitives ────────────────────────────────────────
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = AppConstants.radiusSmall,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return _CredoShimmer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

// ── Account card shimmer ──────────────────────────────────────────────────
/// Matches the real account card dimensions (see Phase 3).
class AccountCardShimmer extends StatelessWidget {
  const AccountCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return _CredoShimmer(
      child: Container(
        height: 160,
        width: double.infinity,
        margin: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingM,
          vertical: AppConstants.spacingS,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(AppConstants.radiusLarge),
        ),
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 80,
              height: 14,
              color: Colors.white,
            ),
            const SizedBox(height: AppConstants.spacingM),
            Container(
              width: 160,
              height: 24,
              color: Colors.white,
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(width: 60, height: 12, color: Colors.white),
                Container(width: 60, height: 12, color: Colors.white),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Transaction row shimmer ───────────────────────────────────────────────
class TransactionRowShimmer extends StatelessWidget {
  const TransactionRowShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return _CredoShimmer(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingM,
          vertical: AppConstants.spacingS,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppConstants.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: double.infinity,
                    color: Colors.white,
                  ),
                  const SizedBox(height: AppConstants.spacingXS),
                  Container(
                    height: 12,
                    width: 100,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppConstants.spacingM),
            Container(width: 60, height: 16, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

// ── Chart shimmer ─────────────────────────────────────────────────────────
class ChartShimmer extends StatelessWidget {
  const ChartShimmer({super.key, this.height = 200});
  final double height;

  @override
  Widget build(BuildContext context) {
    return _CredoShimmer(
      child: Container(
        height: height,
        width: double.infinity,
        margin: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingM,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        ),
      ),
    );
  }
}

// ── Gauge shimmer ─────────────────────────────────────────────────────────
class GaugeShimmer extends StatelessWidget {
  const GaugeShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return _CredoShimmer(
      child: Container(
        width: 220,
        height: 220,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
