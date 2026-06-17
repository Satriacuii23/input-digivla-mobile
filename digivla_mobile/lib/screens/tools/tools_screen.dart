import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/digivla_widgets.dart';

/// Tools & Helpers — fitur berat (Media Reach, Backtrack) direkomendasikan via web.
class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Tools & Helpers',
      subtitle: 'Media Reach · Backtrack',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          DigivlaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.travel_explore_outlined, color: AppColors.navy),
                    SizedBox(width: 10),
                    Text('Media Reach', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.navy)),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  'Crawler SimilarWeb dan konfigurasi selector tersedia di web IDS 2.0.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.45),
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          DigivlaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.history_outlined, color: AppColors.navy),
                    SizedBox(width: 10),
                    Text('Backtrack', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.navy)),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  'Fitur backtrack artikel tersedia di web. Gunakan browser untuk akses penuh.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.45),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Web access: http://192.168.100.66:3005',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
