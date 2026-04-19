import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/enums/transaction_type.dart';
import '../../core/models/transaction_model.dart';
import '../../core/models/category_model.dart';
import '../../core/services/notification_service.dart';
import '../../data/repositories/transaction_repository.dart';

class TransactionProvider extends ChangeNotifier {
  final TransactionRepository _repo;
  final _uuid = const Uuid();
  final _notif = NotificationService();

  TransactionProvider(this._repo);

  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  String? _error;

  // Budget thresholds we've already notified about (avoid spam)
  bool _warned80  = false;
  bool _warned100 = false;

  List<TransactionModel> get transactions => _transactions;
  bool                   get isLoading    => _isLoading;
  String?                get error        => _error;

  void startListening(String userId) {
    _isLoading = true;
    notifyListeners();
    _repo.watchAll(userId).listen(
      (txs) {
        _transactions = txs;
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

  // ── Add Transaction ───────────────────────────────────────────
  Future<bool> addTransaction({
    required String userId,
    required TransactionType type,
    required double amount,
    required CategoryModel category,
    String? description,
    required DateTime date,
    double monthlyBudget = 0,  // pass current budget for threshold check
  }) async {
    try {
      final tx = TransactionModel(
        id: _uuid.v4(),
        userId: userId,
        type: type,
        amount: amount,
        categoryId: category.id,
        categoryName: category.name,
        categoryIcon: category.icon,
        description: description,
        date: date,
        createdAt: DateTime.now(),
      );
      await _repo.add(tx);

      // ✅ Fire transaction saved notification
      await _notif.showTransactionSaved(
        type: type == TransactionType.income ? 'Income' : 'Expense',
        amount: amount,
        category: category.name,
      );

      // ✅ Check budget thresholds after adding an expense
      if (type == TransactionType.expense && monthlyBudget > 0) {
        await _checkBudgetThresholds(monthlyBudget);
      }

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── Budget threshold checker ──────────────────────────────────
  Future<void> checkBudgetThresholds(double monthlyBudget) async {
    await _checkBudgetThresholds(monthlyBudget);
  }

  Future<void> _checkBudgetThresholds(double monthlyBudget) async {
    if (monthlyBudget <= 0) return;

    final now = DateTime.now();
    final spent = _transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            t.date.year == now.year &&
            t.date.month == now.month)
        .fold(0.0, (sum, t) => sum + t.amount);

    final fraction = spent / monthlyBudget;

    if (fraction >= 1.0 && !_warned100) {
      _warned100 = true;
      await _notif.showBudgetExceeded(spent: spent, budget: monthlyBudget);
    } else if (fraction >= 0.8 && !_warned80) {
      _warned80 = true;
      await _notif.showBudgetWarning(spent: spent, budget: monthlyBudget);
    }

    // Reset flags at month change
    if (now.day == 1) {
      _warned80  = false;
      _warned100 = false;
    }
  }

  Future<bool> deleteTransaction(String id) async {
    try {
      await _repo.delete(id);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
