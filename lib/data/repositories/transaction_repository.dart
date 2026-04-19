import '../../core/models/transaction_model.dart';
import '../../core/services/firestore_service.dart';

class TransactionRepository {
  final FirestoreService _service;
  TransactionRepository(this._service);

  Future<void> add(TransactionModel tx) => _service.addTransaction(tx);
  Future<void> update(TransactionModel tx) => _service.updateTransaction(tx);
  Future<void> delete(String id) => _service.deleteTransaction(id);

  Stream<List<TransactionModel>> watchAll(String userId) =>
      _service.transactionsStream(userId);

  Stream<List<TransactionModel>> watchMonthly(String userId, DateTime month) =>
      _service.monthlyTransactionsStream(userId, month);
}
