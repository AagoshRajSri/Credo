import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/enums.dart';
import '../../../data/providers/app_providers.dart';
import '../../../data/services/analytics_isolate.dart';
import '../../../shared/widgets/glass_card.dart';

/// Section on the Analytics screen for viewing and managing monthly category budgets.
class CategoryBudgetsSection extends ConsumerWidget {
  const CategoryBudgetsSection({super.key, required this.analytics});

  final AnalyticsResult analytics;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetsProvider);

    return budgetsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
        child: SizedBox(
          height: 120,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: CredoColors.accentViolet,
            ),
          ),
        ),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
        child: Text(
          'Failed to load budgets: $e',
          style: const TextStyle(color: CredoColors.error),
        ),
      ),
      data: (budgets) {
        // Map actual spend from analytics isolate result
        final spentMap = <TransactionCategory, double>{
          for (final item in analytics.categoryBreakdown) item.category: item.total,
        };

        // Total computations
        final totalBudget =
            budgets.values.fold<double>(0.0, (sum, val) => sum + val);
        final totalSpent = analytics.totalSpend;
        final overallProgress =
            totalBudget > 0 ? (totalSpent / totalBudget).clamp(0.0, 1.0) : 0.0;
        final isOverallExceeded = totalSpent > totalBudget;

        // Sort categories: active spending first (highest to lowest), then remaining
        final sortedCategories = List<TransactionCategory>.from(
          TransactionCategory.values,
        )..sort((a, b) {
            final spendA = spentMap[a] ?? 0.0;
            final spendB = spentMap[b] ?? 0.0;
            return spendB.compareTo(spendA);
          });

        return Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Overall Budget Overview Card ─────────────────────────────
              _OverallBudgetCard(
                totalSpent: totalSpent,
                totalBudget: totalBudget,
                progress: overallProgress,
                isExceeded: isOverallExceeded,
              ),
              const SizedBox(height: AppConstants.spacingM),

              // ── Category Budget Cards ────────────────────────────────────
              ...sortedCategories.map((category) {
                final spent = spentMap[category] ?? 0.0;
                final budget = budgets[category] ?? 5000.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppConstants.spacingS),
                  child: _CategoryBudgetCard(
                    category: category,
                    spent: spent,
                    budget: budget,
                    onTap: () => _showEditBudgetSheet(
                      context,
                      ref,
                      category,
                      budget,
                      spent,
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showEditBudgetSheet(
    BuildContext context,
    WidgetRef ref,
    TransactionCategory category,
    double currentBudget,
    double currentSpent,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: CredoColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return _EditBudgetBottomSheet(
          category: category,
          currentBudget: currentBudget,
          currentSpent: currentSpent,
        );
      },
    );
  }
}

// ── Overall Budget Card ───────────────────────────────────────────────────────
class _OverallBudgetCard extends StatelessWidget {
  const _OverallBudgetCard({
    required this.totalSpent,
    required this.totalBudget,
    required this.progress,
    required this.isExceeded,
  });

  final double totalSpent;
  final double totalBudget;
  final double progress;
  final bool isExceeded;

  @override
  Widget build(BuildContext context) {
    final percent = totalBudget > 0 ? ((totalSpent / totalBudget) * 100).round() : 0;
    final remaining = totalBudget - totalSpent;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: CredoColors.accentViolet.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: CredoColors.accentViolet,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Total Monthly Budget',
                    style: context.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isExceeded
                      ? CredoColors.error.withValues(alpha: 0.2)
                      : (percent >= 80
                          ? CredoColors.warning.withValues(alpha: 0.2)
                          : CredoColors.accentCyan.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$percent%',
                  style: TextStyle(
                    color: isExceeded
                        ? CredoColors.error
                        : (percent >= 80
                            ? CredoColors.warning
                            : CredoColors.accentCyan),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Numbers row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: CredoFormatters.rupees(totalSpent),
                      style: context.textTheme.headlineSmall?.copyWith(
                        color: CredoColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(
                      text: ' / ${CredoFormatters.rupees(totalBudget)}',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: CredoColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                isExceeded
                    ? '${CredoFormatters.rupees(remaining.abs())} over'
                    : '${CredoFormatters.rupees(remaining)} left',
                style: TextStyle(
                  color: isExceeded ? CredoColors.error : CredoColors.success,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Custom linear progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    color: CredoColors.surfaceHighlight,
                  ),
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: isExceeded
                            ? const LinearGradient(
                                colors: [CredoColors.error, Color(0xFFDC2626)],
                              )
                            : (percent >= 80
                                ? const LinearGradient(
                                    colors: [CredoColors.warning, Colors.orangeAccent],
                                  )
                                : CredoColors.accentGradient),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Category Budget Card ──────────────────────────────────────────────────────
class _CategoryBudgetCard extends StatelessWidget {
  const _CategoryBudgetCard({
    required this.category,
    required this.spent,
    required this.budget,
    required this.onTap,
  });

  final TransactionCategory category;
  final double spent;
  final double budget;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
    final percent = budget > 0 ? ((spent / budget) * 100).round() : 0;
    final isExceeded = spent > budget;
    final isWarning = !isExceeded && percent >= 80;
    final remaining = budget - spent;

    final statusColor = isExceeded
        ? CredoColors.error
        : (isWarning ? CredoColors.warning : CredoColors.accentCyan);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
      child: Container(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        decoration: BoxDecoration(
          color: CredoColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          border: Border.all(
            color: isExceeded
                ? CredoColors.error.withValues(alpha: 0.3)
                : Colors.transparent,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Emoji + Name, and Spent / Budget
            Row(
              children: [
                Text(
                  category.emoji,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    category.displayName,
                    style: context.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: CredoColors.textPrimary,
                    ),
                  ),
                ),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: CredoFormatters.rupees(spent),
                        style: const TextStyle(
                          color: CredoColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      TextSpan(
                        text: ' / ${CredoFormatters.rupees(budget)}',
                        style: const TextStyle(
                          color: CredoColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.edit_rounded,
                  size: 14,
                  color: CredoColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: SizedBox(
                height: 6,
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      color: CredoColors.surfaceHighlight,
                    ),
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Bottom metadata row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$percent% spent',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  isExceeded
                      ? '${CredoFormatters.rupees(remaining.abs())} over limit'
                      : '${CredoFormatters.rupees(remaining)} remaining',
                  style: TextStyle(
                    color: isExceeded
                        ? CredoColors.error
                        : CredoColors.textSecondary,
                    fontSize: 12,
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

// ── Interactive Edit Budget Bottom Sheet ──────────────────────────────────────
class _EditBudgetBottomSheet extends ConsumerStatefulWidget {
  const _EditBudgetBottomSheet({
    required this.category,
    required this.currentBudget,
    required this.currentSpent,
  });

  final TransactionCategory category;
  final double currentBudget;
  final double currentSpent;

  @override
  ConsumerState<_EditBudgetBottomSheet> createState() =>
      _EditBudgetBottomSheetState();
}

class _EditBudgetBottomSheetState
    extends ConsumerState<_EditBudgetBottomSheet> {
  late double _limit;
  late TextEditingController _textCtrl;

  @override
  void initState() {
    super.initState();
    _limit = widget.currentBudget;
    _textCtrl = TextEditingController(text: _limit.round().toString());
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  void _setLimit(double val) {
    setState(() {
      _limit = (val / 500).round() * 500.0;
      _textCtrl.text = _limit.round().toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppConstants.spacingM,
        AppConstants.spacingM,
        AppConstants.spacingM,
        AppConstants.spacingL + bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: CredoColors.textDisabled,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(
            children: [
              Text(widget.category.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.category.displayName} Budget',
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Current spend this month: ${CredoFormatters.rupees(widget.currentSpent)}',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: CredoColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Large Limit Display & Input
          Center(
            child: Column(
              children: [
                Text(
                  CredoFormatters.rupees(_limit),
                  style: context.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: CredoColors.accentCyan,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Monthly spending cap',
                  style: TextStyle(
                    color: CredoColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: CredoColors.accentViolet,
              inactiveTrackColor: CredoColors.surfaceHighlight,
              thumbColor: CredoColors.accentCyan,
              overlayColor: CredoColors.accentCyan.withValues(alpha: 0.15),
              trackHeight: 6,
            ),
            child: Slider(
              value: _limit.clamp(1000.0, 50000.0),
              min: 1000.0,
              max: 50000.0,
              divisions: 98, // 500 INR steps
              onChanged: _setLimit,
            ),
          ),

          // Quick Presets
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [5000.0, 8000.0, 12000.0, 15000.0, 20000.0, 25000.0]
                  .map((preset) {
                final isSelected = (_limit - preset).abs() < 250;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(CredoFormatters.rupees(preset)),
                    selected: isSelected,
                    selectedColor:
                        CredoColors.accentViolet.withValues(alpha: 0.3),
                    backgroundColor: CredoColors.surfaceHighlight,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? CredoColors.accentCyan
                          : CredoColors.textSecondary,
                      fontSize: 12,
                    ),
                    onSelected: (_) => _setLimit(preset),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 32),

          // Save Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: CredoColors.accentViolet,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              onPressed: () async {
                await ref
                    .read(budgetsProvider.notifier)
                    .updateBudget(widget.category, _limit);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Updated ${widget.category.displayName} budget to ${CredoFormatters.rupees(_limit)}',
                      ),
                      backgroundColor: CredoColors.surfaceHighlight,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: const Text(
                'Save Budget',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
