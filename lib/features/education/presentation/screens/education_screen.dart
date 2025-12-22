import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/widgets/app_bottom_nav.dart';

/// Tela de Educação/Prevenção (Placeholder).
///
/// TODO: Implementar cards de prevenção, sistema de favoritos.
class EducationScreen extends StatelessWidget {
  const EducationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prevenção'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultHorizontalPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.school_rounded,
                size: 120,
                color: AppColors.success.withOpacity(0.5),
              ),
              const SizedBox(height: AppConstants.spacingXl),
              Text(
                'Educação e Prevenção',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppConstants.spacingMd),
              Text(
                'Aprenda como prevenir e combater a dengue com informações validadas.',
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
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 2),
    );
  }
}
