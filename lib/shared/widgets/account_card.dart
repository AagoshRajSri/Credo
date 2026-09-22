import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/color_tokens.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/account.dart';
import '../../data/models/enums.dart';

/// Premium glass account card — used on both the dashboard and accounts screen.
///
/// Phase 3: static glass card with account color tint.
/// Phase 5: adds tilt-on-drag parallax via pointer listener.
class AccountCard extends StatelessWidget {
  const AccountCard({
    super.key,
    required this.account,
    this.onTap,
    this.width = 300,
  });

  final Account account;
  final VoidCallback? onTap;
  final double width;

  Color get _cardColor {
    try {
      final hex = account.colorHex.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return CredoColors.accentViolet;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _cardColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: 172,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.radiusXL),
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.28),
              color.withValues(alpha: 0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: color.withValues(alpha: 0.35),
            width: AppConstants.glassBorderWidth,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppConstants.radiusXL),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: AppConstants.glassBlurSigma,
              sigmaY: AppConstants.glassBlurSigma,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header row ────────────────────────────────────────
                  Row(
                    children: [
                      _BankBadge(bankName: account.bankName, color: color),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              account.bankName,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: CredoColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              account.type.displayName,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: CredoColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      _StatusDot(color: color),
                    ],
                  ),
                  const Spacer(),

                  // ── Masked card number ────────────────────────────────
                  if (account.lastFourDigits != null)
                    Text(
                      '•••• •••• •••• ${account.lastFourDigits}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: CredoColors.textSecondary,
                            letterSpacing: 2,
                          ),
                    ),
                  const SizedBox(height: 6),

                  // ── Balance ───────────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              account.type == AccountType.credit
                                  ? 'Outstanding'
                                  : 'Balance',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color: CredoColors.textSecondary),
                            ),
                            Text(
                              CredoFormatters.rupees(account.balance),
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    color: account.balance < 0
                                        ? CredoColors.error
                                        : CredoColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        account.type == AccountType.credit
                            ? Icons.credit_card_outlined
                            : Icons.account_balance_outlined,
                        color: color.withValues(alpha: 0.7),
                        size: 22,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────

class _BankBadge extends StatelessWidget {
  const _BankBadge({required this.bankName, required this.color});
  final String bankName;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.2),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Center(
        child: Text(
          bankName.isNotEmpty ? bankName[0].toUpperCase() : '?',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6)],
      ),
    );
  }
}
