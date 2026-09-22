import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/savings_goal.dart';

class SavingsGoalRepository {
  SavingsGoalRepository({required this.userId});
  final String userId;

  CollectionReference<Map<String, dynamic>> get _collection =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('savings_goals');

  /// Get all goals
  Future<List<SavingsGoal>> getAllGoals() async {
    if (userId.isEmpty || userId == 'offline') return [];
    
    final snapshot = await _collection.get();
    return snapshot.docs.map((doc) => SavingsGoal.fromJson(doc.data())).toList();
  }

  /// Add a new goal
  Future<void> addGoal(SavingsGoal goal) async {
    if (userId.isEmpty || userId == 'offline') return;
    await _collection.doc(goal.id).set(goal.toJson());
  }

  /// Update an existing goal
  Future<void> updateGoal(SavingsGoal goal) async {
    if (userId.isEmpty || userId == 'offline') return;
    await _collection.doc(goal.id).update(goal.toJson());
  }

  /// Delete a goal
  Future<void> deleteGoal(String id) async {
    if (userId.isEmpty || userId == 'offline') return;
    await _collection.doc(id).delete();
  }
}
