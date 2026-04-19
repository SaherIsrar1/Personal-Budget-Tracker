import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/utils/app_theme.dart';
import '../../../logic/providers/auth_provider.dart';

class AccountDetailsSheet extends StatefulWidget {
  final AuthProvider auth;  // ✅ accepts auth
  const AccountDetailsSheet({super.key, required this.auth});

  @override
  State<AccountDetailsSheet> createState() => _AccountDetailsSheetState();
}

class _AccountDetailsSheetState extends State<AccountDetailsSheet> {
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
    await FirestoreService()
        .updateUserSetting(widget.auth.uid, 'displayName', name);
    await widget.auth.updateDisplayName(name);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Profile updated!'),
        backgroundColor: AppTheme.primary,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(color: AppTheme.cardBorder,
                borderRadius: BorderRadius.circular(99)),
          )),
          Text('Account Details',
              style: AppTheme.titleLarge.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          const Text('FULL NAME', style: TextStyle(fontSize: 10,
              fontWeight: FontWeight.w700, letterSpacing: 1,
              color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            style: AppTheme.bodyLarge,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'Your full name'),
          ),
          const SizedBox(height: 16),
          const Text('EMAIL', style: TextStyle(fontSize: 10,
              fontWeight: FontWeight.w700, letterSpacing: 1,
              color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Row(children: [
              const Icon(Icons.lock_outline, size: 16, color: AppTheme.textHint),
              const SizedBox(width: 8),
              Expanded(child: Text(widget.auth.email, style: AppTheme.bodyMedium)),
              Text('Read-only', style: AppTheme.labelSmall.copyWith(fontSize: 10)),
            ]),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity, height: 52,
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
        ],
      ),
    );
  }
}