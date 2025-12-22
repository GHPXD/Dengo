import 'dart:math';

/// Extensões úteis para números (int e double).
///
/// Facilitam formatações comuns de números no contexto da aplicação.
extension DoubleExtensions on double {
  /// Formata número como porcentagem.
  ///
  /// Exemplo: 0.85.toPercentage() -> "85%"
  String toPercentage({int decimals = 0}) {
    return '${(this * 100).toStringAsFixed(decimals)}%';
  }

  /// Formata número com vírgula decimal (padrão brasileiro).
  ///
  /// Exemplo: 1234.56.toFormattedString() -> "1.234,56"
  String toFormattedString({int decimals = 2}) {
    final formatted = toStringAsFixed(decimals);
    final parts = formatted.split('.');

    // Adiciona separador de milhar
    final integerPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );

    if (parts.length > 1) {
      return '$integerPart,${parts[1]}';
    }
    return integerPart;
  }

  /// Arredonda para N casas decimais.
  ///
  /// Exemplo: 3.14159.roundTo(2) -> 3.14
  double roundTo(int decimals) {
    final multiplier = pow(10.0, decimals).toDouble();
    return (this * multiplier).round() / multiplier;
  }
}

extension IntExtensions on int {
  /// Formata inteiro com separador de milhar (ponto).
  ///
  /// Exemplo: 1234567.toFormattedString() -> "1.234.567"
  String toFormattedString() {
    return toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  /// Retorna forma plural de uma palavra baseada no número.
  ///
  /// Exemplo:
  /// 1.pluralize('caso', 'casos') -> "1 caso"
  /// 5.pluralize('caso', 'casos') -> "5 casos"
  String pluralize(String singular, String plural) {
    return '$this ${this == 1 ? singular : plural}';
  }

  /// Verifica se o número está dentro de um intervalo (inclusivo).
  bool inRange(int min, int max) {
    return this >= min && this <= max;
  }
}
