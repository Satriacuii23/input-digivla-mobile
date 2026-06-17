import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../core/auth/auth_provider.dart';

/// Tombol akun + logout di header Beranda.
class AccountMenuButton extends StatelessWidget {
  const AccountMenuButton({super.key});

  Future<void> _logout(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    await auth.logout();
    if (context.mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      tooltip: 'Account',
      offset: const Offset(0, 40),
      onSelected: (value) {
        if (value == 'logout') _logout(context);
      },
      itemBuilder: (ctx) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.navy)),
              Text(user.roleLabel, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 18, color: AppColors.error),
              SizedBox(width: 8),
              Text('Logout', style: TextStyle(color: AppColors.error)),
            ],
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.navy.withValues(alpha: 0.1),
          child: Text(
            user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
            style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ),
      ),
    );
  }
}
