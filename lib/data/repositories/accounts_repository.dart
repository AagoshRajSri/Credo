import 'package:hive/hive.dart';
import '../models/account.dart';
import '../services/local_data_service.dart';
import 'transactions_repository.dart';

/// Accounts repository — mirrors the same asset-first, Hive-cache pattern
/// as [TransactionsRepository].
class AccountsRepository {
  AccountsRepository({bool simulateOffline = false})
      : _simulateOffline = simulateOffline;

  final bool _simulateOffline;

  Box<Account> get _box => Hive.box<Account>(HiveBoxNames.accounts);

  Future<List<Account>> getAll() async {
    if (_box.isNotEmpty) {
      return _box.values.toList(growable: false);
    }
    if (_simulateOffline) return [];

    final fromAsset = await LocalDataService.loadAccounts();
    await _seedToHive(fromAsset);
    return _box.values.toList(growable: false);
  }

  Future<Account?> getById(String id) async {
    final all = await getAll();
    try {
      return all.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearCache() => _box.clear();

  Future<void> _seedToHive(List<Account> items) async {
    final map = {for (final a in items) a.id: a};
    await _box.putAll(map);
  }
}
