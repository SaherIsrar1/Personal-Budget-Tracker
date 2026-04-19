import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/models/savings_goal_model.dart';
import '../../core/services/notification_service.dart';
import '../../data/repositories/savings_goal_repository.dart';

class SavingsGoalProvider extends ChangeNotifier {
  final SavingsGoalRepository _repo;
  final _notif = NotificationService();

  SavingsGoalProvider(this._repo);

  List<SavingsGoalModel> _goals = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _sub;
  String? _currentUserId;

  List<SavingsGoalModel> get goals     => _goals;
  bool                   get isLoading => _isLoading;
  String?                get error     => _error;
  double get totalSaved  => _goals.fold(0.0, (s, g) => s + g.savedAmount);
  double get totalTarget => _goals.fold(0.0, (s, g) => s + g.targetAmount);

  void startListening(String userId) {
    if (userId.isEmpty) return;
    if (_currentUserId == userId && _sub != null) return;

    _currentUserId = userId;
    _isLoading = true;
    notifyListeners();

    _sub?.cancel();
    _sub = _repo.streamGoals(userId).listen(
      (goals) {
        _goals = goals;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<bool> addGoal({
    required String userId,
    required String title,
    required double targetAmount,
    required String icon,
    double initialSaved = 0,
    DateTime? deadline,
  }) async {
    try {
      await _repo.addGoal(SavingsGoalModel(
        id: '', userId: userId, title: title,
        targetAmount: targetAmount, savedAmount: initialSaved,
        icon: icon, deadline: deadline, createdAt: DateTime.now(),
      ));
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateGoal(String userId, SavingsGoalModel goal) async {
    try {
      await _repo.updateGoal(goal);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ✅ addMoney fires goal notifications
  Future<bool> addMoney({
    required String userId,
    required String goalId,
    required double amount,
  }) async {
    try {
      await _repo.addToGoal(userId: userId, goalId: goalId, amount: amount);

      // Find the updated goal to check progress
      final goalIndex = _goals.indexWhere((g) => g.id == goalId);
      if (goalIndex != -1) {
        final goal = _goals[goalIndex];
        final newSaved = goal.savedAmount + amount;
        final newProgress = goal.targetAmount > 0
            ? newSaved / goal.targetAmount : 0.0;

        if (newSaved >= goal.targetAmount) {
          // 🎉 Goal reached!
          await _notif.showGoalReached(
            goalTitle: goal.title,
            targetAmount: goal.targetAmount,
            goalIndex: goalIndex,
          );
        } else if (newProgress >= 0.5 && goal.progress < 0.5) {
          // 50% milestone
          await _notif.showGoalProgress(
            goalTitle: goal.title,
            progress: newProgress,
            saved: newSaved,
            target: goal.targetAmount,
          );
        }
      }

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteGoal(String userId, String goalId) async {
    try {
      await _repo.deleteGoal(userId, goalId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() { _sub?.cancel(); super.dispose(); }
}
