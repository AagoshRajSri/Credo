import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'data/adapters/account_adapter.dart';
import 'data/adapters/transaction_adapter.dart';
import 'data/adapters/credit_score_snapshot_adapter.dart';
import 'data/models/account.dart';
import 'data/models/transaction.dart';
import 'data/models/credit_score_snapshot.dart';
import 'data/models/savings_goal.dart';
import 'data/adapters/savings_goal_adapter.dart';
import 'data/repositories/transactions_repository.dart';
import 'app.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ── System UI ──────────────────────────────────────────────────────
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFF12121A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ── Hive ───────────────────────────────────────────────────────────
  await Hive.initFlutter();

  // Register adapters (safe to call multiple times — Hive is idempotent).
  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(AccountAdapter());
  if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(TransactionAdapter());
  if (!Hive.isAdapterRegistered(4)) {
    Hive.registerAdapter(CreditScoreSnapshotAdapter());
  }
  if (!Hive.isAdapterRegistered(5)) {
    Hive.registerAdapter(SavingsGoalAdapter());
  }

  // Open all boxes before the widget tree starts.
  await Future.wait([
    Hive.openBox<Account>(HiveBoxNames.accounts),
    Hive.openBox<Transaction>(HiveBoxNames.transactions),
    Hive.openBox<CreditScoreSnapshot>(HiveBoxNames.scoreHistory),
    Hive.openBox<dynamic>(HiveBoxNames.appSettings),
    Hive.openBox<double>(HiveBoxNames.budgets),
    Hive.openBox<SavingsGoal>(HiveBoxNames.savingsGoals),
  ]);

  runApp(
    const ProviderScope(
      child: CredoApp(),
    ),
  );
}
