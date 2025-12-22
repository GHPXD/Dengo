import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/widgets/app_bottom_nav.dart';

/// Tela do Mapa de Calor (Placeholder).
///
/// TODO: Implementar integração com Flutter_Map e overlay de heatmap.
class HeatmapScreen extends StatelessWidget {
  const HeatmapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Calor'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultHorizontalPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.map_rounded,
                size: 120,
                color: AppColors.primary.withOpacity(0.5),
              ),
              const SizedBox(height: AppConstants.spacingXl),
              Text(
                'Mapa de Calor',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppConstants.spacingMd),
              Text(
                'Visualize a distribuição geográfica dos casos de dengue em sua região.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: AppConstants.spacingXl),
              Chip(
                label: const Text('Em desenvolvimento'),
                backgroundColor: AppColors.warning.withOpacity(0.2),
                labelStyle: TextStyle(color: AppColors.warning),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 1),
    );
  }
}
