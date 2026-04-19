import 'package:cloud_firestore/cloud_firestore.dart';
import '../enums/transaction_type.dart';

class TransactionModel {
  final String id;
  final String userId;
  final TransactionType type;
  final double amount;
  final String categoryId;
  final String categoryName;
  final String categoryIcon;
  final String? description;
  final DateTime date;
  final DateTime createdAt;

  const TransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    this.description,
    required this.date,
    required this.createdAt,
  });

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: TransactionType.fromString(data['type'] ?? 'expense'),
      amount: (data['amount'] as num).toDouble(),
      categoryId: data['categoryId'] ?? '',
      categoryName: data['categoryName'] ?? '',
      categoryIcon: data['categoryIcon'] ?? '💰',
      description: data['description'],
      date: (data['date'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'type': type.name,
    'amount': amount,
    'categoryId': categoryId,
    'categoryName': categoryName,
    'categoryIcon': categoryIcon,
    'description': description,
    'date': Timestamp.fromDate(date),
    'createdAt': Timestamp.fromDate(createdAt),
  };

  TransactionModel copyWith({
    String? id,
    String? userId,
    TransactionType? type,
    double? amount,
    String? categoryId,
    String? categoryName,
    String? categoryIcon,
    String? description,
    DateTime? date,
    DateTime? createdAt,
  }) => TransactionModel(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    type: type ?? this.type,
    amount: amount ?? this.amount,
    categoryId: categoryId ?? this.categoryId,
    categoryName: categoryName ?? this.categoryName,
    categoryIcon: categoryIcon ?? this.categoryIcon,
    description: description ?? this.description,
    date: date ?? this.date,
    createdAt: createdAt ?? this.createdAt,
  );
}
