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
  final _searchController = TextEditingController();
  String _searchQuery = '';
  TransactionCategory? _selectedCategory;
  bool _onlyFavorites = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final txnAsync = ref.watch(transactionsProvider);

    return Scaffold(
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 120),
        child: FloatingActionButton(
          onPressed: () => context.push('/transaction-form'),
          backgroundColor: CredoColors.accentViolet,
          child: const Icon(Icons.add, color: Colors.white),
        ),
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

                // ── Search bar ───────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingM,
                  ),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: CredoColors.surfaceVariant,
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusMedium),
                      border: Border.all(
                        color: CredoColors.textDisabled,
                        width: 0.5,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) =>
                          setState(() => _searchQuery = val.trim().toLowerCase()),
                      style: const TextStyle(
                        color: CredoColors.textPrimary,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search merchant, note, amount...',
                        hintStyle: const TextStyle(
                          color: CredoColors.textSecondary,
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: CredoColors.textSecondary,
                          size: 20,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: CredoColors.textSecondary,
                                  size: 18,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.spacingS),

                // ── Category & Favorites filter chips ────────────────
                _CategoryFilterBar(
                  selected: _selectedCategory,
                  onlyFavorites: _onlyFavorites,
                  onSelected: (cat) => setState(() => _selectedCategory = cat),
                  onFavoritesToggled: () =>
                      setState(() => _onlyFavorites = !_onlyFavorites),
                ),
                const SizedBox(height: AppConstants.spacingS),

                // ── List with Pull-to-refresh ────────────────────────
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
                      final filtered = txns.where((t) {
                        if (_onlyFavorites && !t.isFavorite) return false;
                        if (_selectedCategory != null &&
                            t.category != _selectedCategory) {
                          return false;
                        }
                        if (_searchQuery.isNotEmpty) {
                          final matchesMerchant = t.merchant
                              .toLowerCase()
                              .contains(_searchQuery);
                          final matchesNote = t.note
                                  ?.toLowerCase()
                                  .contains(_searchQuery) ??
                              false;
                          final matchesCat = t.category.displayName
                              .toLowerCase()
                              .contains(_searchQuery);
                          final matchesAmt =
                              t.amount.toString().contains(_searchQuery);
                          if (!matchesMerchant &&
                              !matchesNote &&
                              !matchesCat &&
                              !matchesAmt) {
                            return false;
                          }
                        }
                        return true;
                      }).toList();

                      if (filtered.isEmpty) {
                        final hasFilter = _selectedCategory != null ||
                            _onlyFavorites ||
                            _searchQuery.isNotEmpty;
                        return EmptyState(
                          emoji: '🔍',
                          title: 'No matching transactions',
                          subtitle: hasFilter
                              ? 'Try adjusting your search or active filters.'
                              : 'Your transactions will appear here.',
                          action: hasFilter
                              ? () => setState(() {
                                    _selectedCategory = null;
                                    _onlyFavorites = false;
                                    _searchQuery = '';
                                    _searchController.clear();
                                  })
                              : null,
                          actionLabel: 'Clear filters',
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(transactionsProvider);
                          await ref.read(transactionsProvider.future);
                        },
                        color: CredoColors.accentViolet,
                        backgroundColor: CredoColors.surfaceVariant,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          padding: const EdgeInsets.only(bottom: 32),
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
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                              onDismissed: (direction) {
                                ref
                                    .read(transactionsProvider.notifier)
                                    .remove(txn.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Transaction deleted'),
                                  ),
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
                        ),
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
    required this.onlyFavorites,
    required this.onSelected,
    required this.onFavoritesToggled,
  });
  final TransactionCategory? selected;
  final bool onlyFavorites;
  final ValueChanged<TransactionCategory?> onSelected;
  final VoidCallback onFavoritesToggled;

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
            selected: selected == null && !onlyFavorites,
            onTap: () {
              onSelected(null);
              if (onlyFavorites) onFavoritesToggled();
            },
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: _FilterChip(
              label: 'Favorites',
              emoji: '⭐',
              selected: onlyFavorites,
              onTap: onFavoritesToggled,
            ),
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
