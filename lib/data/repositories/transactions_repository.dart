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

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction.dart';

class TransactionsRepository {
  TransactionsRepository({required this.userId});
  final String userId;

  CollectionReference<Map<String, dynamic>> get _collection =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('transactions');

  /// Returns all transactions, sorted newest-first.
  Future<List<Transaction>> getAll() async {
    if (userId.isEmpty || userId == 'offline') return [];
    
    final snapshot = await _collection.orderBy('date', descending: true).get();
    return snapshot.docs.map((doc) => Transaction.fromJson(doc.data())).toList();
  }

  /// Returns transactions for a specific [accountId].
  Future<List<Transaction>> getByAccount(String accountId) async {
    final all = await getAll();
    return all.where((t) => t.accountId == accountId).toList();
  }

  /// Adds a new transaction.
  Future<void> addTransaction(Transaction transaction) async {
    if (userId.isEmpty || userId == 'offline') return;
    await _collection.doc(transaction.id).set(transaction.toJson());
  }

  /// Updates an existing transaction.
  Future<void> updateTransaction(Transaction transaction) async {
    if (userId.isEmpty || userId == 'offline') return;
    await _collection.doc(transaction.id).update(transaction.toJson());
  }

  /// Deletes a transaction by ID.
  Future<void> deleteTransaction(String id) async {
    if (userId.isEmpty || userId == 'offline') return;
    await _collection.doc(id).delete();
  }
}
