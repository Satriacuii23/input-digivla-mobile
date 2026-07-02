import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/responsive.dart';
import '../../config/theme.dart';
import '../../core/auth/auth_provider.dart';
import '../../models/user.dart';
import '../../services/dashboard_service.dart';
import '../../widgets/account_menu.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/digivla_logo.dart';
import '../../widgets/digivla_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DashboardStats? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<AuthProvider>().api;
      final stats = await DashboardService(api).fetchStats();
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final pad = AppResponsive.pagePadding(context);
    final gridCols = AppResponsive.quickActionColumns(context);

    return HomeShell(
      child: RefreshIndicator(
        onRefresh: _loadStats,
        color: AppColors.navy,
        child: ListView(
          padding: EdgeInsets.fromLTRB(pad, pad, pad, 24),
          children: [
            _HomeTopBar(user: user, onRefresh: _loadStats),
            const SizedBox(height: 8),
            const PageHeader(
              title: 'Dashboard',
              description: 'Summary of TV, Radio, Online articles and total media.',
            ),
            const SizedBox(height: 20),
            if (_loading)
              const LoadingView(message: 'Loading statistics', subtitle: 'Fetching dashboard data…')
            else if (_error != null)
              DigivlaCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Failed to load statistics', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.navy)),
                    const SizedBox(height: 8),
                    Text(_error!, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    OutlinedButton(onPressed: _loadStats, child: const Text('Try again')),
                  ],
                ),
              )
            else if (_stats != null) ...[
              _StatGrid(stats: _stats!, user: user),
              const SizedBox(height: 20),
              _TodayActivityCard(stats: _stats!, user: user),

            ],
          ],
        ),
      ),
    );
  }
}

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar({required this.user, required this.onRefresh});

  final UserModel? user;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final compact = AppResponsive.isCompact(context);

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: DigivlaLogo()),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Home', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.navy)),
                    if (user != null)
                      Text(
                        'Hello, ${user!.displayName}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const AccountMenuButton(),
              IconButton(icon: const Icon(Icons.refresh_outlined), tooltip: 'Refresh', onPressed: onRefresh),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        const DigivlaLogoImage(height: 34, maxWidth: 160),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Home', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.navy)),
              if (user != null)
                Text(
                  'Hello, ${user!.displayName} · ${user!.roleLabel}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        const AccountMenuButton(),
        IconButton(icon: const Icon(Icons.refresh_outlined), tooltip: 'Refresh', onPressed: onRefresh),
      ],
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.stats, this.user});

  final DashboardStats stats;
  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    final showTv = user?.canAccessRoute('/tv') ?? true;
    final showRadio = user?.canAccessRoute('/radio') ?? true;
    final showOnline = user?.canAccessRoute('/online') ?? true;
    final showMedia = user?.canAccessRoute('/media') ?? true;

    final cards = <Widget>[];
    if (showTv) {
      cards.add(_StatCard(title: 'TV Articles', total: stats.totalTv, today: stats.todayTv, icon: Icons.tv_outlined));
    }
    if (showRadio) {
      cards.add(_StatCard(title: 'Radio', total: stats.totalRadio, today: stats.todayRadio, icon: Icons.radio_outlined));
    }
    if (showOnline) {
      cards.add(_StatCard(title: 'Online', total: stats.totalOnline, today: stats.todayOnline, icon: Icons.language_outlined));
    }
    if (showMedia) {
      cards.add(_StatCard(title: 'Media', total: stats.totalMedia, today: null, icon: Icons.storage_outlined));
    }

    if (cards.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        for (var i = 0; i < cards.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: cards[i]),
              if (i + 1 < cards.length) ...[
                const SizedBox(width: 10),
                Expanded(child: cards[i + 1]),
              ] else
                const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.total, required this.icon, this.today});

  final String title;
  final int total;
  final int? today;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DigivlaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.navy),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
            ],
          ),
          const SizedBox(height: 12),
          Text('$total', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.navy)),
          if (today != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('+$today today', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ),
        ],
      ),
    );
  }
}

class _TodayActivityCard extends StatelessWidget {
  const _TodayActivityCard({required this.stats, required this.user});

  final DashboardStats stats;
  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    final todayTotal = stats.todayTv + stats.todayRadio + stats.todayOnline;
    final canUploadTv = user?.canWriteChannel('tv') ?? false;
    final canUploadRadio = user?.canWriteChannel('radio') ?? false;
    final canUploadOnline = user?.canWriteChannel('online') ?? false;
    
    String? defaultUploadRoute;
    if (canUploadOnline) defaultUploadRoute = '/online/upload';
    else if (canUploadTv) defaultUploadRoute = '/tv/upload';
    else if (canUploadRadio) defaultUploadRoute = '/radio/upload';

    return DigivlaCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.navy.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.show_chart, color: AppColors.navy, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Today's Activity",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.navy),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$todayTotal articles uploaded today',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _ActivityMiniStat(label: 'TV', count: stats.todayTv),
              const SizedBox(width: 12),
              _ActivityMiniStat(label: 'Radio', count: stats.todayRadio),
              const SizedBox(width: 12),
              _ActivityMiniStat(label: 'Online', count: stats.todayOnline),
            ],
          ),
          if (defaultUploadRoute != null) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.push(defaultUploadRoute!),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add_circle_outline, size: 20),
                label: const Text('Upload Article', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActivityMiniStat extends StatelessWidget {
  const _ActivityMiniStat({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('$count', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.navy)),
          ],
        ),
      ),
    );
  }
}
