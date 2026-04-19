import '../../core/models/savings_goal_model.dart';
import '../../core/services/firestore_service.dart';

class SavingsGoalRepository {
  final FirestoreService _service;
  SavingsGoalRepository(this._service);

  Stream<List<SavingsGoalModel>> streamGoals(String userId) =>
      _service.savingsGoalsStream(userId);

  Future<void> addGoal(SavingsGoalModel goal) =>
      _service.addSavingsGoal(goal);

  Future<void> updateGoal(SavingsGoalModel goal) =>
      _service.updateSavingsGoal(goal);

  Future<void> deleteGoal(String userId, String goalId) =>
      _service.deleteSavingsGoal(userId, goalId);

  Future<void> addToGoal({
    required String userId,
    required String goalId,
    required double amount,
  }) =>
      _service.addMoneyToGoal(userId: userId, goalId: goalId, amount: amount);
}
