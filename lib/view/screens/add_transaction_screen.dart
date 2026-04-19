import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/enums/transaction_type.dart';
import '../../core/models/category_model.dart';
import '../../core/utils/app_theme.dart';
import '../../core/utils/formatter.dart';
import '../../logic/providers/auth_provider.dart';
import '../../logic/providers/dashboard_provider.dart';
import '../../logic/providers/transaction_provider.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen>
    with SingleTickerProviderStateMixin {
  TransactionType _type = TransactionType.expense;
  CategoryModel? _selectedCategory;
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  late AnimationController _animController;
  late Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  List<CategoryModel> get _categories {
    final all = CategoryModel.defaults;
    if (_type == TransactionType.income) {
      return all.where((c) => ['salary', 'freelance', 'other'].contains(c.id)).toList();
    }
    return all.where((c) => !['salary', 'freelance'].contains(c.id)).toList();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      _showSnack('Enter a valid amount', isError: true);
      return;
    }
    if (_selectedCategory == null) {
      _showSnack('Please select a category', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    final userId = context.read<AuthProvider>().uid;
    if (userId.isEmpty) {
      _showSnack('Session expired. Please sign in again.', isError: true);
      setState(() => _isSaving = false);
      return;
    }
    final budget = context.read<DashboardProvider>().monthlyBudget;
    final success = await context.read<TransactionProvider>().addTransaction(
      userId: userId,
      type: _type,
      amount: amount,
      category: _selectedCategory!,
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      date: _selectedDate,
      monthlyBudget: budget,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.of(context).pop(true);
      } else {
        _showSnack('Failed to save. Try again.', isError: true);
      }
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppTheme.expense : AppTheme.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnim,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _slideAnim.value * 60),
        child: child,
      ),
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text('Add Transaction'),
          leading: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.primary, fontSize: 14),
            ),
          ),
          leadingWidth: 80,
          automaticallyImplyLeading: false,
          actions: const [SizedBox(width: 16)],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Type Toggle ───────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: TransactionType.values.map((t) {
                    final active = _type == t;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _type = t;
                          _selectedCategory = null;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: active ? AppTheme.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            t.label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: active ? Colors.white : AppTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              // ── Amount ────────────────────────────────────
              _FieldLabel('Amount'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                style: AppTheme.displayMedium.copyWith(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                ),
                decoration: InputDecoration(
                  hintText: '0.00',
                  hintStyle: AppTheme.displayMedium.copyWith(
                    color: AppTheme.textHint, fontSize: 22,
                  ),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(left: 14, right: 8, top: 14),
                    child: Text('\$',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary)),
                  ),
                  prefixIconConstraints: const BoxConstraints(),
                ),
              ),

              const SizedBox(height: 20),

              // ── Category ──────────────────────────────────
              _FieldLabel('Category'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  final selected = _selectedCategory?.id == cat.id;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? AppTheme.primary : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? AppTheme.primary : AppTheme.cardBorder,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(cat.icon,
                              style: const TextStyle(fontSize: 15)),
                          const SizedBox(width: 6),
                          Text(
                            cat.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: selected
                                  ? Colors.white
                                  : AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // ── Description ───────────────────────────────
              _FieldLabel('Description (optional)'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descCtrl,
                maxLines: 2,
                style: AppTheme.bodyLarge,
                decoration: const InputDecoration(
                  hintText: 'e.g. Grocery shopping at Imtiaz',
                ),
              ),

              const SizedBox(height: 20),

              // ── Date ──────────────────────────────────────
              _FieldLabel('Date'),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppTheme.cardBorder),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 16, color: AppTheme.textSecondary),
                      const SizedBox(width: 10),
                      Text(
                        Formatter.dateLong(_selectedDate),
                        style: AppTheme.bodyLarge,
                      ),
                      const Spacer(),
                      const Icon(Icons.chevron_right,
                          size: 18, color: AppTheme.textHint),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ── Save Button ───────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Text(
                          'Save Transaction',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: AppTheme.labelSmall.copyWith(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      );
}
