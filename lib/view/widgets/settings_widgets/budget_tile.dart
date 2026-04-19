import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/formatter.dart';
import 'settings_helpers.dart';

class BudgetTile extends StatelessWidget {
  final double currentBudget;
  final Future<void> Function(double) onSave;
  const BudgetTile({
    super.key,
    required this.currentBudget,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsCard(children: [
      SettingsTile(
        icon: Icons.account_balance_wallet_outlined,
        title: 'Monthly Budget',
        subtitle: Formatter.currency(currentBudget),
        onTap: () => _showSheet(context),
      ),
    ]);
  }

  void _showSheet(BuildContext context) {
    final ctrl = TextEditingController(
        text: currentBudget.toStringAsFixed(0));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        bool saving = false;
        return StatefulBuilder(
          builder: (ctx, setS) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius:
              BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              left: 24, right: 24, top: 8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                      color: AppTheme.cardBorder,
                      borderRadius: BorderRadius.circular(99)),
                )),
                Text('Set Monthly Budget',
                    style: AppTheme.titleLarge
                        .copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('Track spending against your monthly limit.',
                    style: AppTheme.bodyMedium),
                const SizedBox(height: 20),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'[0-9.]'))
                  ],
                  style: AppTheme.displayMedium.copyWith(fontSize: 24),
                  decoration: const InputDecoration(
                      prefixText: '\$ ', hintText: '2000'),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: saving ? null : () async {
                      final val = double.tryParse(
                          ctrl.text.replaceAll(',', ''));
                      if (val == null || val <= 0) return;
                      setS(() => saving = true);
                      await onSave(val);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: saving
                        ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                        : const Text('Save Budget',
                        style: TextStyle(fontSize: 15,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}