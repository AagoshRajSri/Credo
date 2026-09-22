import 'package:hive/hive.dart';
import '../models/enums.dart';
import 'transactions_repository.dart';

/// Repository managing user-defined monthly category budgets.
///
/// Backed by Hive (`budgets_box`), mapping each `TransactionCategory`
/// string name to its allocated monthly limit (₹).
class BudgetRepository {
  Box<double> get _box => Hive.box<double>(HiveBoxNames.budgets);

  /// Sensible initial defaults in INR.
  static const Map<TransactionCategory, double> defaultBudgets = {
    TransactionCategory.food: 12000.0,
    TransactionCategory.shopping: 8000.0,
    TransactionCategory.entertainment: 5000.0,
    TransactionCategory.transport: 4000.0,
    TransactionCategory.utilities: 6000.0,
    TransactionCategory.health: 5000.0,
    TransactionCategory.travel: 10000.0,
    TransactionCategory.other: 3000.0,
  };

  /// Returns all category budgets. If uninitialized, seeds defaults.
  Future<Map<TransactionCategory, double>> getBudgets() async {
    final result = <TransactionCategory, double>{};

    for (final category in TransactionCategory.values) {
      final stored = _box.get(category.name);
      if (stored != null) {
        result[category] = stored;
      } else {
        final def = defaultBudgets[category] ?? 5000.0;
        await _box.put(category.name, def);
        result[category] = def;
      }
    }

    return result;
  }

  /// Sets or updates the budget limit for a specific category.
  Future<void> setBudget(TransactionCategory category, double limit) async {
    await _box.put(category.name, limit);
  }

  /// Resets all category budgets back to initial defaults.
  Future<Map<TransactionCategory, double>> resetDefaults() async {
    await _box.clear();
    for (final entry in defaultBudgets.entries) {
      await _box.put(entry.key.name, entry.value);
    }
    return Map.from(defaultBudgets);
  }
}
