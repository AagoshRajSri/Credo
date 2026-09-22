import 'package:hive/hive.dart';
import '../models/transaction.dart';
import '../services/local_data_service.dart';

/// Box names — centralised so typos fail at compile time.
abstract final class HiveBoxNames {
  static const String accounts = 'accounts_box';
  static const String transactions = 'transactions_box';
  static const String scoreHistory = 'score_history_box';
  static const String appSettings = 'app_settings_box';
  static const String budgets = 'budgets_box';
  static const String savingsGoals = 'savings_goals_box';
}

/// Transactions repository.
///
/// Strategy: **asset-first, Hive-cache-write-through**.
/// - On first run (empty Hive box): load from JSON asset, seed into Hive.
/// - On subsequent runs: serve from Hive (fast, synchronous-ish).
/// - When a real backend is wired (future): swap the asset load for a
///   Dio call and keep the write-through pattern identical.
///
/// The "simulate offline" debug flag bypasses the asset load to prove
/// the Hive cache path works in isolation.
class TransactionsRepository {
  TransactionsRepository({bool simulateOffline = false})
      : _simulateOffline = simulateOffline;

  final bool _simulateOffline;

  Box<Transaction> get _box => Hive.box<Transaction>(HiveBoxNames.transactions);

  /// Returns all transactions, sorted newest-first.
  Future<List<Transaction>> getAll() async {
    // If the cache is populated, return it immediately.
    if (_box.isNotEmpty) {
      return _sortedFromCache();
    }

    // DECISION: If simulateOffline is on, return empty list instead of
    // loading from asset, to prove the empty-cache path works.
    if (_simulateOffline) {
      return [];
    }

    // First run — seed from JSON asset and cache in Hive.
    final fromAsset = await LocalDataService.loadTransactions();
    await _seedToHive(fromAsset);
    return _sortedFromCache();
  }

  /// Returns transactions for a specific [accountId].
  Future<List<Transaction>> getByAccount(String accountId) async {
    final all = await getAll();
    return all.where((t) => t.accountId == accountId).toList();
  }

  /// Clears the Hive cache (used in the debug "simulate offline" flow).
  Future<void> clearCache() => _box.clear();

  // ── Private helpers ────────────────────────────────────────────────
  List<Transaction> _sortedFromCache() {
    final items = _box.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  /// Adds a new transaction to the cache.
  Future<void> addTransaction(Transaction transaction) async {
    await _box.put(transaction.id, transaction);
  }

  /// Updates an existing transaction in the cache.
  Future<void> updateTransaction(Transaction transaction) async {
    if (_box.containsKey(transaction.id)) {
      await _box.put(transaction.id, transaction);
    }
  }

  /// Deletes a transaction from the cache by ID.
  Future<void> deleteTransaction(String id) async {
    await _box.delete(id);
  }

  Future<void> _seedToHive(List<Transaction> items) async {
    final map = {for (final t in items) t.id: t};
    await _box.putAll(map);
  }
}
