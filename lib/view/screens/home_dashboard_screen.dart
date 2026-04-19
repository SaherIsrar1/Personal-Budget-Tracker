import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/app_theme.dart';
import '../../core/utils/formatter.dart';
import '../../logic/providers/auth_provider.dart';
import '../../logic/providers/dashboard_provider.dart';
import '../../logic/providers/savings_goal_provider.dart';
import '../../logic/providers/transaction_provider.dart';
import '../../router/app_router.dart';
import '../common/transaction_tile.dart';
import '../widgets/dashboard_widgets/balance_card.dart';
import 'add_transaction_screen.dart';
import 'reports_screen.dart';
import 'savings_goals_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startListeners());
  }

  void _startListeners() {
    final userId = context.read<AuthProvider>().uid;
    if (userId.isEmpty) return;
    context.read<TransactionProvider>().startListening(userId);
    context.read<DashboardProvider>().loadBudget(userId);
    context.read<SavingsGoalProvider>().startListening(userId);
  }

  Future<void> _openAddTransaction() async {
    final result = await Navigator.of(context).push<bool>(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const AddTransactionScreen(),
        transitionsBuilder: (_, animation, __, child) {
          final tween = Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOutCubic));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
        transitionDuration: const Duration(milliseconds: 380),
      ),
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Transaction saved!'),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: IndexedStack(
        index: _currentTab,
        children: [
          _DashboardTab(onAddTransaction: _openAddTransaction),
          const SavingsGoalsScreen(),
          const ReportsScreen(),
        ],
      ),
      floatingActionButton: _currentTab == 0
          ? FloatingActionButton(
              onPressed: _openAddTransaction,
              backgroundColor: AppTheme.primary,
              shape: const CircleBorder(),
              elevation: 4,
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentTab,
        onTap: (i) => setState(() => _currentTab = i),
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  final VoidCallback onAddTransaction;
  const _DashboardTab({required this.onAddTransaction});

  @override
  Widget build(BuildContext context) {
    final auth    = context.watch<AuthProvider>();
    final txProv  = context.watch<TransactionProvider>();
    final dash    = context.watch<DashboardProvider>();
    final txs     = txProv.transactions;
    final recent  = dash.recentTransactions(txs);

    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: BalanceCard(
            userName: auth.displayName,
            balance: dash.totalBalance(txs),
            monthlyExpense: dash.monthlyExpense(txs),
            monthlyBudget: dash.monthlyBudget,
            currentMonth: Formatter.monthYear(DateTime.now()),
            onAvatarTap: () => _showProfileSheet(context, auth),
          ),
        ),

        // Income / Expense summary pills
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(children: [
            _SummaryPill(
              label: 'Income',
              amount: dash.monthlyIncome(txs),
              icon: '↑',
              color: AppTheme.income,
            ),
            const SizedBox(width: 10),
            _SummaryPill(
              label: 'Expenses',
              amount: dash.monthlyExpense(txs),
              icon: '↓',
              color: AppTheme.expense,
            ),
          ]),
        ),

        // Recent transactions list
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recent Transactions', style: AppTheme.titleMedium),
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 28)),
                      child: Text('See all',
                          style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: txProv.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: AppTheme.primary))
                      : recent.isEmpty
                          ? _EmptyState(onAdd: onAddTransaction)
                          : ListView.builder(
                              padding: const EdgeInsets.only(bottom: 90),
                              itemCount: recent.length,
                              itemBuilder: (_, i) => TransactionTile(
                                transaction: recent[i],
                                onDelete: () => context
                                    .read<TransactionProvider>()
                                    .deleteTransaction(recent[i].id),
                              ),
                            ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showProfileSheet(BuildContext context, AuthProvider auth) {
    Navigator.of(context).pushNamed(AppRouter.settings);
  }

  void _showProfileSheetOld(BuildContext context, AuthProvider auth) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.primaryLight,
                child: Text(
                  auth.displayName.isNotEmpty ? auth.displayName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w700, color: AppTheme.primary),
                ),
              ),
              const SizedBox(height: 12),
              Text(auth.displayName, style: AppTheme.titleLarge),
              Text(auth.email, style: AppTheme.bodyMedium),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                icon: const Icon(Icons.logout, size: 16),
                label: const Text('Sign Out'),
                onPressed: () async {
                  Navigator.of(context).pop();
                  await auth.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushReplacementNamed(AppRouter.signIn);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final String label;
  final double amount;
  final String icon;
  final Color color;
  const _SummaryPill(
      {required this.label, required this.amount, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Center(
                child: Text(icon,
                    style: TextStyle(
                        color: color, fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: AppTheme.labelSmall.copyWith(fontSize: 11)),
              Text(Formatter.currencyCompact(amount),
                  style: AppTheme.titleMedium.copyWith(fontSize: 14, color: color)),
            ]),
          ]),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('💸', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('No transactions yet', style: AppTheme.titleMedium),
          const SizedBox(height: 6),
          Text('Tap + to add your first one', style: AppTheme.bodyMedium),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onAdd,
            style: ElevatedButton.styleFrom(minimumSize: const Size(160, 44)),
            child: const Text('Add Transaction'),
          ),
        ]),
      );
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: Colors.white,
      elevation: 8,
      shadowColor: Colors.black12,
      notchMargin: 6,
      shape: const CircularNotchedRectangle(),
      child: SizedBox(
        height: 56,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
                icon: Icons.home_outlined, activeIcon: Icons.home,
                label: 'Home', active: currentIndex == 0,
                onTap: () => onTap(0)),
            const SizedBox(width: 56),
            _NavItem(
                icon: Icons.savings_outlined, activeIcon: Icons.savings,
                label: 'Goals', active: currentIndex == 1,
                onTap: () => onTap(1)),
            _NavItem(
                icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart,
                label: 'Reports', active: currentIndex == 2,
                onTap: () => onTap(2)),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon, activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _NavItem(
      {required this.icon, required this.activeIcon, required this.label,
       required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 60,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(active ? activeIcon : icon,
                color: active ? AppTheme.primary : AppTheme.textHint, size: 22),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    color: active ? AppTheme.primary : AppTheme.textHint)),
          ]),
        ),
      );
}
