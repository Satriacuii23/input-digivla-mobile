import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/digivla_widgets.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Tools & Helpers',
      subtitle: 'Analyst utilities',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const PageHeader(
            title: 'Tools & Helpers',
            description: 'Same menu as web Administration → Tools & Helpers.',
          ),
          const SizedBox(height: 12),
          DigivlaCard(
            onTap: () => context.push('/tools/media-reach'),
            child: const Row(
              children: [
                Icon(Icons.travel_explore_outlined, color: AppColors.navy),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Media Reach', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.navy)),
                      SizedBox(height: 4),
                      Text('SimilarWeb crawler', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.textMuted),
              ],
            ),
          ),
          const SizedBox(height: 10),
          DigivlaCard(
            onTap: () => context.push('/tools/backtrack'),
            child: const Row(
              children: [
                Icon(Icons.history_outlined, color: AppColors.navy),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Backtrack', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.navy)),
                      SizedBox(height: 4),
                      Text('Article backtrack lookup (coming soon)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.textMuted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
