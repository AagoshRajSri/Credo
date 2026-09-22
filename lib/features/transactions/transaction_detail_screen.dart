import 'package:flutter/material.dart';
import '../../core/theme/color_tokens.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/extensions.dart';
import '../../data/models/transaction.dart';
import '../../shared/widgets/gradient_background.dart';

/// Full-screen transaction detail.
///
/// Phase 3: plain push navigation, static layout.
/// Phase 6: Hero tag wraps the amount + merchant icon, custom page route
///           provides shared-axis entrance.
class TransactionDetailScreen extends StatelessWidget {
  const TransactionDetailScreen({super.key, required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final color =
        transaction.isCredit ? CredoColors.success : CredoColors.error;

    return Scaffold(
      body: Stack(
        children: [
          const GradientBackground(),
          SafeArea(
            child: Column(
              children: [
                // ── App bar ──────────────────────────────────────────
                _DetailAppBar(transaction: transaction),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(AppConstants.spacingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: AppConstants.spacingL),

                        // ── Hero: emoji badge — destination ──────────────
                        // DECISION: only the icon Heroes. Amount skipped —
                        // titleSmall → displayMedium delta too large for a
                        // clean default cross-fade flight.
                        Hero(
                          tag: 'txn-icon-${transaction.id}',
                          flightShuttleBuilder: (
                            _,
                            animation,
                            direction,
                            fromCtx,
                            toCtx,
                          ) {
                            // Show destination widget fading in during
                            // flight — scales the large circle cleanly.
                            return FadeTransition(
                              opacity: animation,
                              child: toCtx.widget,
                            );
                          },
                          child: Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color.withValues(alpha: 0.12),
                              border: Border.all(
                                color: color.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                transaction.iconEmoji ??
                                    transaction.category.emoji,
                                style: const TextStyle(fontSize: 40),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: AppConstants.spacingM),

                        // ── Merchant name ────────────────────────────
                        Text(
                          transaction.merchant,
                          style: context.textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 6),

                        // ── Category chip ────────────────────────────
                        _CategoryChip(transaction: transaction),

                        const SizedBox(height: AppConstants.spacingXL),

                        // ── Hero: Amount ─────────────────────────────
                        // Phase 6: wrap in Hero(tag: 'txn-amount-${transaction.id}')
                        Text(
                          CredoFormatters.signedRupees(
                            transaction.amount,
                            isCredit: transaction.isCredit,
                          ),
                          style: context.textTheme.displayMedium?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: AppConstants.spacingXL),

                        // ── Metadata card ────────────────────────────
                        _MetadataCard(transaction: transaction),

                        if (transaction.note != null &&
                            transaction.note!.isNotEmpty) ...[
                          const SizedBox(height: AppConstants.spacingM),
                          _NoteCard(note: transaction.note!),
                        ],

                        const SizedBox(height: AppConstants.spacingXXL),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailAppBar extends StatelessWidget {
  const _DetailAppBar({required this.transaction});
  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingS,
        vertical: AppConstants.spacingXS,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Text(
            'Transaction',
            style: context.textTheme.titleLarge,
          ),
          const Spacer(),
          // Share / receipt placeholder
          IconButton(
            icon: const Icon(Icons.ios_share_outlined, size: 20),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.transaction});
  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: CredoColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
      ),
      child: Text(
        '${transaction.category.emoji}  ${transaction.category.displayName}',
        style: context.textTheme.labelMedium,
      ),
    );
  }
}

class _MetadataCard extends StatelessWidget {
  const _MetadataCard({required this.transaction});
  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: CredoColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
      ),
      child: Column(
        children: [
          _MetaRow(
            icon: Icons.calendar_today_outlined,
            label: 'Date',
            value: CredoFormatters.fullDateTime(transaction.date),
          ),
          const Divider(height: AppConstants.spacingL),
          _MetaRow(
            icon: Icons.account_balance_outlined,
            label: 'Account',
            value: transaction.accountId.replaceFirst('acc_', 'Account #'),
          ),
          const Divider(height: AppConstants.spacingL),
          _MetaRow(
            icon: Icons.swap_horiz_rounded,
            label: 'Type',
            value: transaction.isCredit ? 'Credit (Received)' : 'Debit (Paid)',
          ),
          const Divider(height: AppConstants.spacingL),
          _MetaRow(
            icon: Icons.tag_outlined,
            label: 'Reference',
            value: transaction.id.toUpperCase(),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: CredoColors.textSecondary),
        const SizedBox(width: 10),
        Text(
          label,
          style: context.textTheme.bodySmall
              ?.copyWith(color: CredoColors.textSecondary),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: context.textTheme.labelMedium?.copyWith(
              color: CredoColors.textPrimary,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note});
  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: CredoColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.notes_rounded,
              size: 16, color: CredoColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(note, style: context.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
