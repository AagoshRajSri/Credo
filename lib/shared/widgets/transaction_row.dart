import 'package:flutter/material.dart';
import '../../core/theme/color_tokens.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/transaction.dart';
import '../../data/models/enums.dart';

/// Reusable transaction row used in both the dashboard (recent) and
/// the full transactions list screen.
///
/// Phase 6: wraps key elements in matching [Hero] tags for the
/// shared-axis transition to [TransactionDetailScreen].
class TransactionRow extends StatelessWidget {
  const TransactionRow({
    super.key,
    required this.transaction,
    this.onTap,
    this.showDivider = true,
  });

  final Transaction transaction;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingM,
              vertical: 12,
            ),
            child: Row(
              children: [
                // ── Category emoji badge — Hero source ─────────────────
                // Phase 6: tag matches TransactionDetailScreen destination.
                Hero(
                  tag: 'txn-icon-${transaction.id}',
                  child: _CategoryBadge(transaction: transaction),
                ),
                const SizedBox(width: 12),

                // ── Merchant + category + date ─────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.merchant,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              color: CredoColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${transaction.category.displayName} · '
                        '${CredoFormatters.relativeDate(transaction.date)}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: CredoColors.textSecondary),
                      ),
                    ],
                  ),
                ),

                // ── Signed amount ──────────────────────────────────────
                Text(
                  CredoFormatters.signedRupees(
                    transaction.amount,
                    isCredit: transaction.isCredit,
                  ),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: transaction.isCredit
                            ? CredoColors.success
                            : CredoColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            indent: AppConstants.spacingM + 52,
            endIndent: AppConstants.spacingM,
            height: 1,
          ),
      ],
    );
  }
}

/// Circular badge showing the transaction's category emoji.
class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.transaction});
  final Transaction transaction;

  Color _badgeColor() {
    return switch (transaction.category) {
      TransactionCategory.food => const Color(0x22F59E0B),
      TransactionCategory.shopping => const Color(0x22EC4899),
      TransactionCategory.entertainment => const Color(0x227C3AED),
      TransactionCategory.transport => const Color(0x2206B6D4),
      TransactionCategory.utilities => const Color(0x223B82F6),
      TransactionCategory.health => const Color(0x2222C55E),
      TransactionCategory.travel => const Color(0x2214B8A6),
      TransactionCategory.other => const Color(0x2271717A),
    };
  }

  @override
  Widget build(BuildContext context) {
    final emoji = transaction.iconEmoji ?? transaction.category.emoji;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _badgeColor(),
      ),
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 20)),
      ),
    );
  }
}
