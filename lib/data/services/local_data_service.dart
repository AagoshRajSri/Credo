import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/account.dart';
import '../models/transaction.dart';
import '../models/credit_score_snapshot.dart';

/// Loads and parses the seeded JSON asset files.
///
/// Parsing is done via [_parseList] which runs the fromJson loop
/// synchronously but is called inside a [compute] isolate in the
/// repositories, so the UI thread is never blocked.
abstract final class LocalDataService {
  // ── Accounts ────────────────────────────────────────────────────────
  static Future<List<Account>> loadAccounts() async {
    final raw = await rootBundle.loadString('assets/data/accounts.json');
    final list = json.decode(raw) as List<dynamic>;
    return list
        .map((e) => Account.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  // ── Transactions ─────────────────────────────────────────────────────
  static Future<List<Transaction>> loadTransactions() async {
    final raw = await rootBundle.loadString('assets/data/transactions.json');
    final list = json.decode(raw) as List<dynamic>;
    return list
        .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  // ── Credit score history ──────────────────────────────────────────────
  static Future<List<CreditScoreSnapshot>> loadScoreHistory() async {
    final raw = await rootBundle.loadString(
      'assets/data/credit_score_history.json',
    );
    final list = json.decode(raw) as List<dynamic>;
    return list
        .map((e) => CreditScoreSnapshot.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }
}
