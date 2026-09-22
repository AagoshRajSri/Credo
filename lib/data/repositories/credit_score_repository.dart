import 'package:hive/hive.dart';
import '../models/credit_score_snapshot.dart';
import '../services/local_data_service.dart';
import 'transactions_repository.dart';

/// Credit score history repository.
class CreditScoreRepository {
  CreditScoreRepository({bool simulateOffline = false})
      : _simulateOffline = simulateOffline;

  final bool _simulateOffline;

  Box<CreditScoreSnapshot> get _box =>
      Hive.box<CreditScoreSnapshot>(HiveBoxNames.scoreHistory);

  /// Returns snapshots sorted oldest → newest (for the sparkline left → right).
  Future<List<CreditScoreSnapshot>> getHistory() async {
    if (_box.isNotEmpty) {
      return _sortedFromCache();
    }
    if (_simulateOffline) return [];

    final fromAsset = await LocalDataService.loadScoreHistory();
    await _seedToHive(fromAsset);
    return _sortedFromCache();
  }

  /// The most recent score snapshot.
  Future<CreditScoreSnapshot?> getLatest() async {
    final history = await getHistory();
    return history.isEmpty ? null : history.last;
  }

  Future<void> clearCache() => _box.clear();

  List<CreditScoreSnapshot> _sortedFromCache() {
    return _box.values.toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<void> _seedToHive(List<CreditScoreSnapshot> items) async {
    for (int i = 0; i < items.length; i++) {
      await _box.put(i, items[i]);
    }
  }
}
