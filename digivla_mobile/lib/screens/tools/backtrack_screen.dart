import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/digivla_widgets.dart';

/// Backtrack — placeholder matching web (next iteration).
class BacktrackScreen extends StatelessWidget {
  const BacktrackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PageScaffold(
      title: 'Backtrack',
      subtitle: 'Article backtrack lookup',
      body: Padding(
        padding: EdgeInsets.all(16),
        child: DigivlaCard(
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
              SizedBox(height: 12),
              Text(
                'Article backtrack lookup is planned for a future release — same status as the web Backtrack tool.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
