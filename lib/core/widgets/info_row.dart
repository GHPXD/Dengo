import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Widget de linha de informação padronizado.
///
/// Exibe um par label-valor em formato de linha, usado em modais
/// e cards de detalhes.
class InfoRow extends StatelessWidget {
  /// Rótulo da informação.
  final String label;

  /// Valor a ser exibido.
  final String value;

  /// Ícone opcional à esquerda do label.
  final IconData? icon;

  /// Cor do ícone.
  final Color? iconColor;

  /// Estilo do valor (opcional).
  final TextStyle? valueStyle;

  /// Se deve usar layout de coluna em vez de linha.
  final bool isColumn;

  /// Cria uma linha de informação.
  const InfoRow({
    required this.label,
    required this.value,
    super.key,
    this.icon,
    this.iconColor,
    this.valueStyle,
    this.isColumn = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isColumn) {
      return _buildColumnLayout();
    }
    return _buildRowLayout();
  }

  Widget _buildRowLayout() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 18,
                  color: iconColor ?? AppColors.textGrey,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          Flexible(
            child: Text(
              value,
              style: valueStyle ??
                  const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnLayout() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: iconColor ?? AppColors.textGrey,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: valueStyle ??
                const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
          ),
        ],
      ),
    );
  }
}
