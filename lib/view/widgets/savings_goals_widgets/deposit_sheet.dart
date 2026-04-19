import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/savings_goal_model.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/formatter.dart';
import '../../../logic/providers/auth_provider.dart';
import 'package:budget_tracker/view/screens/savings_goals_screen.dart';

import '../../../logic/providers/savings_goal_provider.dart';

class DepositSheet extends StatefulWidget {
  final SavingsGoalModel goal;
  const DepositSheet({super.key, required this.goal});

  @override
  State<DepositSheet> createState() => _DepositSheetState();
}

class _DepositSheetState extends State<DepositSheet> {
  final _amountCtrl = TextEditingController();
  bool _isSaving = false;

  Future<void> _deposit() async {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) return;

    setState(() => _isSaving = true);
    final userId = context.read<AuthProvider>().user?.uid ?? '';
    await context.read<SavingsGoalProvider>().addMoney(
      userId: userId,
      goalId: widget.goal.id,
      amount: amount,
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24, right: 24, top: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Add to ${widget.goal.title}', style: AppTheme.titleLarge),
          const SizedBox(height: 20),
          TextField(
            controller: _amountCtrl,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              hintText: '0.00',
              prefixText: '\$ ',
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [50, 100, 500].map((amt) => ActionChip(
              label: Text('\$$amt'),
              onPressed: () => _amountCtrl.text = amt.toString(),
            )).toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _deposit,
              child: _isSaving ? const CircularProgressIndicator() : const Text('Confirm Deposit'),
            ),
          ),
        ],
      ),
    );
  }
}