import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/enums/risk_level.dart';

/// Card Hero que exibe o nível de risco atual.
///
/// Design de destaque no Dashboard, usando gradiente semântico
/// baseado no nível de risco (verde/amarelo/vermelho).
class RiskIndicatorCard extends StatelessWidget {
  final RiskLevel riskLevel;
  final String cityName;
  final int casesCount;

  const RiskIndicatorCard({
    super.key,
    required this.riskLevel,
    required this.cityName,
    required this.casesCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.spacingXl),
      decoration: BoxDecoration(
        gradient: _getGradient(),
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        boxShadow: [
          BoxShadow(
            color: _getColor().withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Ícone de status
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingLg),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getIcon(),
              size: 64,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: AppConstants.spacingLg),

          // Título do risco
          Text(
            riskLevel.label,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: AppConstants.spacingSm),

          // Cidade
          Text(
            cityName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
          ),

          const SizedBox(height: AppConstants.spacingLg),

          // Contador de casos
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingLg,
              vertical: AppConstants.spacingMd,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppConstants.radiusFull),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.coronavirus_outlined, color: Colors.white),
                const SizedBox(width: AppConstants.spacingSm),
                Text(
                  '$casesCount casos registrados',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppConstants.spacingMd),

          // Descrição
          Text(
            riskLevel.description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
          ),
        ],
      ),
    );
  }

  LinearGradient _getGradient() {
    switch (riskLevel) {
      case RiskLevel.low:
        return AppColors.lowRiskGradient;
      case RiskLevel.medium:
        return AppColors.mediumRiskGradient;
      case RiskLevel.high:
        return AppColors.highRiskGradient;
    }
  }

  Color _getColor() {
    switch (riskLevel) {
      case RiskLevel.low:
        return AppColors.success;
      case RiskLevel.medium:
        return AppColors.warning;
      case RiskLevel.high:
        return AppColors.danger;
    }
  }

  IconData _getIcon() {
    switch (riskLevel) {
      case RiskLevel.low:
        return Icons.check_circle_outline_rounded;
      case RiskLevel.medium:
        return Icons.warning_amber_rounded;
      case RiskLevel.high:
        return Icons.error_outline_rounded;
    }
  }
}
