import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../models/enums.dart';

// ── Input / output shapes ─────────────────────────────────────────────────

/// Input passed to the isolate — plain serialisable data only
/// (no Hive objects; those are converted to plain maps before calling compute).
class AnalyticsInput {
  const AnalyticsInput({required this.transactionMaps});
  final List<Map<String, dynamic>> transactionMaps;
}

/// Spend totalled by [TransactionCategory].
class CategorySpend {
  const CategorySpend({required this.category, required this.total});
  final TransactionCategory category;
  final double total;
}

/// Spend total for one calendar month.
class MonthlySpend {
  const MonthlySpend({
    required this.year,
    required this.month,
    required this.total,
  });
  final int year;
  final int month;
  final double total;

  String get label {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month - 1];
  }
}

/// Full analytics result returned from the isolate.
class AnalyticsResult {
  const AnalyticsResult({
    required this.categoryBreakdown,
    required this.monthlySpend,
    required this.totalSpend,
    required this.totalIncome,
  });

  final List<CategorySpend> categoryBreakdown;
  final List<MonthlySpend> monthlySpend;
  final double totalSpend;
  final double totalIncome;
}

// ── Isolate entry-point ───────────────────────────────────────────────────

/// Pure function run inside a [compute] isolate.
/// Must be a top-level function (not a closure) for [compute] to work.
///
/// Input: serialised transaction maps.
/// Output: fully computed [AnalyticsResult].
///
/// DECISION: We include only debit transactions in spend analytics;
/// credits are tracked separately as income.
AnalyticsResult _computeAnalytics(AnalyticsInput input) {
  final transactions = input.transactionMaps
      .map(Transaction.fromJson)
      .toList(growable: false);

  final debits = transactions.where((t) => !t.isCredit).toList();
  final credits = transactions.where((t) => t.isCredit).toList();

  // ── Category breakdown ──────────────────────────────────────────────
  final categoryMap = <TransactionCategory, double>{};
  for (final t in debits) {
    categoryMap[t.category] = (categoryMap[t.category] ?? 0) + t.amount;
  }
  final categoryBreakdown = categoryMap.entries
      .map((e) => CategorySpend(category: e.key, total: e.value))
      .toList()
    ..sort((a, b) => b.total.compareTo(a.total));

  // ── Monthly spend ───────────────────────────────────────────────────
  final monthMap = <String, double>{};
  for (final t in debits) {
    final key = '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}';
    monthMap[key] = (monthMap[key] ?? 0) + t.amount;
  }
  final monthlySpend = monthMap.entries.map((e) {
    final parts = e.key.split('-');
    return MonthlySpend(
      year: int.parse(parts[0]),
      month: int.parse(parts[1]),
      total: e.value,
    );
  }).toList()
    ..sort((a, b) {
      final aTime = DateTime(a.year, a.month);
      final bTime = DateTime(b.year, b.month);
      return aTime.compareTo(bTime);
    });

  final totalSpend = debits.fold(0.0, (sum, t) => sum + t.amount);
  final totalIncome = credits.fold(0.0, (sum, t) => sum + t.amount);

  return AnalyticsResult(
    categoryBreakdown: categoryBreakdown,
    monthlySpend: monthlySpend,
    totalSpend: totalSpend,
    totalIncome: totalIncome,
  );
}

// ── Public API ────────────────────────────────────────────────────────────

/// Computes analytics from a list of [Transaction] objects.
/// Runs in a separate isolate via [compute] so the UI thread is never blocked.
///
/// Example:
/// ```dart
/// final result = await AnalyticsIsolate.compute(transactions);
/// ```
abstract final class AnalyticsIsolate {
  static Future<AnalyticsResult> run(List<Transaction> transactions) async {
    final watch = Stopwatch()..start();
    final maps = transactions.map((t) => t.toJson()).toList(growable: false);
    debugPrint('[AnalyticsIsolate] Serialized ${transactions.length} txns in ${watch.elapsedMilliseconds}ms');

    final computeWatch = Stopwatch()..start();
    final result = await compute(
      _computeAnalytics,
      AnalyticsInput(transactionMaps: maps),
    );
    debugPrint('[AnalyticsIsolate] compute() finished in ${computeWatch.elapsedMilliseconds}ms');
    
    return result;
  }
}
