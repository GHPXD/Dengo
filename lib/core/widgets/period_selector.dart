import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Opção de período para o seletor.
class PeriodOption {
  /// Valor interno (ex: '7days', '30days').
  final String value;

  /// Texto exibido (ex: '7 Dias', '30 Dias').
  final String label;

  /// Cria uma opção de período.
  const PeriodOption({
    required this.value,
    required this.label,
  });
}

/// Widget seletor de período padronizado.
///
/// Exibe chips/botões para selecionar períodos de tempo
/// (7 dias, 30 dias, 90 dias, etc.).
class PeriodSelector extends StatelessWidget {
  /// Período atualmente selecionado.
  final String selectedPeriod;

  /// Lista de opções de período disponíveis.
  final List<PeriodOption> options;

  /// Callback quando um período é selecionado.
  final ValueChanged<String> onChanged;

  /// Padding horizontal do container.
  final double horizontalPadding;

  /// Espaçamento entre os chips.
  final double spacing;

  /// Cria um seletor de período.
  const PeriodSelector({
    required this.selectedPeriod,
    required this.options,
    required this.onChanged,
    super.key,
    this.horizontalPadding = 24,
    this.spacing = 12,
  });

  /// Cria um seletor com opções padrão em semanas (4, 8, 12 semanas).
  /// Nota: Dados epidemiológicos são SEMANAIS, não diários.
  factory PeriodSelector.standard({
    required String selectedPeriod,
    required ValueChanged<String> onChanged,
  }) {
    return PeriodSelector(
      selectedPeriod: selectedPeriod,
      onChanged: onChanged,
      options: const [
        PeriodOption(value: '7days', label: '4 Semanas'),
        PeriodOption(value: '30days', label: '8 Semanas'),
        PeriodOption(value: '90days', label: '12 Semanas'),
      ],
    );
  }

  /// Cria um seletor com opções de semanas.
  factory PeriodSelector.weeks({
    required int selectedWeeks,
    required ValueChanged<int> onChanged,
    List<int> weekOptions = const [1, 2, 4],
  }) {
    return PeriodSelector(
      selectedPeriod: selectedWeeks.toString(),
      onChanged: (value) => onChanged(int.parse(value)),
      options: weekOptions
          .map((w) => PeriodOption(
                value: w.toString(),
                label: '$w ${w == 1 ? 'Semana' : 'Semanas'}',
              ))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Row(
        children: options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          final isSelected = selectedPeriod == option.value;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: index == 0 ? 0 : spacing / 2,
                right: index == options.length - 1 ? 0 : spacing / 2,
              ),
              child: _PeriodChip(
                label: option.label,
                isSelected: isSelected,
                onTap: () => onChanged(option.value),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textGrey,
          ),
        ),
      ),
    );
  }
}
