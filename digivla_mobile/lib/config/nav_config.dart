import 'package:flutter/material.dart';

import '../core/auth/rbac.dart';

/// Navigation structure aligned with web sidebar (rbac.ts ALL_NAV_ITEMS).
/// Sectioned groups mirroring Frontend/V2 admin-layout.tsx.

// ─── Nav data types ───────────────────────────────────────────

sealed class NavItem {
  const NavItem();
}

/// Section header — "Overview", "Content Management", etc.
class NavSection extends NavItem {
  const NavSection({required this.label});
  final String label;
}

/// Single link — Dashboard.
class NavLink extends NavItem {
  const NavLink({
    required this.label,
    required this.route,
    required this.icon,
    this.description,
  });
  final String label;
  final String route;
  final IconData icon;
  final String? description;
}

/// Expandable group — Media, TV, Radio, Online, QC, Users, Tools.
class NavGroup extends NavItem {
  const NavGroup({
    required this.key,
    required this.label,
    required this.icon,
    required this.children,
    this.description,
  });
  final String key;
  final String label;
  final IconData icon;
  final List<NavChild> children;
  final String? description;
}

class NavChild {
  const NavChild({
    required this.label,
    required this.route,
    this.description,
  });
  final String label;
  final String route;
  final String? description;
}

// ─── Static catalog ───────────────────────────────────────────

/// Full nav catalog — mirrors Frontend/V2 src/lib/auth/rbac.ts ALL_NAV_ITEMS.
const List<NavItem> _allNavItems = [
  NavSection(label: 'Overview'),
  NavLink(
    label: 'Dashboard',
    route: '/home',
    icon: Icons.dashboard_outlined,
    description: 'Stats & quick actions',
  ),
  NavSection(label: 'Content'),
  NavGroup(
    key: 'media',
    label: 'Media',
    icon: Icons.storage_outlined,
    description: 'Master media database',
    children: [
      NavChild(label: 'Media List', route: '/media', description: 'Browse & search outlets'),
      NavChild(label: 'Add Media', route: '/media/add', description: 'Register a new outlet'),
    ],
  ),
  NavGroup(
    key: 'tv',
    label: 'TV',
    icon: Icons.tv_outlined,
    description: 'Television articles',
    children: [
      NavChild(label: 'Article List', route: '/tv', description: 'View TV clippings'),
      NavChild(label: 'Upload Article', route: '/tv/upload', description: 'Submit new TV entry'),
    ],
  ),
  NavGroup(
    key: 'radio',
    label: 'Radio',
    icon: Icons.radio_outlined,
    description: 'Radio broadcast articles',
    children: [
      NavChild(label: 'Article List', route: '/radio', description: 'View radio clippings'),
      NavChild(label: 'Upload Article', route: '/radio/upload', description: 'Submit new radio entry'),
    ],
  ),
  NavGroup(
    key: 'online',
    label: 'Online',
    icon: Icons.language_outlined,
    description: 'Digital & web articles',
    children: [
      NavChild(label: 'Article List', route: '/online', description: 'View online articles'),
      NavChild(label: 'Upload Article', route: '/online/upload', description: 'Submit new online entry'),
    ],
  ),

];

// ─── Filtered catalog ─────────────────────────────────────────

class NavConfig {
  /// Return the RBAC-filtered nav catalog for [role].
  /// Sections with no visible children are stripped.
  static List<NavItem> itemsForRole(String? role) {
    final filtered = <NavItem>[];
    NavSection? pending;

    void flushSection() {
      if (pending != null) {
        filtered.add(pending!);
        pending = null;
      }
    }

    for (final item in _allNavItems) {
      if (item is NavSection) {
        pending = item;
        continue;
      }
      if (item is NavLink) {
        if (!UserRbac.canAccessRoute(role, item.route)) continue;
        flushSection();
        filtered.add(item);
        continue;
      }
      if (item is NavGroup) {
        final children = item.children
            .where((c) => UserRbac.canAccessRoute(role, c.route))
            .toList();
        if (children.isEmpty) continue;
        flushSection();
        filtered.add(NavGroup(
          key: item.key,
          label: item.label,
          icon: item.icon,
          description: item.description,
          children: children,
        ));
      }
    }
    return filtered;
  }

  /// Legacy flat list (still used by bottom nav / quick reference).
  static List<NavEntry> entriesForRole(String? role) {
    final all = <NavEntry>[
      const NavEntry(label: 'Dashboard', route: '/home', icon: Icons.dashboard_outlined),
      const NavEntry(label: 'Media List', route: '/media', icon: Icons.list_alt_outlined),
      const NavEntry(label: 'Add Media', route: '/media/add', icon: Icons.add_circle_outline),
      const NavEntry(label: 'TV Articles', route: '/tv', icon: Icons.tv_outlined),
      const NavEntry(label: 'Radio Articles', route: '/radio', icon: Icons.radio_outlined),
      const NavEntry(label: 'Online Articles', route: '/online', icon: Icons.language_outlined),

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
