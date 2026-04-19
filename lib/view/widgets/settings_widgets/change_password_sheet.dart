import 'package:flutter/material.dart';
import '../../../core/utils/app_theme.dart';
import '../../../logic/providers/auth_provider.dart';

class ChangePasswordSheet extends StatefulWidget {
  final AuthProvider auth;  // ✅ accepts auth
  const ChangePasswordSheet({super.key, required this.auth});

  @override
  State<ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<ChangePasswordSheet> {
  bool _sent = false, _sending = false;

  Future<void> _send() async {
    setState(() => _sending = true);
    await widget.auth.resetPassword(widget.auth.email);
    if (mounted) setState(() { _sent = true; _sending = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 36),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(
          width: 40, height: 4,
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(color: AppTheme.cardBorder,
              borderRadius: BorderRadius.circular(99)),
        )),
        const Text('🔐', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 16),
        Text('Change Password',
            style: AppTheme.titleLarge.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(
          _sent
              ? 'Reset link sent to\n${widget.auth.email}'
              : 'We\'ll send a reset link to\n${widget.auth.email}',
          textAlign: TextAlign.center,
          style: AppTheme.bodyMedium.copyWith(height: 1.5),
        ),
        const SizedBox(height: 28),
        if (!_sent)
          SizedBox(
            width: double.infinity, height: 52,
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
}