import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/services/firestore_service.dart';
import '../../core/utils/app_theme.dart';
import '../../core/utils/formatter.dart';
import '../../logic/providers/auth_provider.dart';
import '../../logic/providers/dashboard_provider.dart';
import '../../core/services/notification_service.dart';
import '../../router/app_router.dart';

class SettingsProfileScreen extends StatefulWidget {
  const SettingsProfileScreen({super.key});

  @override
  State<SettingsProfileScreen> createState() => _SettingsProfileScreenState();
}

class _SettingsProfileScreenState extends State<SettingsProfileScreen> {
  bool _notificationsEnabled = true;
  String _selectedCurrency = 'USD (\$)';
  bool _isLoading = true;

  final List<String> _currencies = [
    'USD (\$)', 'EUR (€)', 'GBP (£)', 'PKR (₨)', 'INR (₹)', 'AED (د.إ)',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = context.read<AuthProvider>().uid;
    if (uid.isEmpty) { setState(() => _isLoading = false); return; }
    final profile = await FirestoreService().getUserProfile(uid);
    if (mounted) {
      setState(() {
        _isLoading = false;
        _notificationsEnabled = profile?['notificationsEnabled'] as bool? ?? true;
        _selectedCurrency = profile?['currency'] as String? ?? 'USD (\$)';
      });
    }
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final uid = context.read<AuthProvider>().uid;
    if (uid.isEmpty) return;
    try { await FirestoreService().updateUserSetting(uid, key, value); } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final dash = context.watch<DashboardProvider>();
    final initial = auth.displayName.isNotEmpty
        ? auth.displayName[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  _ProfileHeader(
                    initial: initial,
                    displayName: auth.displayName,
                    email: auth.email,
                    monthYear: Formatter.monthYear(DateTime.now()),
                  ),
                  const SizedBox(height: 20),

                  // Budget
                  _SectionLabel('BUDGET'),
                  _SettingsCard(children: [
                    _SettingsTile(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Monthly Budget',
                      subtitle: Formatter.currency(dash.monthlyBudget),
                      onTap: () => _showBudgetSheet(context, dash),
                    ),
                  ]),
                  const SizedBox(height: 16),

                  // Account
                  _SectionLabel('ACCOUNT'),
                  _SettingsCard(children: [
                    _SettingsTile(
                      icon: Icons.person_outline,
                      title: 'Account Details',
                      subtitle: auth.email,
                      onTap: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => _AccountDetailsSheet(auth: auth),
                      ),
                    ),
                    const _TileDivider(),
                    _SettingsTile(
                      icon: Icons.lock_outline,
                      title: 'Change Password',
                      subtitle: 'Send password reset email',
                      onTap: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => _ChangePasswordSheet(auth: auth),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),

                  // Preferences
                  _SectionLabel('PREFERENCES'),
                  _SettingsCard(children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(children: [
                        _IconBadge(Icons.notifications_outlined),
                        const SizedBox(width: 14),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Notification Preferences',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary)),
                            Text('Budget alerts & reminders',
                                style: AppTheme.bodyMedium
                                    .copyWith(fontSize: 12)),
                          ],
                        )),
                        Switch(
                          value: _notificationsEnabled,
                          thumbColor: WidgetStateProperty.all(Colors.white),
                          trackColor: WidgetStateProperty.resolveWith((s) =>
                              s.contains(WidgetState.selected)
                                  ? AppTheme.primary
                                  : AppTheme.cardBorder),
                          onChanged: (v) async {
                            setState(() => _notificationsEnabled = v);
                            _saveSetting('notificationsEnabled', v);
                            final notif = NotificationService();
                            if (v) {
                              // Schedule daily reminder at 8pm
                              await notif.scheduleDailyReminder(hour: 20, minute: 0);
                              await notif.scheduleWeeklySummary();
                            } else {
                              await notif.cancelDailyReminder();
                              await notif.cancelWeeklySummary();
                            }
                          },
                        ),
                      ]),
                    ),
                    const _TileDivider(),
                    _SettingsTile(
                      icon: Icons.attach_money_outlined,
                      title: 'Currency & Formats',
                      subtitle: _selectedCurrency,
                      onTap: () => _showCurrencyPicker(context),
                    ),
                  ]),
                  const SizedBox(height: 16),

                  // Support
                  _SectionLabel('SUPPORT'),
                  _SettingsCard(children: [
                    _SettingsTile(
                      icon: Icons.help_outline,
                      title: 'Help & Support',
                      subtitle: 'FAQs and contact',
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          _snackBar('Help center coming soon')),
                    ),
                    const _TileDivider(),
                    _SettingsTile(
                      icon: Icons.info_outline,
                      title: 'About BudgetWise',
                      subtitle: 'Version 1.0.0 • SoftTech 2025',
                      onTap: () => _showAbout(context),
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // Sign Out
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _SignOutButton(
                      onSignOut: () async {
                        await auth.signOut();
                        if (context.mounted) {
                          Navigator.of(context)
                              .pushReplacementNamed(AppRouter.signIn);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  void _showBudgetSheet(BuildContext context, DashboardProvider dash) {
    final auth = context.read<AuthProvider>();
    final ctrl = TextEditingController(
        text: dash.monthlyBudget.toStringAsFixed(0));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        bool saving = false;
        return StatefulBuilder(builder: (ctx, setS) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 24, right: 24, top: 8,
          ),
          child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: AppTheme.cardBorder,
                      borderRadius: BorderRadius.circular(99)))),
              Text('Set Monthly Budget',
                  style: AppTheme.titleLarge.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text('Track spending against your monthly limit.',
                  style: AppTheme.bodyMedium),
              const SizedBox(height: 20),
              TextField(
                controller: ctrl,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                ],
                style: AppTheme.displayMedium.copyWith(fontSize: 24),
                decoration: const InputDecoration(prefixText: '\$ ', hintText: '2000'),
              ),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: saving ? null : () async {
                    final val = double.tryParse(ctrl.text.replaceAll(',', ''));
                    if (val == null || val <= 0) return;
                    setS(() => saving = true);
                    await dash.updateBudget(auth.uid, val);
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
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
        ));
      },
    );
  }

  void _showCurrencyPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 8),
        Container(width: 40, height: 4,
            decoration: BoxDecoration(color: AppTheme.cardBorder,
                borderRadius: BorderRadius.circular(99))),
        const SizedBox(height: 16),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('Select Currency', style: AppTheme.titleLarge)),
        const SizedBox(height: 8),
        ..._currencies.map((c) => ListTile(
              title: Text(c),
              trailing: _selectedCurrency == c
                  ? const Icon(Icons.check_circle, color: AppTheme.primary) : null,
              onTap: () {
                setState(() => _selectedCurrency = c);
                _saveSetting('currency', c);
                Navigator.pop(context);
              },
            )),
        const SizedBox(height: 12),
      ]),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 64, height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryDark]),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Center(child: Text('💰', style: TextStyle(fontSize: 28)))),
          const SizedBox(height: 16),
          Text('BudgetWise', style: AppTheme.titleLarge),
          const SizedBox(height: 4),
          Text('Version 1.0.0', style: AppTheme.bodyMedium),
          const SizedBox(height: 8),
          Text('Built for SoftTech 2025\nSmart money. Better life.',
              textAlign: TextAlign.center,
              style: AppTheme.bodyMedium.copyWith(height: 1.5)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  SnackBar _snackBar(String msg) => SnackBar(
      content: Text(msg), backgroundColor: AppTheme.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)));
}

