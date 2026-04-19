import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/models/savings_goal_model.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/formatter.dart';
import '../../../logic/providers/auth_provider.dart';
import '../../../logic/providers/savings_goal_provider.dart';

class GoalFormSheet extends StatefulWidget {
  final SavingsGoalModel? existingGoal;
  const GoalFormSheet({super.key, this.existingGoal});

  @override
  State<GoalFormSheet> createState() => _GoalFormSheetState();
}

class _GoalFormSheetState extends State<GoalFormSheet> {
  final _titleCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _savedCtrl = TextEditingController();
  String _selectedIcon = '🎯';
  DateTime? _deadline;
  bool _isSaving = false;

  bool get _isEdit => widget.existingGoal != null;
  final List<String> _icons = SavingsGoalModel.defaultIcons;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final g = widget.existingGoal!;
      _titleCtrl.text = g.title;
      _targetCtrl.text = g.targetAmount.toStringAsFixed(0);
      _savedCtrl.text = g.savedAmount.toStringAsFixed(0);
      _selectedIcon = g.icon;
      _deadline = g.deadline;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _targetCtrl.dispose();
    _savedCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2035),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final target = double.tryParse(_targetCtrl.text.replaceAll(',', ''));
    final saved = double.tryParse(_savedCtrl.text.replaceAll(',', '')) ?? 0;

    if (title.isEmpty || target == null || target <= 0) return;

    setState(() => _isSaving = true);
    final userId = context.read<AuthProvider>().user?.uid ?? '';
    final goalProv = context.read<SavingsGoalProvider>();

    if (_isEdit) {
      final updated = widget.existingGoal!.copyWith(
        title: title,
        targetAmount: target,
        savedAmount: saved,
        icon: _selectedIcon,
        deadline: _deadline,
      );
      await goalProv.updateGoal(userId, updated);
    } else {
      await goalProv.addGoal(
        userId: userId,
        title: title,
        targetAmount: target,
        icon: _selectedIcon,
        deadline: _deadline,
      );
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24, right: 24, top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_isEdit ? 'Edit Goal' : 'New Savings Goal', style: AppTheme.titleLarge),
            const SizedBox(height: 20),

            // Icon Picker
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _icons.length,
                itemBuilder: (context, i) => GestureDetector(
                  onTap: () => setState(() => _selectedIcon = _icons[i]),
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _selectedIcon == _icons[i] ? AppTheme.primary : AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_icons[i], style: const TextStyle(fontSize: 20)),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Goal Name', hintText: 'e.g. New Laptop'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _targetCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Target Amount', prefixText: '\$ '),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _savedCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Already Saved', prefixText: '\$ '),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ListTile(
              onTap: _pickDeadline,
              leading: const Icon(Icons.calendar_today),
              title: Text(_deadline == null ? 'Set Deadline' : Formatter.dateLong(_deadline!)),
              trailing: const Icon(Icons.chevron_right),
              tileColor: AppTheme.primaryLight,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black87),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(_isEdit ? 'Save Changes' : 'Create Goal'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}