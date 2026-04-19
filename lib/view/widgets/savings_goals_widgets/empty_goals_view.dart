import 'package:flutter/material.dart';
import '../../../core/utils/app_theme.dart';

class EmptyGoalsView extends StatelessWidget {
  final VoidCallback onAdd;
  const EmptyGoalsView({super.key, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎯', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 20),
            Text('No Savings Goals', style: AppTheme.titleLarge),
            const SizedBox(height: 10),
            const Text(
              'You haven\'t set any goals yet. Start saving for something special!',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Create My First Goal'),
            ),
          ],
        ),
      ),
    );
  }
}