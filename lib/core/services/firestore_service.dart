// lib/core/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';
import '../models/savings_goal_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _users        => _db.collection('users');
  CollectionReference get _transactions => _db.collection('transactions');

  // ── User Profile ──────────────────────────────────────────────
  Future<void> createUserProfile({
    required String uid,
    required String displayName,
    required String email,
    double monthlyBudget = 2000,
    double initialBalance = 0,
  }) async {
    await _users.doc(uid).set({
      'displayName': displayName,
      'email': email,
      'monthlyBudget': monthlyBudget,
      'initialBalance': initialBalance,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _users.doc(uid).get();
    return doc.exists ? doc.data() as Map<String, dynamic> : null;
  }

  Future<void> updateMonthlyBudget(String uid, double budget) =>
      _users.doc(uid).update({'monthlyBudget': budget});

  // ✅ Save initial balance — stores as a special "opening balance" income tx
  Future<void> setInitialBalance({
    required String uid,
    required double amount,
  }) async {
    // Update profile
    await _users.doc(uid).set(
      {'initialBalance': amount},
      SetOptions(merge: true),
    );

    // Write as an income transaction so balance shows correctly
    final docRef = _transactions.doc();
    await docRef.set({
      'userId': uid,
      'type': 'income',
      'amount': amount,
      'categoryId': 'opening_balance',
      'categoryName': 'Opening Balance',
      'categoryIcon': '🏦',
      'description': 'Initial balance',
      'date': Timestamp.fromDate(DateTime.now()),
      'createdAt': FieldValue.serverTimestamp(),
      'isOpeningBalance': true,   // flag so we can handle specially if needed
    });
  }

  // ── Transactions ──────────────────────────────────────────────
  Future<void> addTransaction(TransactionModel tx) =>
      _transactions.doc(tx.id).set(tx.toFirestore());

  Future<void> updateTransaction(TransactionModel tx) =>
      _transactions.doc(tx.id).update(tx.toFirestore());

  Future<void> deleteTransaction(String id) =>
      _transactions.doc(id).delete();

  Stream<List<TransactionModel>> transactionsStream(String userId) {
    return _transactions
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs
        .map((d) => TransactionModel.fromFirestore(d))
        .toList());
  }

  Stream<List<TransactionModel>> monthlyTransactionsStream(
      String userId, DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end   = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    return _transactions
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs
        .map((d) => TransactionModel.fromFirestore(d))
        .toList());
  }

  // ── Savings Goals ─────────────────────────────────────────────
  CollectionReference _goalsCol(String userId) =>
      _users.doc(userId).collection('savings_goals');

  Stream<List<SavingsGoalModel>> savingsGoalsStream(String userId) {
    return _goalsCol(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
        .map((d) => SavingsGoalModel.fromMap(
        d.id, d.data() as Map<String, dynamic>))
        .toList());
  }

  Future<void> addSavingsGoal(SavingsGoalModel goal) async {
    await _goalsCol(goal.userId).add(goal.toMap());
  }

  Future<void> updateSavingsGoal(SavingsGoalModel goal) async {
    await _goalsCol(goal.userId).doc(goal.id).update(goal.toMap());
  }

  Future<void> deleteSavingsGoal(String userId, String goalId) async {
    await _goalsCol(userId).doc(goalId).delete();
  }

  Future<void> addMoneyToGoal({
    required String userId,
    required String goalId,
    required double amount,
  }) async {
    await _goalsCol(userId).doc(goalId).update({
      'savedAmount': FieldValue.increment(amount),
    });
  }
}