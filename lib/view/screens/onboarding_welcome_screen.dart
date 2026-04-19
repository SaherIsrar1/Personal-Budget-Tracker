import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/services/firestore_service.dart';
import '../../core/utils/app_theme.dart';
import '../../logic/providers/auth_provider.dart';
import '../../logic/providers/savings_goal_provider.dart';
import '../../router/app_router.dart';

class OnboardingWelcomeScreen extends StatefulWidget {
  const OnboardingWelcomeScreen({super.key});

  @override
  State<OnboardingWelcomeScreen> createState() =>
      _OnboardingWelcomeScreenState();
}

class _OnboardingWelcomeScreenState extends State<OnboardingWelcomeScreen>
    with TickerProviderStateMixin {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;

  final _balanceCtrl   = TextEditingController();
  bool _balanceSaving  = false;

  final _goalTitleCtrl  = TextEditingController();
  final _goalAmountCtrl = TextEditingController();
  String _selectedIcon  = '🎯';
  bool _goalSaving      = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  final List<String> _icons = ['🎯', '🚗', '🏠', '✈️', '📱', '💍', '🎓', '🏦'];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _balanceCtrl.dispose();
    _goalTitleCtrl.dispose();
    _goalAmountCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _nextPage() => _pageCtrl.nextPage(
      duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);

  void _skip() =>
      Navigator.of(context).pushReplacementNamed(AppRouter.dashboard);

  Future<void> _saveBalance() async {
    final text = _balanceCtrl.text.trim();
    if (text.isEmpty) { _nextPage(); return; }

    final amount = double.tryParse(text.replaceAll(',', ''));
    if (amount == null || amount < 0) {
      _showSnack('Enter a valid balance');
      return;
    }

    setState(() => _balanceSaving = true);
    final userId = context.read<AuthProvider>().uid;
    if (userId.isNotEmpty && amount > 0) {
      try {
        await FirestoreService().setInitialBalance(uid: userId, amount: amount);
      } catch (_) {}
    }
    if (mounted) {
      setState(() => _balanceSaving = false);
      _nextPage();
    }
  }

  Future<void> _saveGoal() async {
    final title  = _goalTitleCtrl.text.trim();
    final amount = double.tryParse(_goalAmountCtrl.text.replaceAll(',', ''));

    if (title.isEmpty) { _showSnack('Enter a goal name'); return; }
    if (amount == null || amount <= 0) {
      _showSnack('Enter a valid target amount');
      return;
    }

    setState(() => _goalSaving = true);
    final userId = context.read<AuthProvider>().uid;
    final success = await context.read<SavingsGoalProvider>().addGoal(
        userId: userId, title: title, targetAmount: amount, icon: _selectedIcon);

    if (mounted) {
      setState(() => _goalSaving = false);
      if (success) {
        Navigator.of(context).pushReplacementNamed(AppRouter.dashboard);
      } else {
        _showSnack('Failed to create goal. Try again.');
      }
    }
  }

  void _showSnack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppTheme.expense,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      resizeToAvoidBottomInset: true,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Column(
            children: [
              // Dots + Skip
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: List.generate(3, (i) {
                        final active = _currentPage == i;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.only(right: 6),
                          width: active ? 20 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: active
                                ? AppTheme.primary
                                : AppTheme.primaryLight,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        );
                      }),
                    ),
                    TextButton(
                      onPressed: _skip,
                      child: Text('Skip',
                          style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: PageView(
                  controller: _pageCtrl,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  children: [
                    _WelcomePage(onNext: _nextPage),
                    _BalancePage(
                      controller: _balanceCtrl,
                      isSaving: _balanceSaving,
                      onSave: _saveBalance,
                      onSkip: _nextPage,
                    ),
                    _GoalPage(
                      titleCtrl: _goalTitleCtrl,
                      amountCtrl: _goalAmountCtrl,
                      selectedIcon: _selectedIcon,
                      icons: _icons,
                      isSaving: _goalSaving,
                      onIconSelect: (icon) =>
                          setState(() => _selectedIcon = icon),
                      onSave: _saveGoal,
                      onSkip: _skip,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Page 1 — Welcome
class _WelcomePage extends StatelessWidget {
  final VoidCallback onNext;
  const _WelcomePage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(children: [
        const Spacer(flex: 2),
        Container(
          width: 160, height: 160,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primary, AppTheme.primaryDark],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(40),
          ),
          child: const Center(
              child: Text('💰', style: TextStyle(fontSize: 70))),
        ),
        const Spacer(flex: 1),
        Text('Welcome,\nLet\'s Get Started!',
            textAlign: TextAlign.center,
            style: AppTheme.displayMedium.copyWith(
                fontSize: 28, fontWeight: FontWeight.w700, height: 1.2)),
        const SizedBox(height: 14),
        Text(
            'BudgetWise helps you track spending,\nset savings goals, and stay in control\nof your money — effortlessly.',
            textAlign: TextAlign.center,
            style: AppTheme.bodyMedium.copyWith(height: 1.6)),
        const Spacer(flex: 2),
        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton(
            onPressed: onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Set Initial Balance',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity, height: 52,
          child: OutlinedButton(
            onPressed: onNext,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.primary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Create First Savings Goal',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary)),
          ),
        ),
        const SizedBox(height: 32),
      ]),
    );
  }
}

// Page 2 — Balance
class _BalancePage extends StatelessWidget {
  final TextEditingController controller;
  final bool isSaving;
  final VoidCallback onSave, onSkip;
  const _BalancePage({
    required this.controller, required this.isSaving,
    required this.onSave, required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          28, 20, 28, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(18)),
          child: const Center(
              child: Text('🏦', style: TextStyle(fontSize: 28))),
        ),
        const SizedBox(height: 24),
        Text('What\'s your\ncurrent balance?',
            style: AppTheme.displayMedium.copyWith(
                fontSize: 26, fontWeight: FontWeight.w700, height: 1.2)),
        const SizedBox(height: 10),
        Text('This helps show an accurate picture\nof your finances from day one.',
            style: AppTheme.bodyMedium.copyWith(height: 1.5)),
        const SizedBox(height: 36),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primary, width: 1.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(children: [
            Text('\$',
                style: AppTheme.displayMedium
                    .copyWith(color: AppTheme.primary, fontSize: 28)),
            const SizedBox(width: 8),
            Expanded(child: TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
              ],
              autofocus: true,
              style: AppTheme.displayMedium.copyWith(fontSize: 28),
              decoration: InputDecoration(
                hintText: '0.00',
                hintStyle: AppTheme.displayMedium
                    .copyWith(color: AppTheme.textHint, fontSize: 28),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            )),
          ]),
        ),
        const SizedBox(height: 10),
        Text('You can always update this later in Settings.',
            style: AppTheme.labelSmall
                .copyWith(fontSize: 11, color: AppTheme.textHint)),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton(
            onPressed: isSaving ? null : onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: isSaving
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white))
                : const Text('Continue',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity, height: 48,
          child: TextButton(
            onPressed: onSkip,
            child: Text('Skip for now',
                style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }
}

// Page 3 — Goal
class _GoalPage extends StatelessWidget {
  final TextEditingController titleCtrl, amountCtrl;
  final String selectedIcon;
  final List<String> icons;
  final bool isSaving;
  final ValueChanged<String> onIconSelect;
  final VoidCallback onSave, onSkip;
  const _GoalPage({
    required this.titleCtrl, required this.amountCtrl,
    required this.selectedIcon, required this.icons,
    required this.isSaving, required this.onIconSelect,
    required this.onSave, required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          28, 20, 28, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(18)),
          child: const Center(
              child: Text('🎯', style: TextStyle(fontSize: 28))),
        ),
        const SizedBox(height: 24),
        Text('Create your first\nsavings goal',
            style: AppTheme.displayMedium.copyWith(
                fontSize: 26, fontWeight: FontWeight.w700, height: 1.2)),
        const SizedBox(height: 10),
        Text('Having a goal keeps you motivated.\nYou can add more goals anytime.',
            style: AppTheme.bodyMedium.copyWith(height: 1.5)),
        const SizedBox(height: 28),
        Text('CHOOSE AN ICON',
            style: AppTheme.labelSmall.copyWith(
                fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10, runSpacing: 10,
          children: icons.map((icon) {
            final selected = icon == selectedIcon;
            return GestureDetector(
              onTap: () => onIconSelect(icon),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: selected ? AppTheme.primary : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: selected
                          ? AppTheme.primary
                          : AppTheme.cardBorder),
                ),
                child: Center(
                    child:
                        Text(icon, style: const TextStyle(fontSize: 24))),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 22),
        Text('GOAL NAME',
            style: AppTheme.labelSmall.copyWith(
                fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
        const SizedBox(height: 8),
        TextField(
          controller: titleCtrl,
          style: AppTheme.bodyLarge,
          decoration:
              const InputDecoration(hintText: 'e.g. Emergency Fund, New Car'),
        ),
        const SizedBox(height: 18),
        Text('TARGET AMOUNT',
            style: AppTheme.labelSmall.copyWith(
                fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
        const SizedBox(height: 8),
        TextField(
          controller: amountCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
          ],
          style: AppTheme.bodyLarge,
          decoration:
              const InputDecoration(hintText: '0.00', prefixText: '\$ '),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton(
            onPressed: isSaving ? null : onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: isSaving
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white))
                : const Text('Create Goal & Continue',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity, height: 48,
          child: TextButton(
            onPressed: onSkip,
            child: Text('Skip for now',
                style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }
}
