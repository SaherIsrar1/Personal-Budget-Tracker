import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/models/savings_goal_model.dart';
import '../../core/utils/app_theme.dart';
import '../../core/utils/formatter.dart';
import '../../logic/providers/auth_provider.dart';
import '../../logic/providers/savings_goal_provider.dart';

class SavingsGoalsScreen extends StatelessWidget {
  const SavingsGoalsScreen({super.key});

  void _openAddSheet(BuildContext context) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const _GoalFormSheet(),
      );

  void _openEditSheet(BuildContext context, SavingsGoalModel goal) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _GoalFormSheet(existingGoal: goal),
      );

  void _openDepositSheet(BuildContext context, SavingsGoalModel goal) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _DepositSheet(goal: goal),
      );

  void _confirmDelete(BuildContext context, SavingsGoalModel goal) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Goal?'),
        content: Text('Delete "${goal.title}"? This cannot be undone.',
            style: AppTheme.bodyMedium),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final userId = context.read<AuthProvider>().uid;
              await context
                  .read<SavingsGoalProvider>()
                  .deleteGoal(userId, goal.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('Goal deleted'),
                  backgroundColor: AppTheme.expense,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ));
              }
            },
            child: const Text('Delete',
                style: TextStyle(color: AppTheme.expense)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SavingsGoalProvider>();
    final goals    = provider.goals;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Savings Goals'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () => _openAddSheet(context),
            icon: const Icon(Icons.add_circle_outline, size: 26),
            color: AppTheme.primary,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: provider.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : goals.isEmpty
              ? _EmptyGoals(onAdd: () => _openAddSheet(context))
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                        child: _SummaryHeader(provider: provider)),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => _GoalCard(
                            goal: goals[i],
                            onDeposit: () =>
                                _openDepositSheet(context, goals[i]),
                            onEdit: () => _openEditSheet(context, goals[i]),
                            onDelete: () => _confirmDelete(context, goals[i]),
                          ),
                          childCount: goals.length,
                        ),
                      ),
                    ),
                  ],
                ),
      floatingActionButton: goals.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openAddSheet(context),
              backgroundColor: AppTheme.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('New Goal',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ),
    );
  }
}

// ── Summary Header ────────────────────────────────────────────────
class _SummaryHeader extends StatelessWidget {
  final SavingsGoalProvider provider;
  const _SummaryHeader({required this.provider});

  @override
  Widget build(BuildContext context) {
    final progress = provider.totalTarget > 0
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Total Saved',
                style: AppTheme.labelSmall
                    .copyWith(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 4),
            Text(Formatter.currency(provider.totalSaved),
                style: AppTheme.displayMedium.copyWith(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700)),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('Target',
                style: AppTheme.labelSmall
                    .copyWith(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 4),
            Text(Formatter.currency(provider.totalTarget),
                style: AppTheme.titleMedium
                    .copyWith(color: Colors.white, fontSize: 16)),
          ]),
        ]),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('${(progress * 100).toStringAsFixed(0)}% of total target',
              style: AppTheme.labelSmall
                  .copyWith(color: Colors.white70, fontSize: 11)),
          Text(
              '${provider.goals.length} goal${provider.goals.length == 1 ? '' : 's'}',
              style: AppTheme.labelSmall
                  .copyWith(color: Colors.white70, fontSize: 11)),
        ]),
      ]),
    );
  }
}

