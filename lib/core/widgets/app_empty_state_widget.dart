import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Widget de estado vazio padronizado.
///
/// Exibe uma mensagem quando não há dados ou nenhuma cidade está selecionada.
class AppEmptyStateWidget extends StatelessWidget {
  /// Mensagem principal a ser exibida.
  final String message;

  /// Mensagem secundária (opcional).
  final String? subtitle;

  /// Ícone a ser exibido.
  final IconData icon;

  /// Ação opcional (botão).
  final VoidCallback? onAction;

  /// Texto do botão de ação.
  final String? actionText;

  /// Cria um widget de estado vazio.
  const AppEmptyStateWidget({
    super.key,
    this.message = 'Nenhum dado disponível',
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.onAction,
    this.actionText,
  });

  /// Cria um widget para quando nenhuma cidade está selecionada.
  factory AppEmptyStateWidget.noCity({VoidCallback? onSelectCity}) {
    return AppEmptyStateWidget(
      message: 'Nenhuma cidade selecionada',
      subtitle: 'Selecione uma cidade para ver os dados',
      icon: Icons.location_off,
      onAction: onSelectCity,
      actionText: 'Selecionar Cidade',
    );
  }

  /// Cria um widget para quando não há dados no período.
  factory AppEmptyStateWidget.noData() {
    return const AppEmptyStateWidget(
      message: 'Sem dados para este período',
      subtitle: 'Tente selecionar um período diferente',
      icon: Icons.bar_chart_outlined,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onAction != null && actionText != null) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_location_alt),
                label: Text(actionText!),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
