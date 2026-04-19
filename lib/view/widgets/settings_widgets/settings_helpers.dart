import 'package:flutter/material.dart';
import '../../../core/utils/app_theme.dart';
import '../../../logic/providers/auth_provider.dart';
import '../../../router/app_router.dart';

// ── Sign Out Button ───────────────────────────────────────────────
class SignOutButton extends StatelessWidget {
  final AuthProvider auth;  // ✅ accepts auth
  const SignOutButton({super.key, required this.auth});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
          if (confirmed == true && context.mounted) {
            await auth.signOut();
            Navigator.of(context)
                .pushReplacementNamed(AppRouter.signIn);
          }
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
}

// ── Section Title ─────────────────────────────────────────────────
class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
    child: Text(title,
        style: AppTheme.labelSmall.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1)),
  );
}

// ── Settings Card ─────────────────────────────────────────────────
class SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const SettingsCard({super.key, required this.children});

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

// ── Settings Tile ─────────────────────────────────────────────────
class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        SettingsIconBox(icon: icon),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary)),
            Text(subtitle,
                style: AppTheme.bodyMedium.copyWith(fontSize: 12)),
          ],
        )),
        const Icon(Icons.chevron_right,
            color: AppTheme.textHint, size: 18),
      ]),
    ),
  );
}

// ── Icon Box ──────────────────────────────────────────────────────
class SettingsIconBox extends StatelessWidget {
  final IconData icon;
  const SettingsIconBox({super.key, required this.icon});

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

// ── Divider ───────────────────────────────────────────────────────
class SettingsDivider extends StatelessWidget {
  const SettingsDivider({super.key});

  @override
  Widget build(BuildContext context) => const Divider(
      height: 1, thickness: 1,
      color: AppTheme.cardBorder, indent: 66);
}