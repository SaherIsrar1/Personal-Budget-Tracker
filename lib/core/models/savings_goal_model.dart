import 'package:cloud_firestore/cloud_firestore.dart';

class SavingsGoalModel {
  final String id;
  final String userId;
  final String title;
  final double targetAmount;
  final double savedAmount;
  final String icon;
  final DateTime? deadline;
  final DateTime createdAt;

  SavingsGoalModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.targetAmount,
    required this.savedAmount,
    required this.icon,
    this.deadline,
    required this.createdAt,
  });

  double get progress =>
      targetAmount > 0 ? (savedAmount / targetAmount).clamp(0.0, 1.0) : 0.0;
  double get remaining =>
      (targetAmount - savedAmount).clamp(0.0, double.infinity);
  bool get isCompleted => savedAmount >= targetAmount;

  SavingsGoalModel copyWith({
    String? id, String? userId, String? title,
    double? targetAmount, double? savedAmount,
    String? icon, DateTime? deadline, DateTime? createdAt,
  }) =>
      SavingsGoalModel(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        title: title ?? this.title,
        targetAmount: targetAmount ?? this.targetAmount,
        savedAmount: savedAmount ?? this.savedAmount,
        icon: icon ?? this.icon,
        deadline: deadline ?? this.deadline,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'title': title,
        'targetAmount': targetAmount,
        'savedAmount': savedAmount,
        'icon': icon,
        'deadline':
            deadline != null ? Timestamp.fromDate(deadline!) : null,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory SavingsGoalModel.fromMap(String id, Map<String, dynamic> map) =>
      SavingsGoalModel(
        id: id,
        userId: map['userId'] ?? '',
        title: map['title'] ?? '',
        targetAmount: (map['targetAmount'] ?? 0).toDouble(),
        savedAmount: (map['savedAmount'] ?? 0).toDouble(),
        icon: map['icon'] ?? '🎯',
        deadline: map['deadline'] != null
            ? (map['deadline'] as Timestamp).toDate()
            : null,
        createdAt: map['createdAt'] != null
            ? (map['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
      );

  static List<String> get defaultIcons =>
      ['🎯', '🚗', '🏠', '✈️', '📱', '💍', '🎓', '🏦', '💻', '🎮'];
}
