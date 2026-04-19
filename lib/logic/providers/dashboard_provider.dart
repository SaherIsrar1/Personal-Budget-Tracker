import 'package:flutter/material.dart';
import '../../core/enums/transaction_type.dart';
import '../../core/models/transaction_model.dart';
import '../../core/models/category_model.dart';
import '../../core/services/firestore_service.dart';

class CategorySpending {
  final CategoryModel category;
  final double total;
  final double percentage;
  const CategorySpending({
    required this.category,
    required this.total,
    required this.percentage,
  });
}

class DashboardProvider extends ChangeNotifier {
  final FirestoreService _service;
  DashboardProvider(this._service);

  double _monthlyBudget = 2000;
  double get monthlyBudget => _monthlyBudget;

  // ── Derived from transaction list ─────────────────────────────
  double totalBalance(List<TransactionModel> txs) {
    double income  = txs.where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    double expense = txs.where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
    return income - expense;
  }

  double monthlyIncome(List<TransactionModel> txs) {
    final now = DateTime.now();
    return txs
        .where((t) =>
            t.type == TransactionType.income &&
            t.date.year == now.year &&
            t.date.month == now.month)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double monthlyExpense(List<TransactionModel> txs) {
    final now = DateTime.now();
    return txs
        .where((t) =>
            t.type == TransactionType.expense &&
            t.date.year == now.year &&
            t.date.month == now.month)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double budgetUsedFraction(List<TransactionModel> txs) {
    if (_monthlyBudget <= 0) return 0;
    return (monthlyExpense(txs) / _monthlyBudget).clamp(0.0, 1.0);
  }

  List<TransactionModel> recentTransactions(
      List<TransactionModel> txs, {int limit = 5}) {
    final sorted = List<TransactionModel>.from(txs)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(limit).toList();
  }

  /// Spending grouped by category for current month
  List<CategorySpending> categoryBreakdown(List<TransactionModel> txs) {
    final now = DateTime.now();
    final expenses = txs.where((t) =>
        t.type == TransactionType.expense &&
        t.date.year == now.year &&
        t.date.month == now.month);

    final Map<String, double> totals = {};
    final Map<String, CategoryModel> catMap = {};

    for (final tx in expenses) {
      totals[tx.categoryId] = (totals[tx.categoryId] ?? 0) + tx.amount;
      catMap[tx.categoryId] ??= CategoryModel(
        id: tx.categoryId,
        name: tx.categoryName,
        icon: tx.categoryIcon,
        color: '#1BA589',
      );
    }

    final grandTotal = totals.values.fold(0.0, (a, b) => a + b);
    if (grandTotal == 0) return [];

    final breakdown = totals.entries.map((e) => CategorySpending(
      category: catMap[e.key]!,
      total: e.value,
      percentage: e.value / grandTotal,
    )).toList()
      ..sort((a, b) => b.total.compareTo(a.total));

    return breakdown.take(5).toList();
  }

  /// Daily spending for the current week (Mon–Sun)
  List<double> weeklySpending(List<TransactionModel> txs) {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final result = List<double>.filled(7, 0);

    for (final tx in txs) {
      if (tx.type != TransactionType.expense) continue;
      final diff = tx.date.difference(monday).inDays;
      if (diff >= 0 && diff < 7) result[diff] += tx.amount;
    }
    return result;
  }

  // ── Budget ────────────────────────────────────────────────────
  Future<void> loadBudget(String userId) async {
    final profile = await _service.getUserProfile(userId);
    if (profile != null) {
      _monthlyBudget = (profile['monthlyBudget'] as num?)?.toDouble() ?? 2000;
      notifyListeners();
    }
  }

  Future<void> updateBudget(String userId, double budget) async {
    _monthlyBudget = budget;
    notifyListeners();
    await _service.updateMonthlyBudget(userId, budget);
  }
}
