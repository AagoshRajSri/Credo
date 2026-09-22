import 'package:hive/hive.dart';
import '../models/savings_goal.dart';

class SavingsGoalRepository {
  static const String boxName = 'savings_goals';

  /// Ensure the box is open. Call this in main() alongside others.
  static Future<void> init() async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox<SavingsGoal>(boxName);
    }
  }

  /// Get the Hive box
  Box<SavingsGoal> _getBox() {
    if (!Hive.isBoxOpen(boxName)) {
      throw StateError('SavingsGoals box is not open. Call SavingsGoalRepository.init() first.');
    }
    return Hive.box<SavingsGoal>(boxName);
  }

  /// Get all goals
  Future<List<SavingsGoal>> getAllGoals() async {
    final box = _getBox();
    return box.values.toList();
  }

  /// Add a new goal
  Future<void> addGoal(SavingsGoal goal) async {
    final box = _getBox();
    await box.put(goal.id, goal);
  }

  /// Update an existing goal
  Future<void> updateGoal(SavingsGoal goal) async {
    final box = _getBox();
    if (box.containsKey(goal.id)) {
      await box.put(goal.id, goal);
    } else {
      throw ArgumentError('Goal with ID ${goal.id} not found.');
    }
  }

  /// Delete a goal
  Future<void> deleteGoal(String id) async {
    final box = _getBox();
    await box.delete(id);
  }

  /// Delete all goals
  Future<void> clearAll() async {
    final box = _getBox();
    await box.clear();
  }
}
