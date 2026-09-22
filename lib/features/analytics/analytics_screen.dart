import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/color_tokens.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/extensions.dart';
import '../../data/providers/app_providers.dart';
import '../../data/services/analytics_isolate.dart';
import '../../shared/widgets/gradient_background.dart';
import '../../shared/widgets/shimmer_widgets.dart';
import '../../shared/widgets/empty_state.dart';
import 'widgets/category_budgets_section.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      body: Stack(
        children: [
          GradientBackground(),
          SafeArea(child: _AnalyticsBody()),
        ],
      ),
    );
  }
}

class _AnalyticsBody extends ConsumerWidget {
  const _AnalyticsBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(analyticsProvider);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.spacingM,
              AppConstants.spacingL,
              AppConstants.spacingM,
              AppConstants.spacingS,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Analytics', style: context.textTheme.headlineMedium),
                Text(
                  'Spending insights · Sep 2026',
                  style: context.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),

        analyticsAsync.when(
          loading: () => const SliverToBoxAdapter(
            child: Column(
              children: [
                ChartShimmer(height: 280),
                SizedBox(height: AppConstants.spacingL),
                ChartShimmer(height: 220),
              ],
            ),
          ),
          error: (e, _) => SliverToBoxAdapter(
            child: ErrorState(
              message: e.toString(),
              onRetry: () => ref.invalidate(analyticsProvider),
            ),
          ),
          data: (analytics) {
            if (analytics.categoryBreakdown.isEmpty) {
              return const SliverToBoxAdapter(
                child: EmptyState(
                  emoji: '📊',
                  title: 'No spending data yet',
                  subtitle: 'Transactions will appear here once recorded.',
                ),
              );
            }

            return SliverList.list(
              children: [
                // ── Summary row ─────────────────────────────────────
                _SummaryRow(analytics: analytics),
                const SizedBox(height: AppConstants.spacingM),

                // ── Donut chart — spend by category ─────────────────
                const _SectionTitle(title: 'Spend by Category'),
                _DonutChart(analytics: analytics),
                const SizedBox(height: AppConstants.spacingL),

                // ── Monthly Category Budgets ─────────────────────────
                const _SectionTitle(title: 'Monthly Category Budgets'),
                CategoryBudgetsSection(analytics: analytics),
                const SizedBox(height: AppConstants.spacingL),

                // ── Bar chart — monthly spend ────────────────────────
                const _SectionTitle(title: 'Monthly Spend'),
                _MonthlyBarChart(analytics: analytics),
                const SizedBox(height: 48),
              ],
            );
          },
        ),
      ],
    );
  }
}