// ── Goal Card ─────────────────────────────────────────────────────
class _GoalCard extends StatelessWidget {
  final SavingsGoalModel goal;
  final VoidCallback onDeposit, onEdit, onDelete;
  const _GoalCard({
    required this.goal,
    required this.onDeposit,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = goal.isCompleted
        ? AppTheme.income
        : goal.progress > 0.7
            ? const Color(0xFFF59E0B)
            : AppTheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: goal.isCompleted
              ? AppTheme.income.withOpacity(0.3)
              : AppTheme.cardBorder,
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
          child: Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: goal.isCompleted
                    ? AppTheme.income.withOpacity(0.1)
                    : AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                  child: Text(goal.icon,
                      style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                          child: Text(goal.title,
                              style: AppTheme.titleMedium
                                  .copyWith(fontSize: 15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis)),
                      if (goal.isCompleted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.income.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text('✓ Done',
                              style: AppTheme.labelSmall.copyWith(
                                  color: AppTheme.income,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11)),
                        ),
                    ]),
                    const SizedBox(height: 3),
                    RichText(
                        text: TextSpan(children: [
                      TextSpan(
                          text: Formatter.currency(goal.savedAmount),
                          style: TextStyle(
                              color: color,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'DM Sans')),
                      TextSpan(
                          text:
                              ' / ${Formatter.currency(goal.targetAmount)}',
                          style: AppTheme.bodyMedium
                              .copyWith(fontSize: 13)),
                    ])),
                  ]),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert,
                  color: AppTheme.textHint, size: 20),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              onSelected: (v) {
                if (v == 'edit') onEdit();
                if (v == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [
                      const Icon(Icons.edit_outlined,
                          size: 16, color: AppTheme.textPrimary),
                      const SizedBox(width: 10),
                      Text('Edit', style: AppTheme.bodyMedium),
                    ])),
                PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      const Icon(Icons.delete_outline,
                          size: 16, color: AppTheme.expense),
                      const SizedBox(width: 10),
                      Text('Delete',
                          style: AppTheme.bodyMedium
                              .copyWith(color: AppTheme.expense)),
                    ])),
              ],
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: goal.progress,
                minHeight: 7,
                backgroundColor: AppTheme.primaryLight,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 6),
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${(goal.progress * 100).toStringAsFixed(0)}% saved',
                      style: AppTheme.labelSmall.copyWith(fontSize: 11)),
                  if (!goal.isCompleted)
                    Text('${Formatter.currency(goal.remaining)} left',
                        style: AppTheme.labelSmall.copyWith(
                            fontSize: 11,
                            color: AppTheme.textSecondary)),
                ]),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: Row(children: [
            if (goal.deadline != null) ...[
              const Icon(Icons.calendar_today_outlined,
                  size: 12, color: AppTheme.textHint),
              const SizedBox(width: 4),
              Text(Formatter.dateLong(goal.deadline!),
                  style: AppTheme.labelSmall.copyWith(fontSize: 11)),
            ],
            const Spacer(),
            if (!goal.isCompleted)
              SizedBox(
                height: 34,
                child: ElevatedButton.icon(
                  onPressed: onDeposit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.add, size: 15, color: Colors.white),
                  label: const Text('Add Money',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ),
              )
            else
              Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppTheme.income.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text('🎉 Goal Reached!',
                    style: AppTheme.labelSmall.copyWith(
                        color: AppTheme.income,
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
              ),
          ]),
        ),
      ]),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────
class _EmptyGoals extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyGoals({required this.onAdd});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(36),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 96, height: 96,
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Center(
                  child: Text('🎯', style: TextStyle(fontSize: 44))),
            ),
            const SizedBox(height: 24),
            Text('No savings goals yet', style: AppTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Set a goal and watch your\nsavings grow step by step.',
                textAlign: TextAlign.center,
                style: AppTheme.bodyMedium.copyWith(height: 1.5)),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
              icon: const Icon(Icons.add),
              label: const Text('Create First Goal'),
            ),
          ]),
        ),
      );
}

// ── Add / Edit Sheet ──────────────────────────────────────────────
class _GoalFormSheet extends StatefulWidget {
  final SavingsGoalModel? existingGoal;
  const _GoalFormSheet({this.existingGoal});

  @override
  State<_GoalFormSheet> createState() => _GoalFormSheetState();
}

