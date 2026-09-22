import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/transactions_repository.dart';
import '../repositories/accounts_repository.dart';
import '../repositories/credit_score_repository.dart';
import '../repositories/budget_repository.dart';
import '../repositories/savings_goal_repository.dart';
import '../models/transaction.dart';
import '../models/savings_goal.dart';
import '../models/account.dart';
import '../models/credit_score_snapshot.dart';
import '../models/enums.dart';
import '../services/analytics_isolate.dart';
import '../services/exchange_rate_service.dart';

// ── Debug: simulate offline ───────────────────────────────────────────────

/// Toggling this to `true` clears all Hive caches and prevents asset loading,
/// proving the offline fallback path.  Flip it via the debug drawer in Phase 9.
final simulateOfflineProvider = StateProvider<bool>((ref) => false);

// ── Repository providers ──────────────────────────────────────────────────

final transactionsRepositoryProvider = Provider<TransactionsRepository>((ref) {
  final offline = ref.watch(simulateOfflineProvider);
  return TransactionsRepository(simulateOffline: offline);
});

final accountsRepositoryProvider = Provider<AccountsRepository>((ref) {
  final offline = ref.watch(simulateOfflineProvider);
  return AccountsRepository(simulateOffline: offline);
});

final creditScoreRepositoryProvider = Provider<CreditScoreRepository>((ref) {
  final offline = ref.watch(simulateOfflineProvider);
  return CreditScoreRepository(simulateOffline: offline);
});

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository();
});

final savingsGoalRepositoryProvider = Provider<SavingsGoalRepository>((ref) {
  return SavingsGoalRepository();
});

// ── Data providers ────────────────────────────────────────────────────────

/// Monthly category budgets notifier.
class BudgetsNotifier extends AsyncNotifier<Map<TransactionCategory, double>> {
  @override
  Future<Map<TransactionCategory, double>> build() async {
    final repo = ref.watch(budgetRepositoryProvider);
    return repo.getBudgets();
  }

  Future<void> updateBudget(TransactionCategory category, double limit) async {
    final repo = ref.read(budgetRepositoryProvider);
    await repo.setBudget(category, limit);
    state = AsyncData(await repo.getBudgets());
  }

  Future<void> resetToDefaults() async {
    final repo = ref.read(budgetRepositoryProvider);
    final defaults = await repo.resetDefaults();
    state = AsyncData(defaults);
  }
}

final budgetsProvider =
    AsyncNotifierProvider<BudgetsNotifier, Map<TransactionCategory, double>>(() {
  return BudgetsNotifier();
});

/// Savings goals notifier.
class SavingsGoalsNotifier extends AsyncNotifier<List<SavingsGoal>> {
  @override
  Future<List<SavingsGoal>> build() async {
    final repo = ref.watch(savingsGoalRepositoryProvider);
    return repo.getAllGoals();
  }

  Future<void> add(SavingsGoal goal) async {
    final repo = ref.read(savingsGoalRepositoryProvider);
    await repo.addGoal(goal);
    state = AsyncData(await repo.getAllGoals());
  }

  Future<void> updateGoal(SavingsGoal goal) async {
    final repo = ref.read(savingsGoalRepositoryProvider);
    await repo.updateGoal(goal);
    state = AsyncData(await repo.getAllGoals());
  }

  Future<void> remove(String id) async {
    final repo = ref.read(savingsGoalRepositoryProvider);
    await repo.deleteGoal(id);
    state = AsyncData(await repo.getAllGoals());
  }
}

final savingsGoalsProvider =
    AsyncNotifierProvider<SavingsGoalsNotifier, List<SavingsGoal>>(() {
  return SavingsGoalsNotifier();
});

/// All transactions, sorted newest-first, mutable via AsyncNotifier.
class TransactionsNotifier extends AsyncNotifier<List<Transaction>> {
  @override
  Future<List<Transaction>> build() async {
    final repo = ref.watch(transactionsRepositoryProvider);
    return repo.getAll();
  }

  Future<void> add(Transaction t) async {
    final repo = ref.read(transactionsRepositoryProvider);
    await repo.addTransaction(t);
    state = AsyncData(await repo.getAll());
  }

  Future<void> updateTx(Transaction t) async {
    final repo = ref.read(transactionsRepositoryProvider);
    await repo.updateTransaction(t);
    state = AsyncData(await repo.getAll());
  }

  Future<void> remove(String id) async {
    final repo = ref.read(transactionsRepositoryProvider);
    await repo.deleteTransaction(id);
    state = AsyncData(await repo.getAll());
  }

  Future<void> toggleFavorite(String id) async {
    final current = state.valueOrNull ?? [];
    final index = current.indexWhere((t) => t.id == id);
    if (index != -1) {
      final target = current[index];
      final updated = target.copyWith(isFavorite: !target.isFavorite);
      await updateTx(updated);
    }
  }
}

final transactionsProvider =
    AsyncNotifierProvider<TransactionsNotifier, List<Transaction>>(() {
  return TransactionsNotifier();
});

/// Transactions for a specific account ID.
final accountTransactionsProvider =
    FutureProvider.family<List<Transaction>, String>((ref, accountId) async {
  final repo = ref.watch(transactionsRepositoryProvider);
  return repo.getByAccount(accountId);
});

/// All accounts.
final accountsProvider = FutureProvider<List<Account>>((ref) async {
  final repo = ref.watch(accountsRepositoryProvider);
  return repo.getAll();
});

/// Credit score history, oldest → newest.
final scoreHistoryProvider =
    FutureProvider<List<CreditScoreSnapshot>>((ref) async {
  final repo = ref.watch(creditScoreRepositoryProvider);
  return repo.getHistory();
});

/// The most recent credit score snapshot.
final latestScoreProvider =
    FutureProvider<CreditScoreSnapshot?>((ref) async {
  final repo = ref.watch(creditScoreRepositoryProvider);
  return repo.getLatest();
});

// ── Analytics provider (compute isolate) ─────────────────────────────────

/// Spend analytics computed off the UI thread via [AnalyticsIsolate].
final analyticsProvider = FutureProvider<AnalyticsResult>((ref) async {
  final txnAsync = await ref.watch(transactionsProvider.future);
  return AnalyticsIsolate.run(txnAsync);
});

// ── Live exchange rate provider (real REST call) ──────────────────────────

/// Live USD→INR rate from open.er-api.com.
/// On failure, returns null — the UI shows a "—" fallback gracefully.
final exchangeRateProvider = FutureProvider<double?>((ref) async {
  try {
    final service = ExchangeRateService();
    final response = await service.fetchRates();
    return response.inrRate;
  } catch (_) {
    // Network unavailable — return null; UI shows cached/fallback value.
    return null;
  }
});
