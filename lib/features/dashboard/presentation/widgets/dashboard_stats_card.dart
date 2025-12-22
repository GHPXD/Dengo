import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';

/// Card com estatísticas resumidas da dengue.
///
/// Exibe métricas importantes em formato grid.
class DashboardStatsCard extends StatelessWidget {
  final int newCasesThisWeek;
  final int totalCases;
  final int predictionNextWeek;

  const DashboardStatsCard({
    super.key,
    required this.newCasesThisWeek,
    required this.totalCases,
    required this.predictionNextWeek,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estatísticas',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppConstants.spacingLg),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    icon: Icons.trending_up_rounded,
                    label: 'Novos (7 dias)',
                    value: newCasesThisWeek.toString(),
                    color: AppColors.warning,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.show_chart_rounded,
                    label: 'Total',
                    value: totalCases.toString(),
                    color: AppColors.primary,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.psychology_rounded,
                    label: 'Previsão',
                    value: '+$predictionNextWeek',
                    color: AppColors.danger,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppConstants.spacingMd),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: AppConstants.spacingSm),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}
