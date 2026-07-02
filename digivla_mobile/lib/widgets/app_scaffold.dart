import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../config/nav_config.dart';
import '../config/theme.dart';
import '../core/auth/auth_provider.dart';
import '../core/auth/rbac.dart';
import 'digivla_logo.dart';
import 'account_menu.dart';

// ═══════════════════════════════════════════════════════════════
//  Bottom navigation tabs (Media, TV, Radio, Online)
// ═══════════════════════════════════════════════════════════════

/// Shared bottom navigation routes.
class DigivlaNav {
  static const tabs = [
    _TabDef(label: 'Home', route: '/home', icon: Icons.home_outlined, activeIcon: Icons.home),
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

// ═══════════════════════════════════════════════════════════════
//  Navy sidebar drawer — mirrors Frontend admin-layout.tsx
// ═══════════════════════════════════════════════════════════════

class DigivlaDrawer extends StatefulWidget {
  const DigivlaDrawer({super.key});

  @override
  State<DigivlaDrawer> createState() => _DigivlaDrawerState();
}

class _DigivlaDrawerState extends State<DigivlaDrawer> {
  String? _openGroup;

  @override
  void initState() {
    super.initState();
    _openGroup = _groupKeyFromRoute(_currentRoute);
  }

  String get _currentRoute {
    try {
      return GoRouterState.of(context).uri.path;
    } catch (_) {
      return '/home';
    }
  }

  String? _groupKeyFromRoute(String path) {
    if (path.startsWith('/users')) return 'users';
    if (path.startsWith('/media')) return 'media';
    if (path.startsWith('/qc')) return 'qc';
    if (path.startsWith('/tools')) return 'tools';
    if (path.startsWith('/tv')) return 'tv';
    if (path.startsWith('/radio')) return 'radio';
    if (path.startsWith('/online')) return 'online';
    return null;
  }

  bool _isActive(String route) {
    final current = _currentRoute;
    return current == route || current.startsWith('$route/');
  }

  void _navigate(String route) {
    Navigator.of(context).pop();
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final items = NavConfig.itemsForRole(user?.role);

    return Drawer(
      backgroundColor: AppColors.navy,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
              ),
              child: Image.asset(
                'assets/logo/digivla_logo.png',
                height: 48,
                fit: BoxFit.contain,
                alignment: Alignment.centerLeft,
              ),
            ),

            // ── Navigation ──
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: [
                  for (final item in items) _buildItem(item),
                ],
              ),
            ),

            // ── Profile footer ──
            if (user != null)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.white.withValues(alpha: 0.15),
                            child: Text(
                              user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.displayName,
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  user.roleLabel,
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await auth.logout();
                          if (context.mounted) context.go('/login');
                        },
                        icon: Icon(Icons.logout, size: 18, color: Colors.white.withValues(alpha: 0.7)),
                        label: Text(
                          'Logout',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                        ),
                        style: TextButton.styleFrom(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(NavItem item) {
    if (item is NavSection) return _buildSection(item);
    if (item is NavLink) return _buildLink(item);
    if (item is NavGroup) return _buildGroup(item);
    return const SizedBox.shrink();
  }

  Widget _buildSection(NavSection section) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 6),
      child: Text(
        section.label.toUpperCase(),
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.35),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildLink(NavLink link) {
    final active = _isActive(link.route);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: active ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => _navigate(link.route),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(link.icon, size: 18, color: active ? AppColors.navy : Colors.white.withValues(alpha: 0.7)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        link.label,
                        style: TextStyle(
                          color: active ? AppColors.navy : Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (link.description != null)
                        Text(
                          link.description!,
                          style: TextStyle(
                            color: active ? AppColors.navy.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.4),
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroup(NavGroup group) {
    final isOpen = _openGroup == group.key;
    final groupActive = group.children.any((c) => _isActive(c.route));

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Column(
        children: [
          Material(
            color: groupActive ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: () => setState(() => _openGroup = isOpen ? null : group.key),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Icon(group.icon, size: 18, color: groupActive ? Colors.white : Colors.white.withValues(alpha: 0.7)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.label,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: groupActive ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                          if (group.description != null)
                            Text(
                              group.description!,
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10),
                            ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: isOpen ? 0.25 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.chevron_right, size: 16, color: Colors.white.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Children
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: isOpen ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: Container(
              margin: const EdgeInsets.only(left: 16, top: 2),
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
              ),
              child: Column(
                children: group.children.map((child) {
                  final childActive = _isActive(child.route);
                  return Material(
                    color: childActive ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: () => _navigate(child.route),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              child.label,
                              style: TextStyle(
                                color: childActive ? AppColors.navy : Colors.white.withValues(alpha: 0.65),
                                fontSize: 12,
                                fontWeight: childActive ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                            if (child.description != null)
                              Text(
                                child.description!,
                                style: TextStyle(
                                  color: childActive ? AppColors.navy.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.3),
                                  fontSize: 10,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Beranda button (Home pill)
// ═══════════════════════════════════════════════════════════════

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

// ═══════════════════════════════════════════════════════════════
//  Bottom navigation bar
// ═══════════════════════════════════════════════════════════════

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

// ═══════════════════════════════════════════════════════════════
//  Shell widgets — with drawer + bottom nav
// ═══════════════════════════════════════════════════════════════

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
      drawer: const DigivlaDrawer(),
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
      drawer: const DigivlaDrawer(),
      body: SafeArea(bottom: false, child: child),
      bottomNavigationBar: DigivlaBottomNavBar(
        tabs: tabs,
        selectedIndex: -1,
        onDestinationSelected: (i) => context.go(tabs[i].route),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Page scaffolds — with drawer hamburger menu
// ═══════════════════════════════════════════════════════════════

/// List tab page — hamburger + Beranda pill + logo, SafeArea content.
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
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            tooltip: 'Menu',
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            if (subtitle != null)
              Text(subtitle!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w400)),
          ],
        ),
        actions: [
          const AccountMenuButton(),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Image.asset(
              'assets/logo/digivla_logo.png',
              height: 28,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
      drawer: const DigivlaDrawer(),
      floatingActionButton: floatingActionButton,
      body: SafeArea(top: false, child: body),
    );
  }
}

/// Secondary pages — upload, preview, edit (back + hamburger).
class PageScaffold extends StatelessWidget {
  const PageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.actions,
    this.showHome = true,
    this.floatingActionButton,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final List<Widget>? actions;
  final bool showHome;
  final Widget? floatingActionButton;

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
      floatingActionButton: floatingActionButton,
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
