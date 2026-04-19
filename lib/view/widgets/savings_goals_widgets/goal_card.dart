import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/savings_goal_model.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/formatter.dart';
import '../../../logic/providers/auth_provider.dart';
import '../../../logic/providers/savings_goal_provider.dart';
import 'deposit_sheet.dart';
import 'goal_form_sheet.dart';

class GoalCard extends StatelessWidget {
  final SavingsGoalModel goal;
  const GoalCard({super.key, required this.goal});

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Goal?'),
        content: Text('Are you sure you want to delete "${goal.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final userId = context.read<AuthProvider>().user?.uid ?? '';
              context.read<SavingsGoalProvider>().deleteGoal(userId, goal.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: AppTheme.expense)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progressColor = goal.isCompleted ? AppTheme.income : AppTheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: goal.isCompleted ? AppTheme.income.withOpacity(0.3) : AppTheme.cardBorder),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(goal.icon, style: const TextStyle(fontSize: 20)),
            ),
            title: Text(goal.title, style: AppTheme.titleMedium),
            subtitle: Text('${Formatter.currency(goal.savedAmount)} / ${Formatter.currency(goal.targetAmount)}'),
            trailing: PopupMenuButton(
              onSelected: (val) {
                if (val == 'edit') {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => GoalFormSheet(existingGoal: goal),
                  );
                } else if (val == 'delete') {
                  _confirmDelete(context);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LinearProgressIndicator(
              value: goal.progress,
              backgroundColor: AppTheme.primaryLight,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${(goal.progress * 100).toStringAsFixed(0)}% saved', style: AppTheme.labelSmall),
                if (!goal.isCompleted)
                  ElevatedButton(
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => DepositSheet(goal: goal),
                    ),
                    child: const Text('Add Money'),
                  )
                else
                  const Text('🎉 Finished!', style: TextStyle(color: AppTheme.income, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }
}