import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';

/// Seção de ações rápidas (navegação para outras features).
class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ações Rápidas',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppConstants.spacingMd),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: AppConstants.spacingMd,
          crossAxisSpacing: AppConstants.spacingMd,
          childAspectRatio: 1.5,
          children: [
            _QuickActionCard(
              icon: Icons.map_rounded,
              title: 'Mapa de Calor',
              color: AppColors.primary,
              onTap: () => context.push(AppRoutes.heatmap),
            ),
            _QuickActionCard(
              icon: Icons.bar_chart_rounded,
              title: 'Gráficos',
              color: AppColors.secondary,
              onTap: () {
                // TODO: Navegar para detalhes de gráficos
              },
            ),
            _QuickActionCard(
              icon: Icons.school_rounded,
              title: 'Prevenção',
              color: AppColors.success,
              onTap: () => context.push(AppRoutes.education),
            ),
            _QuickActionCard(
              icon: Icons.share_rounded,
              title: 'Compartilhar',
              color: AppColors.warning,
              onTap: () {
                // TODO: Compartilhar dados
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingMd),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingMd),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: AppConstants.spacingSm),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
