import 'package:flutter/material.dart';
import '../../../core/utils/app_theme.dart';

class ProfileHeader extends StatelessWidget {
  final String displayName, email, monthYear;
  const ProfileHeader({
    super.key,
    required this.displayName,
    required this.email,
    required this.monthYear,
  });

  @override
  Widget build(BuildContext context) {
    final initial = displayName.isNotEmpty
        ? displayName[0].toUpperCase() : 'U';

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1BA589), Color(0xFF0D7A6B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
            color: Colors.white, fontSize: 20,
            fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(monthYear, style: TextStyle(
            color: Colors.white.withOpacity(0.7), fontSize: 13)),
      ]),
    );
  }
}