class _GoalFormSheetState extends State<_GoalFormSheet> {
  final _titleCtrl  = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _savedCtrl  = TextEditingController();
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
      _titleCtrl.text  = g.title;
      _targetCtrl.text = g.targetAmount.toStringAsFixed(0);
      _savedCtrl.text  = g.savedAmount.toStringAsFixed(0);
      _selectedIcon    = g.icon;
      _deadline        = g.deadline;
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
      initialDate:
          _deadline ?? DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2035),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme:
                const ColorScheme.light(primary: AppTheme.primary)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _submit() async {
    final title  = _titleCtrl.text.trim();
    final target = double.tryParse(_targetCtrl.text.replaceAll(',', ''));
    final saved  = double.tryParse(_savedCtrl.text.replaceAll(',', '')) ?? 0;

    if (title.isEmpty) { _snack('Enter a goal name'); return; }
    if (target == null || target <= 0) {
      _snack('Enter a valid target amount');
      return;
    }

    setState(() => _isSaving = true);
    final userId = context.read<AuthProvider>().uid;
    final goalProv = context.read<SavingsGoalProvider>();

    bool success;
    if (_isEdit) {
      final updated = widget.existingGoal!.copyWith(
        title: title, targetAmount: target,
        savedAmount: saved, icon: _selectedIcon, deadline: _deadline,
      );
      success = await goalProv.updateGoal(userId, updated);
    } else {
      success = await goalProv.addGoal(
        userId: userId, title: title, targetAmount: target,
        icon: _selectedIcon, initialSaved: saved, deadline: _deadline,
      );
    }

    setState(() => _isSaving = false);
    if (mounted) {
      Navigator.pop(context);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isEdit ? 'Goal updated!' : 'Goal created! 🎯'),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
          backgroundColor: AppTheme.expense,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12))));

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24, right: 24, top: 8,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: AppTheme.cardBorder,
                  borderRadius: BorderRadius.circular(99)),
            )),
            Text(_isEdit ? 'Edit Goal' : 'New Savings Goal',
                style: AppTheme.titleLarge
                    .copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),

            // Icon picker
            _Label('ICON'),
            const SizedBox(height: 10),
            SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _icons.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final icon = _icons[i];
                  final selected = icon == _selectedIcon;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = icon),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.primary
                            : AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(child: Text(icon,
                          style: const TextStyle(fontSize: 22))),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),

            _Label('GOAL NAME'),
            const SizedBox(height: 8),
            TextField(
              controller: _titleCtrl,
              style: AppTheme.bodyLarge,
              decoration: const InputDecoration(
                  hintText: 'e.g. Emergency Fund, New Car'),
            ),
            const SizedBox(height: 16),

            Row(children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Label('TARGET AMOUNT'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _targetCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                    ],
                    style: AppTheme.bodyLarge,
                    decoration: const InputDecoration(
                        hintText: '0.00', prefixText: '\$ '),
                  ),
                ],
              )),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Label('SAVED SO FAR'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _savedCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                    ],
                    style: AppTheme.bodyLarge,
                    decoration: const InputDecoration(
                        hintText: '0.00', prefixText: '\$ '),
                  ),
                ],
              )),
            ]),
            const SizedBox(height: 16),

            _Label('DEADLINE (OPTIONAL)'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDeadline,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 16, color: AppTheme.primary),
                  const SizedBox(width: 10),
                  Expanded(child: Text(
                    _deadline != null
                        ? Formatter.dateLong(_deadline!)
                        : 'Set a target date',
                    style: AppTheme.bodyMedium.copyWith(
                      color: _deadline != null
                          ? AppTheme.textPrimary
                          : AppTheme.textHint,
                    ),
                  )),
                  if (_deadline != null)
                    GestureDetector(
                      onTap: () => setState(() => _deadline = null),
                      child: const Icon(Icons.close,
                          size: 16, color: AppTheme.textHint),
                    ),
                ]),
              ),
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSaving
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : Text(_isEdit ? 'Save Changes' : 'Create Goal',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Deposit Sheet ─────────────────────────────────────────────────
class _DepositSheet extends StatefulWidget {
  final SavingsGoalModel goal;
  const _DepositSheet({required this.goal});

  @override
  State<_DepositSheet> createState() => _DepositSheetState();
}

class _DepositSheetState extends State<_DepositSheet> {
  final _amountCtrl = TextEditingController();
  bool _isSaving = false;
  final List<int> _presets = [50, 100, 250, 500];

  @override
  void dispose() { _amountCtrl.dispose(); super.dispose(); }

  Future<void> _deposit() async {
    final amount =
        double.tryParse(_amountCtrl.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Enter a valid amount'),
        backgroundColor: AppTheme.expense,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }
    setState(() => _isSaving = true);
    final userId = context.read<AuthProvider>().uid;
    final success = await context.read<SavingsGoalProvider>().addMoney(
        userId: userId, goalId: widget.goal.id, amount: amount);
    setState(() => _isSaving = false);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success
            ? '${Formatter.currency(amount)} added to ${widget.goal.title}!'
            : 'Failed. Try again.'),
        backgroundColor: success ? AppTheme.income : AppTheme.expense,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ));
    }
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
        left: 24, right: 24, top: 8,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(
          width: 40, height: 4,
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(color: AppTheme.cardBorder,
              borderRadius: BorderRadius.circular(99)),
        )),
        Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(child: Text(widget.goal.icon,
                style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.goal.title,
                style: AppTheme.titleMedium
                    .copyWith(fontWeight: FontWeight.w700)),
            Text('${Formatter.currency(widget.goal.remaining)} remaining',
                style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600)),
          ]),
        ]),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: widget.goal.progress, minHeight: 8,
            backgroundColor: AppTheme.primaryLight,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppTheme.primary),
          ),
        ),
        const SizedBox(height: 20),
        _Label('ADD AMOUNT'),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Row(children: [
            Text('\$',
                style: AppTheme.titleLarge.copyWith(color: AppTheme.primary)),
            const SizedBox(width: 8),
            Expanded(child: TextField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
              ],
              autofocus: true,
              style: AppTheme.titleLarge.copyWith(fontSize: 22),
              decoration: InputDecoration(
                hintText: '0.00',
                hintStyle: AppTheme.titleLarge
                    .copyWith(fontSize: 22, color: AppTheme.textHint),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            )),
          ]),
        ),
        const SizedBox(height: 12),
        Row(
          children: _presets.map((amt) {
            final isLast = amt == _presets.last;
            return Expanded(child: GestureDetector(
              onTap: () => setState(() => _amountCtrl.text = amt.toString()),
              child: Container(
                margin: EdgeInsets.only(right: isLast ? 0 : 8),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: Text('\$$amt',
                    style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13))),
              ),
            ));
          }).toList(),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _deposit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: _isSaving
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white))
                : const Text('Add to Goal',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: AppTheme.labelSmall.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          color: AppTheme.textSecondary));
}
