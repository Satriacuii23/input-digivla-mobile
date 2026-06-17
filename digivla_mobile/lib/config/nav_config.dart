import 'package:flutter/material.dart';

import '../core/auth/rbac.dart';

/// Navigation structure aligned with web sidebar (rbac.ts ALL_NAV_ITEMS).
/// Used for reference; runtime nav uses [UserRbac] in app_scaffold / app_router.
class NavConfig {
  static List<NavEntry> entriesForRole(String? role) {
    final all = <NavEntry>[
      const NavEntry(label: 'Dashboard', route: '/home', icon: Icons.dashboard_outlined),
      const NavEntry(label: 'Media List', route: '/media', icon: Icons.list_alt_outlined),
      const NavEntry(label: 'Add Media', route: '/media/add', icon: Icons.add_circle_outline),
      const NavEntry(label: 'TV Articles', route: '/tv', icon: Icons.tv_outlined),
      const NavEntry(label: 'Radio Articles', route: '/radio', icon: Icons.radio_outlined),
      const NavEntry(label: 'Online Articles', route: '/online', icon: Icons.language_outlined),
      const NavEntry(label: 'QC TV', route: '/qc/tv', icon: Icons.fact_check_outlined),
      const NavEntry(label: 'QC Radio', route: '/qc/radio', icon: Icons.fact_check_outlined),
      const NavEntry(label: 'QC Online', route: '/qc/online', icon: Icons.fact_check_outlined),
      const NavEntry(label: 'User Management', route: '/users', icon: Icons.manage_accounts_outlined),
      const NavEntry(label: 'Tools', route: '/tools', icon: Icons.build_outlined),
    ];
    return all.where((e) => UserRbac.canAccessRoute(role, e.route)).toList();
  }
}

class NavEntry {
  const NavEntry({
    required this.label,
    required this.route,
    required this.icon,
    this.activeIcon,
  });

  final String label;
  final String route;
  final IconData icon;
  final IconData? activeIcon;
}
