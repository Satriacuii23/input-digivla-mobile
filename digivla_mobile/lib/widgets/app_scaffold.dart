import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../core/auth/auth_provider.dart';
import '../core/auth/rbac.dart';
import 'digivla_logo.dart';
import 'account_menu.dart';

/// Shared bottom navigation routes.
class DigivlaNav {
  static const tabs = [
    _TabDef(label: 'Media', route: '/media', icon: Icons.storage_outlined, activeIcon: Icons.storage),
    _TabDef(label: 'TV', route: '/tv', icon: Icons.tv_outlined, activeIcon: Icons.tv),
    _TabDef(label: 'Radio', route: '/radio', icon: Icons.radio_outlined, activeIcon: Icons.radio),
    _TabDef(label: 'Online', route: '/online', icon: Icons.language_outlined, activeIcon: Icons.language),
  ];

  static List<_TabDef> tabsForRole(String? role) {
    final routes = UserRbac.allowedTabRoutes(role);
    return tabs.where((tab) => routes.contains(tab.route)).toList();
  }

  static int indexForRoute(String location, List<_TabDef> visibleTabs) {
    for (var i = 0; i < visibleTabs.length; i++) {
      final route = visibleTabs[i].route;
      if (location == route || location.startsWith('$route/')) return i;
    }
    return -1;
  }
}

class _TabDef {
  const _TabDef({required this.label, required this.route, required this.icon, required this.activeIcon});
  final String label;
  final String route;
  final IconData icon;
  final IconData activeIcon;
}

/// Beranda button — pill style for app bar.
class HomeNavButton extends StatelessWidget {
  const HomeNavButton({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Material(
        color: AppColors.navy.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => context.go('/home'),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.dashboard_outlined, size: compact ? 18 : 20, color: AppColors.navy),
                if (!compact) ...[
                  const SizedBox(width: 6),
                  const Text('Home', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.navy)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom nav bar — Media, TV, Radio, Online. [selectedIndex] null = none (home page).
class DigivlaBottomNavBar extends StatelessWidget {
  const DigivlaBottomNavBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    this.onDestinationSelected,
  });

  final List<_TabDef> tabs;
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    if (tabs.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              for (var i = 0; i < tabs.length; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                Expanded(child: _NavItem(
                  tab: tabs[i],
                  selected: selectedIndex == i,
                  onTap: () {
                    if (onDestinationSelected != null) {
                      onDestinationSelected!(i);
                    } else {
                      context.go(tabs[i].route);
                    }
                  },
                )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.tab, required this.selected, required this.onTap});

  final _TabDef tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.navy.withValues(alpha: 0.08) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(selected ? tab.activeIcon : tab.icon, size: 22, color: selected ? AppColors.navy : AppColors.textMuted),
              const SizedBox(height: 4),
              Text(
                tab.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? AppColors.navy : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shell with bottom navigation — Media, TV, Radio, Online.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final tabs = DigivlaNav.tabsForRole(auth.user?.role);
    final location = GoRouterState.of(context).uri.path;
    final selectedIndex = DigivlaNav.indexForRoute(location, tabs);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(bottom: false, child: navigationShell),
      bottomNavigationBar: DigivlaBottomNavBar(
        tabs: tabs,
        selectedIndex: selectedIndex,
        onDestinationSelected: (i) => context.go(tabs[i].route),
      ),
    );
  }
}

/// Beranda wrapper with same bottom nav (no tab selected).
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final tabs = DigivlaNav.tabsForRole(auth.user?.role);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(bottom: false, child: child),
      bottomNavigationBar: DigivlaBottomNavBar(
        tabs: tabs,
        selectedIndex: -1,
        onDestinationSelected: (i) => context.go(tabs[i].route),
      ),
    );
  }
}

/// List tab page — Beranda pill + logo, SafeArea content.
class TabPageScaffold extends StatelessWidget {
  const TabPageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.floatingActionButton,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leadingWidth: 100,
        leading: const Padding(
          padding: EdgeInsets.only(left: 8),
          child: HomeNavButton(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            if (subtitle != null)
              Text(subtitle!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w400)),
          ],
        ),
        actions: const [
          AccountMenuButton(),
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: DigivlaLogoIcon(size: 32),
          ),
        ],
      ),
      floatingActionButton: floatingActionButton,
      body: SafeArea(top: false, child: body),
    );
  }
}

/// Secondary pages — upload, preview, edit (back + Beranda).
class PageScaffold extends StatelessWidget {
  const PageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.actions,
    this.showHome = true,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final List<Widget>? actions;
  final bool showHome;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            if (subtitle != null)
              Text(subtitle!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          if (showHome) const HomeNavButton(compact: true),
          const AccountMenuButton(),
          ...?actions,
        ],
      ),
      body: SafeArea(top: false, child: body),
    );
  }
}

/// Full-page SafeArea wrapper (login).
class SafePage extends StatelessWidget {
  const SafePage({super.key, required this.child, this.backgroundColor});

  final Widget child;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.background,
      body: SafeArea(child: child),
    );
  }
}