// ── Profile Header ─────────────────────────────────────────────────
class _ProfileHeader extends StatelessWidget {
  final String initial, displayName, email, monthYear;
  const _ProfileHeader({
    required this.initial, required this.displayName,
    required this.email, required this.monthYear,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1BA589), Color(0xFF0D7A6B)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Column(children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withOpacity(0.4), width: 2),
            ),
            child: Center(child: Text(initial,
                style: const TextStyle(fontSize: 32,
                    fontWeight: FontWeight.w700, color: Colors.white))),
          ),
          const SizedBox(height: 14),
          Text(displayName, style: const TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(monthYear, style: TextStyle(
              color: Colors.white.withOpacity(0.7), fontSize: 13)),
        ]),
      );
}

// ── Account Details Sheet ──────────────────────────────────────────
class _AccountDetailsSheet extends StatefulWidget {
  final AuthProvider auth;
  const _AccountDetailsSheet({required this.auth});

  @override
  State<_AccountDetailsSheet> createState() => _AccountDetailsSheetState();
}

class _AccountDetailsSheetState extends State<_AccountDetailsSheet> {
  late final TextEditingController _nameCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.auth.displayName);
  }

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    await FirestoreService().updateUserSetting(widget.auth.uid, 'displayName', name);
    await widget.auth.updateDisplayName(name);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Profile updated!'),
        backgroundColor: AppTheme.primary, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 24, right: 24, top: 8,
        ),
        child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: AppTheme.cardBorder,
                    borderRadius: BorderRadius.circular(99)))),
            Text('Account Details',
                style: AppTheme.titleLarge.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            const Text('FULL NAME', style: TextStyle(fontSize: 10,
                fontWeight: FontWeight.w700, letterSpacing: 1,
                color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            TextField(controller: _nameCtrl, style: AppTheme.bodyLarge,
                decoration: const InputDecoration(hintText: 'Your full name')),
            const SizedBox(height: 16),
            const Text('EMAIL', style: TextStyle(fontSize: 10,
                fontWeight: FontWeight.w700, letterSpacing: 1,
                color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(color: AppTheme.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.cardBorder)),
              child: Row(children: [
                const Icon(Icons.lock_outline, size: 16, color: AppTheme.textHint),
                const SizedBox(width: 8),
                Expanded(child: Text(widget.auth.email, style: AppTheme.bodyMedium)),
                Text('Read-only',
                    style: AppTheme.labelSmall.copyWith(fontSize: 10)),
              ]),
            ),
            const SizedBox(height: 28),
            SizedBox(width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: _saving
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : const Text('Save Changes',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
      );
}

// ── Change Password Sheet ──────────────────────────────────────────
class _ChangePasswordSheet extends StatefulWidget {
  final AuthProvider auth;
  const _ChangePasswordSheet({required this.auth});

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  bool _sent = false, _sending = false;

  Future<void> _send() async {
    setState(() => _sending = true);
    await widget.auth.resetPassword(widget.auth.email);
    if (mounted) setState(() { _sent = true; _sending = false; });
  }

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 36),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: AppTheme.cardBorder,
                  borderRadius: BorderRadius.circular(99)))),
          const Text('🔐', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 16),
          Text('Change Password',
              style: AppTheme.titleLarge.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            _sent ? 'Reset link sent to\n${widget.auth.email}'
                  : 'We\'ll send a reset link to\n${widget.auth.email}',
            textAlign: TextAlign.center,
            style: AppTheme.bodyMedium.copyWith(height: 1.5),
          ),
          const SizedBox(height: 28),
          if (!_sent)
            SizedBox(width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: _sending ? null : _send,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: _sending
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : const Text('Send Reset Email',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(children: [
                const Icon(Icons.check_circle, color: AppTheme.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text('Check your email inbox',
                    style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.primary, fontWeight: FontWeight.w600))),
              ]),
            ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_sent ? 'Done' : 'Cancel',
                style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
          ),
        ]),
      );
}