// ── Summary row ───────────────────────────────────────────────────────────
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.analytics});
  final AnalyticsResult analytics;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              label: 'Total Spent',
              value: CredoFormatters.rupees(analytics.totalSpend),
              icon: Icons.arrow_upward_rounded,
              color: CredoColors.error,
            ),
          ),
          const SizedBox(width: AppConstants.spacingM),
          Expanded(
            child: _SummaryCard(
              label: 'Total Income',
              value: CredoFormatters.rupees(analytics.totalIncome),
              icon: Icons.arrow_downward_rounded,
              color: CredoColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: CredoColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: context.textTheme.bodySmall),
                Text(
                  value,
                  style: context.textTheme.titleSmall?.copyWith(
                    color: CredoColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Donut chart ───────────────────────────────────────────────────────────
class _DonutChart extends StatelessWidget {
  const _DonutChart({required this.analytics});
  final AnalyticsResult analytics;

  @override
  Widget build(BuildContext context) {
    final breakdown = analytics.categoryBreakdown.take(6).toList();
    const palette = CredoColors.chartPalette;

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingM,
        ),
        padding: const EdgeInsets.all(AppConstants.spacingM),
        decoration: BoxDecoration(
          color: CredoColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppConstants.radiusXL),
        ),
        child: Column(
          children: [
            // ── Donut + center label ─────────────────────────────
            SizedBox(
              height: 200,
              child: Semantics(
                label: 'Donut chart showing spending breakdown. Top category is ${breakdown.first.category.displayName} at \$${breakdown.first.total.toStringAsFixed(0)}.',
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sections: breakdown.asMap().entries.map((e) {
                          final i = e.key;
                          final cat = e.value;
                          return PieChartSectionData(
                            value: cat.total,
                            color: palette[i % palette.length],
                            radius: 56,
                            title: '',
                            showTitle: false,
                          );
                        }).toList(),
                        centerSpaceRadius: 56,
                        sectionsSpace: 3,
                        startDegreeOffset: -90,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Spent',
                          style: context.textTheme.bodySmall
                              ?.copyWith(color: CredoColors.textSecondary),
                        ),
                        Text(
                          CredoFormatters.rupeesCompact(analytics.totalSpend),
                          style: context.textTheme.titleMedium?.copyWith(
                            color: CredoColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spacingM),
            // ── Legend ──────────────────────────────────────────
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: breakdown.asMap().entries.map((e) {
                final i = e.key;
                final cat = e.value;
                final pct =
                    ((cat.total / analytics.totalSpend) * 100)
                        .toStringAsFixed(0);
                return _LegendItem(
                  color: palette[i % palette.length],
                  label: cat.category.displayName.split(' ').first,
                  pct: '$pct%',
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.pct,
  });
  final Color color;
  final String label;
  final String pct;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label ($pct)',
          style: context.textTheme.bodySmall
              ?.copyWith(color: CredoColors.textSecondary),
        ),
      ],
    );
  }
}

// ── Monthly bar chart ─────────────────────────────────────────────────────
class _MonthlyBarChart extends StatelessWidget {
  const _MonthlyBarChart({required this.analytics});
  final AnalyticsResult analytics;

  @override
  Widget build(BuildContext context) {
    final months = analytics.monthlySpend;
    if (months.isEmpty) return const SizedBox.shrink();

    final maxY = months
        .map((m) => m.total)
        .reduce((a, b) => a > b ? a : b);

    return RepaintBoundary(
      child: Container(
        height: 240,
        margin: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingM,
        ),
        padding: const EdgeInsets.fromLTRB(
          AppConstants.spacingM,
          AppConstants.spacingM,
          AppConstants.spacingM,
          AppConstants.spacingXS,
        ),
        decoration: BoxDecoration(
          color: CredoColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppConstants.radiusXL),
        ),
        child: BarChart(
          BarChartData(
            maxY: maxY * 1.25,
            barGroups: months.asMap().entries.map((e) {
              final i = e.key;
              final m = e.value;
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: m.total,
                    gradient: const LinearGradient(
                      colors: [
                        CredoColors.accentViolet,
                        CredoColors.accentCyan,
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                    width: 22,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6),
                    ),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: maxY * 1.25,
                      color: CredoColors.surfaceHighlight,
                    ),
                  ),
                ],
              );
            }).toList(),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    if (i >= 0 && i < months.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          months[i].label,
                          style: context.textTheme.labelSmall?.copyWith(
                            color: CredoColors.textSecondary,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => const FlLine(
                color: CredoColors.textDisabled,
                strokeWidth: 0.5,
              ),
            ),
            borderData: FlBorderData(show: false),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => CredoColors.surface,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final m = months[group.x];
                  return BarTooltipItem(
                    '${m.label}\n',
                    const TextStyle(
                      color: CredoColors.textSecondary,
                      fontSize: 11,
                    ),
                    children: [
                      TextSpan(
                        text: CredoFormatters.rupeesCompact(rod.toY),
                        style: const TextStyle(
                          color: CredoColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spacingM,
        AppConstants.spacingS,
        AppConstants.spacingM,
        AppConstants.spacingS,
      ),
      child: Text(title, style: context.textTheme.titleMedium),
    );
  }
}
