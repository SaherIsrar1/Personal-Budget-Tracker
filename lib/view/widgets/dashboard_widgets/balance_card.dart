import 'package:flutter/material.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/formatter.dart';

class BalanceCard extends StatelessWidget {
  final String userName;
  final double balance;
  final double monthlyExpense;
  final double monthlyBudget;
  final String currentMonth;
  final VoidCallback? onAvatarTap;

  const BalanceCard({
    super.key,
    required this.userName,
    required this.balance,
    required this.monthlyExpense,
    required this.monthlyBudget,
    required this.currentMonth,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final budgetFraction = monthlyBudget > 0
        ? (monthlyExpense / monthlyBudget).clamp(0.0, 1.0)
        : 0.0;
    final budgetPct = (budgetFraction * 100).toStringAsFixed(0);
    final isOverBudget = monthlyExpense > monthlyBudget && monthlyBudget > 0;

    // Split balance into integer and decimal parts
    final balStr = Formatter.currency(balance.abs());
    final sign = balance < 0 ? '-' : '';

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1BA589), Color(0xFF0D7A6B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Greeting row ──────────────────────────────────
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hi, ${userName.split(' ').first}!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    currentMonth,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              GestureDetector(
                onTap: onAvatarTap,
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // ── Balance ───────────────────────────────────────
          Text(
            'Current Balance',
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 12,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$sign${balStr.split('.').first}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.5,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '.${balStr.contains('.') ? balStr.split('.').last : '00'}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Monthly Budget card ───────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Monthly Budget',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: budgetFraction,
                    minHeight: 6,
                    backgroundColor: Colors.white.withOpacity(0.25),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isOverBudget ? const Color(0xFFFFD93D) : Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${Formatter.currency(monthlyExpense)} / ${Formatter.currency(monthlyBudget)}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      isOverBudget ? 'Over budget!' : '$budgetPct%',
                      style: TextStyle(
                        color: isOverBudget
                            ? const Color(0xFFFFD93D)
                            : Colors.white.withOpacity(0.8),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
