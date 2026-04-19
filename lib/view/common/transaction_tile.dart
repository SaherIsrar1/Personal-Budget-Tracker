import 'package:flutter/material.dart';
import '../../core/enums/transaction_type.dart';
import '../../core/models/transaction_model.dart';
import '../../core/utils/app_theme.dart';
import '../../core/utils/formatter.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;

    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.expense.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: AppTheme.expense, size: 22),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    transaction.categoryIcon,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Name + date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.categoryName,
                      style: AppTheme.titleMedium.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      transaction.description?.isNotEmpty == true
                          ? transaction.description!
                          : Formatter.dateShort(transaction.date),
                      style: AppTheme.bodyMedium.copyWith(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Amount
              Text(
                Formatter.signedCurrency(transaction.amount, isIncome: isIncome),
                style: AppTheme.titleMedium.copyWith(
                  color: isIncome ? AppTheme.income : AppTheme.expense,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