// ── Sign Out Button ────────────────────────────────────────────────
class _SignOutButton extends StatelessWidget {
  final VoidCallback onSignOut;
  const _SignOutButton({required this.onSignOut});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity, height: 52,
        child: OutlinedButton.icon(
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                title: const Text('Sign Out?'),
                content: const Text(
                    'You\'ll need to sign in again to access your data.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel')),
                  TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Sign Out',
                          style: TextStyle(color: AppTheme.expense))),
                ],
              ),
            );
            if (confirmed == true) onSignOut();
          },
          icon: const Icon(Icons.logout, size: 18, color: AppTheme.expense),
          label: const Text('Log Out',
              style: TextStyle(
                  color: AppTheme.expense, fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppTheme.expense, width: 1.5),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
        ),
      );
}

// ── Shared Helpers ─────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        child: Text(text, style: AppTheme.labelSmall.copyWith(
            fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
      );
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Column(children: children),
      );
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  const _SettingsTile({
    required this.icon, required this.title,
    required this.subtitle, required this.onTap,
  });
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            _IconBadge(icon),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14,
                    fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                Text(subtitle,
                    style: AppTheme.bodyMedium.copyWith(fontSize: 12)),
              ],
            )),
            const Icon(Icons.chevron_right, color: AppTheme.textHint, size: 18),
          ]),
        ),
      );
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  const _IconBadge(this.icon);
  @override
  Widget build(BuildContext context) => Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: AppTheme.primaryLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: AppTheme.primary),
      );
}

class _TileDivider extends StatelessWidget {
  const _TileDivider();
  @override
  Widget build(BuildContext context) => const Divider(
      height: 1, thickness: 1, color: AppTheme.cardBorder, indent: 66);
}
