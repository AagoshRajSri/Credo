import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/color_tokens.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/extensions.dart';
import '../../data/providers/app_providers.dart';
import '../../data/models/enums.dart';
import '../../shared/widgets/gradient_background.dart';
import '../../shared/widgets/transaction_row.dart';
import '../../shared/widgets/shimmer_widgets.dart';
import '../../shared/widgets/empty_state.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() =>
      _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  TransactionCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final txnAsync = ref.watch(transactionsProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/transaction-form'),
        backgroundColor: CredoColors.accentViolet,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Stack(
        children: [
          const GradientBackground(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppConstants.spacingM,
                    AppConstants.spacingL,
                    AppConstants.spacingM,
                    AppConstants.spacingS,
                  ),
                  child: Text(
                    'Transactions',
                    style: context.textTheme.headlineMedium,
                  ),
                ),

                // ── Category filter chips ────────────────────────────
                _CategoryFilterBar(
                  selected: _selectedCategory,
                  onSelected: (cat) =>
                      setState(() => _selectedCategory = cat),
                ),
                const SizedBox(height: AppConstants.spacingS),

                // ── List ─────────────────────────────────────────────
                Expanded(
                  child: txnAsync.when(
                    loading: () => ListView.builder(
                      itemCount: 6,
                      itemBuilder: (_, __) => const TransactionRowShimmer(),
                    ),
                    error: (e, _) => ErrorState(
                      message: e.toString(),
                      onRetry: () => ref.invalidate(transactionsProvider),
                    ),
                    data: (txns) {
                      final filtered = _selectedCategory == null
                          ? txns
                          : txns
                              .where(
                                (t) => t.category == _selectedCategory,
                              )
                              .toList();

                      if (filtered.isEmpty) {
                        return EmptyState(
                          emoji: '🧾',
                          title: 'No transactions',
                          subtitle: _selectedCategory == null
                              ? 'Your transactions will appear here.'
                              : 'No ${_selectedCategory!.displayName} transactions found.',
                          action: _selectedCategory != null
                              ? () => setState(
                                    () => _selectedCategory = null,
                                  )
                              : null,
                          actionLabel: 'Clear filter',
                        );
                      }

                      return ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding:
                            const EdgeInsets.only(bottom: 32),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final txn = filtered[i];
                          return Dismissible(
                            key: ValueKey(txn.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 24),
                              color: CredoColors.error,
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            onDismissed: (direction) {
                              ref.read(transactionsProvider.notifier).remove(txn.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Transaction deleted')),
                              );
                            },
                            child: TransactionRow(
                              transaction: txn,
                              showDivider: i < filtered.length - 1,
                              onTap: () => context.push(
                                '/transaction/${txn.id}',
                                extra: txn,
                              ),
                            ),
                          );
                        },
                      );
                    },
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

// ── Category filter bar ───────────────────────────────────────────────────
class _CategoryFilterBar extends StatelessWidget {
  const _CategoryFilterBar({
    required this.selected,
    required this.onSelected,
  });
  final TransactionCategory? selected;
  final ValueChanged<TransactionCategory?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingM,
        ),
        children: [
          _FilterChip(
            label: 'All',
            emoji: '📋',
            selected: selected == null,
            onTap: () => onSelected(null),
          ),
          ...TransactionCategory.values.map(
            (cat) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _FilterChip(
                label: cat.displayName.split(' ').first,
                emoji: cat.emoji,
                selected: selected == cat,
                onTap: () =>
                    onSelected(selected == cat ? null : cat),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppConstants.durationFast,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? CredoColors.accentViolet
              : CredoColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppConstants.radiusFull),
          border: Border.all(
            color: selected
                ? CredoColors.accentViolet
                : CredoColors.textDisabled,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 5),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: selected
                        ? CredoColors.textPrimary
                        : CredoColors.textSecondary,
                    fontWeight: selected
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
