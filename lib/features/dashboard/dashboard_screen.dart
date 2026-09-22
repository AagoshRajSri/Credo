import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/color_tokens.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/extensions.dart';
import '../../data/providers/app_providers.dart';
import '../../data/models/account.dart';
import '../../shared/widgets/gradient_background.dart';
import '../../shared/widgets/account_card.dart';
import '../../shared/widgets/transaction_row.dart';
import '../../shared/widgets/shimmer_widgets.dart';
import '../../shared/widgets/empty_state.dart';
import 'widgets/score_gauge.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/transaction-form'),
        backgroundColor: CredoColors.accentViolet,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: const Stack(
        children: [
          GradientBackground(),
          SafeArea(child: _DashboardBody()),
        ],
      ),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoreAsync = ref.watch(latestScoreProvider);
    final historyAsync = ref.watch(scoreHistoryProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final txnAsync = ref.watch(transactionsProvider);
    final rateAsync = ref.watch(exchangeRateProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(transactionsProvider);
        ref.invalidate(accountsProvider);
        ref.invalidate(exchangeRateProvider);
        ref.invalidate(latestScoreProvider);
        ref.invalidate(scoreHistoryProvider);
        await ref.read(transactionsProvider.future);
      },
      color: CredoColors.accentViolet,
      backgroundColor: CredoColors.surfaceVariant,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          // ── Header ──────────────────────────────────────────────────
          SliverToBoxAdapter(child: _Header(rateAsync: rateAsync)),

        // ── Credit Score Card ────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingM,
              vertical: AppConstants.spacingS,
            ),
            child: scoreAsync.when(
              loading: () => const GaugeShimmer(),
              error: (e, _) => const SizedBox.shrink(),
              data: (snapshot) => historyAsync.when(
                loading: () => const GaugeShimmer(),
                error: (e, _) => const SizedBox.shrink(),
                data: (history) {
                  if (snapshot == null || history.isEmpty) {
                    return const GaugeShimmer();
                  }
                  return ScoreGauge(
                    score: snapshot.score,
                    history: history,
                  );
                },
              ),
            ),
          ),
        ),

        // ── Accounts ─────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _SectionHeader(
            title: 'My Accounts',
            actionLabel: 'See all',
            onAction: () => context.go('/accounts'),
          ),
        ),
        SliverToBoxAdapter(
          child: accountsAsync.when(
            loading: () => const AccountCardShimmer(),
            error: (e, _) => const SizedBox(height: 80),
            data: (accounts) => _AccountsRow(accounts: accounts),
          ),
        ),

        // ── Recent Transactions ───────────────────────────────────────
        SliverToBoxAdapter(
          child: _SectionHeader(
            title: 'Recent',
            actionLabel: 'See all',
            onAction: () => context.go('/transactions'),
          ),
        ),
        txnAsync.when(
          loading: () => SliverList.builder(
            itemCount: 3,
            itemBuilder: (_, __) => const TransactionRowShimmer(),
          ),
          error: (e, _) => const SliverToBoxAdapter(
            child: ErrorState(message: 'Could not load transactions'),
          ),
          data: (txns) {
            final recent = txns.take(5).toList();
            if (recent.isEmpty) {
              return const SliverToBoxAdapter(
                child: EmptyState(
                  emoji: '💸',
                  title: 'No transactions yet',
                  subtitle: 'Your recent activity will appear here.',
                ),
              );
            }
            return SliverList.builder(
              itemCount: recent.length,
              itemBuilder: (context, i) {
                final txn = recent[i];
                return TransactionRow(
                  transaction: txn,
                  showDivider: i < recent.length - 1,
                  onTap: () => context.push(
                    '/transaction/${txn.id}',
                    extra: txn,
                  ),
                );
              },
            );
          },
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    ),
  );
  }
}

// ── Header ────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  const _Header({required this.rateAsync});
  final AsyncValue<double?> rateAsync;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spacingM,
        AppConstants.spacingL,
        AppConstants.spacingM,
        AppConstants.spacingS,
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                CredoFormatters.greeting(),
                style: context.textTheme.bodyMedium,
              ),
              Text(
                'Aagosh 👋',
                style: context.textTheme.headlineMedium,
              ),
            ],
          ),
          const Spacer(),
          // ── Live rate badge ─────────────────────────────────────
          rateAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (rate) => rate == null
                ? const SizedBox.shrink()
                : _LiveRateBadge(inrPerUsd: rate),
          ),
          const SizedBox(width: 8),
          // ── Settings gear ───────────────────────────────────────
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor: CredoColors.surfaceVariant,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppConstants.radiusMedium),
              ),
              fixedSize: const Size(40, 40),
              padding: EdgeInsets.zero,
            ),
            icon: const Icon(
              Icons.settings_outlined,
              size: 20,
              color: CredoColors.textPrimary,
            ),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
    );
  }
}

class _LiveRateBadge extends StatelessWidget {
  const _LiveRateBadge({required this.inrPerUsd});
  final double inrPerUsd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: CredoColors.successSurface,
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
        border: Border.all(
          color: CredoColors.success.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: CredoColors.success,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            // Source: open.er-api.com (live)
            '₹${inrPerUsd.toStringAsFixed(1)}/\$',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: CredoColors.success,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}


// ── Accounts row ──────────────────────────────────────────────────────────
class _AccountsRow extends StatelessWidget {
  const _AccountsRow({required this.accounts});
  final List<Account> accounts;

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) {
      return const SizedBox(
        height: 80,
        child: Center(
          child: Text('No accounts linked'),
        ),
      );
    }
    return SizedBox(
      height: 188,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingM,
          vertical: 8,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: accounts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => AccountCard(account: accounts[i]),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
  });
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spacingM,
        AppConstants.spacingL,
        AppConstants.spacingM,
        AppConstants.spacingXS,
      ),
      child: Row(
        children: [
          Text(title, style: context.textTheme.titleMedium),
          const Spacer(),
          if (actionLabel != null && onAction != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel!,
                style: context.textTheme.labelMedium?.copyWith(
                  color: CredoColors.accentViolet,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
