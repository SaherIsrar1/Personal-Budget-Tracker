import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/app_theme.dart';
import '../../core/utils/formatter.dart';
import '../../logic/providers/dashboard_provider.dart';
import '../../logic/providers/transaction_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _selectedTab = 0; // 0=Week 1=Month 2=Year
  final _tabs = ['Week', 'Month', 'Year'];

  @override
  Widget build(BuildContext context) {
    final txProv = context.watch<TransactionProvider>();
    final dash   = context.watch<DashboardProvider>();
    final txs    = txProv.transactions;

    final weeklyData  = dash.weeklySpending(txs);
    final categories  = dash.categoryBreakdown(txs);
    final maxSpend    = weeklyData.isEmpty ? 1.0 : weeklyData.reduce((a, b) => a > b ? a : b);
    final dayLabels   = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Spending Analysis'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Time Tab ──────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: List.generate(_tabs.length, (i) {
                  final active = _selectedTab == i;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: active ? AppTheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _tabs[i],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: active ? Colors.white : AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 20),

            // ── Bar Chart ─────────────────────────────────
            Container(
              height: 180,
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxSpend > 0 ? maxSpend * 1.3 : 100,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => AppTheme.primaryDark,
                      getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                        Formatter.currency(rod.toY),
                        const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) => Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            dayLabels[value.toInt()],
                            style: AppTheme.labelSmall.copyWith(fontSize: 10),
                          ),
                        ),
                        reservedSize: 24,
                      ),
                    ),
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: AppTheme.cardBorder,
                      strokeWidth: 0.5,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(7, (i) {
                    final isToday = i == DateTime.now().weekday - 1;
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: weeklyData[i],
                          color: isToday
                              ? AppTheme.primary
                              : AppTheme.primaryLight,
                          width: 22,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6)),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text('Top Categories', style: AppTheme.titleMedium),
            const SizedBox(height: 12),

            // ── Category Breakdown ────────────────────────
            categories.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: Center(
                      child: Column(children: [
                        const Text('📊', style: TextStyle(fontSize: 36)),
                        const SizedBox(height: 8),
                        Text('No spending data yet',
                            style: AppTheme.bodyMedium),
                      ]),
                    ),
                  )
                : Column(
                    children: categories.map((cs) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.cardBorder),
                        ),
                        child: Row(children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(cs.category.icon,
                                  style: const TextStyle(fontSize: 18)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(cs.category.name,
                                        style: AppTheme.titleMedium
                                            .copyWith(fontSize: 13)),
                                    Text(Formatter.currency(cs.total),
                                        style: AppTheme.titleMedium
                                            .copyWith(fontSize: 13)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(99),
                                  child: LinearProgressIndicator(
                                    value: cs.percentage,
                                    minHeight: 5,
                                    backgroundColor: AppTheme.primaryLight,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                            AppTheme.primary),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  Formatter.percentage(cs.percentage),
                                  style: AppTheme.labelSmall
                                      .copyWith(fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ]),
                      );
                    }).toList(),
                  ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
