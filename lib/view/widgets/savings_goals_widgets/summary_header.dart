import 'package:flutter/material.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/formatter.dart';
import '../../../logic/providers/savings_goal_provider.dart';

class SummaryHeader extends StatelessWidget {
  final SavingsGoalProvider provider;
  const SummaryHeader({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final overallProgress = provider.totalTarget > 0
        ? (provider.totalSaved / provider.totalTarget).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Total Saved', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  Formatter.currency(provider.totalSaved),
                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                ),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                const Text('Target', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  Formatter.currency(provider.totalTarget),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ]),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: overallProgress,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${(overallProgress * 100).toStringAsFixed(0)}% of total target',
                  style: const TextStyle(color: Colors.white70, fontSize: 11)),
              Text('${provider.goals.length} goals',
                  style: const TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}