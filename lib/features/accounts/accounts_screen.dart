import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/color_tokens.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/extensions.dart';
import '../../data/providers/app_providers.dart';
import '../../data/models/account.dart';
import '../../data/models/enums.dart';
import '../../shared/widgets/gradient_background.dart';
import '../../shared/widgets/account_card.dart';
import '../../shared/widgets/shimmer_widgets.dart';
import '../../shared/widgets/empty_state.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      body: Stack(
        children: [
          GradientBackground(),
          SafeArea(child: _AccountsBody()),
        ],
      ),
    );
  }
}

class _AccountsBody extends ConsumerWidget {
  const _AccountsBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.spacingM,
              AppConstants.spacingL,
              AppConstants.spacingM,
              AppConstants.spacingM,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Accounts', style: context.textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text(
                  'Your linked bank accounts & cards',
                  style: context.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),

        // ── Accounts list ─────────────────────────────────────────────
        accountsAsync.when(
          loading: () => SliverList.builder(
            itemCount: 3,
            itemBuilder: (_, __) => const AccountCardShimmer(),
          ),
          error: (e, _) => SliverToBoxAdapter(
            child: ErrorState(
              message: e.toString(),
              onRetry: () => ref.invalidate(accountsProvider),
            ),
          ),
          data: (accounts) {
            if (accounts.isEmpty) {
              return const SliverToBoxAdapter(
                child: EmptyState(
                  emoji: '🏦',
                  title: 'No accounts yet',
                  subtitle:
                      'Link a bank account to see it here.',
                ),
              );
            }
            return SliverList.builder(
              itemCount: accounts.length,
              itemBuilder: (_, i) =>
                  _AccountListItem(account: accounts[i]),
            );
          },
        ),

        // ── Net Worth Summary ─────────────────────────────────────────
        accountsAsync.whenData((accounts) {
          if (accounts.isEmpty) return null;
          final netWorth = accounts.fold(0.0, (s, a) => s + a.balance);
          return _NetWorthCard(netWorth: netWorth, accounts: accounts);
        }).value != null
            ? SliverToBoxAdapter(
                child: accountsAsync.whenData((accounts) {
                  if (accounts.isEmpty) return const SizedBox.shrink();
                  final netWorth =
                      accounts.fold(0.0, (s, a) => s + a.balance);
                  return _NetWorthCard(
                    netWorth: netWorth,
                    accounts: accounts,
                  );
                }).value!,
              )
            : const SliverToBoxAdapter(child: SizedBox.shrink()),

        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

class _AccountListItem extends StatelessWidget {
  const _AccountListItem({required this.account});
  final Account account;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spacingM,
        0,
        AppConstants.spacingM,
        AppConstants.spacingM,
      ),
      child: AccountCard(
        account: account,
        width: double.infinity,
      ),
    );
  }
}

class _NetWorthCard extends StatelessWidget {
  const _NetWorthCard({
    required this.netWorth,
    required this.accounts,
  });
  final double netWorth;
  final List<Account> accounts;

  @override
  Widget build(BuildContext context) {
    final savings = accounts
        .where((a) =>
            a.type == AccountType.savings || a.type == AccountType.checking)
        .fold(0.0, (s, a) => s + a.balance);
    final credit = accounts
        .where((a) => a.type == AccountType.credit)
        .fold(0.0, (s, a) => s + a.balance);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingM,
        vertical: AppConstants.spacingS,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        decoration: BoxDecoration(
          color: CredoColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
          border: Border.all(
            color: CredoColors.accentViolet.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Net Worth', style: context.textTheme.labelMedium),
            const SizedBox(height: 4),
            Text(
              CredoFormatters.rupees(netWorth),
              style: context.textTheme.headlineSmall?.copyWith(
                color: netWorth >= 0
                    ? CredoColors.textPrimary
                    : CredoColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppConstants.spacingM),
            Row(
              children: [
                Expanded(
                  child: _NetWorthRow(
                    label: 'Savings',
                    amount: savings,
                    color: CredoColors.success,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingM),
                Expanded(
                  child: _NetWorthRow(
                    label: 'Credit Due',
                    amount: credit.abs(),
                    color: CredoColors.error,
                    isNegative: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NetWorthRow extends StatelessWidget {
  const _NetWorthRow({
    required this.label,
    required this.amount,
    required this.color,
    this.isNegative = false,
  });
  final String label;
  final double amount;
  final Color color;
  final bool isNegative;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: context.textTheme.bodySmall),
            Text(
              '${isNegative ? '−' : ''}${CredoFormatters.rupees(amount)}',
              style: context.textTheme.labelMedium
                  ?.copyWith(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }
}
