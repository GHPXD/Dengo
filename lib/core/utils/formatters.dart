/// Utilitários de formatação compartilhados.
///
/// Contém funções para formatar números, datas e outros valores
/// de forma consistente em toda a aplicação.
library;

/// Formata um número de população para exibição amigável.
///
/// Exemplos:
/// - 1500000 → "1.5M"
/// - 150000 → "150k"
/// - 1500 → "1k"
/// - 150 → "150"
String formatPopulation(int population) {
  if (population >= 1000000) {
    return '${(population / 1000000).toStringAsFixed(1)}M';
  } else if (population >= 1000) {
    return '${(population / 1000).toStringAsFixed(0)}k';
  }
  return population.toString();
}

/// Formata um número com separadores de milhar (ponto).
///
/// Exemplo: 1500000 → "1.500.000"
String formatNumber(int number) {
  return number.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]}.',
      );
}

/// Formata um número decimal com casas decimais específicas.
///
/// Exemplo: formatDecimal(1234.5678, 2) → "1234.57"
String formatDecimal(double value, [int decimalPlaces = 1]) {
  return value.toStringAsFixed(decimalPlaces);
}

/// Formata taxa de incidência por 100 mil habitantes.
///
/// Exemplo: formatIncidence(150, 100000) → "150.0"
String formatIncidence(int cases, int population) {
  if (population <= 0) return '0.0';
  return (cases / population * 100000).toStringAsFixed(1);
}

/// Formata variação percentual com sinal.
///
/// Exemplo: formatPercentageChange(25.5) → "+25.5%"
String formatPercentageChange(double percentage) {
  final sign = percentage >= 0 ? '+' : '';
  return '$sign${percentage.toStringAsFixed(1)}%';
}

/// Formata número de casos com texto descritivo.
///
/// Exemplo: formatCases(150) → "150 casos"
String formatCases(int cases) {
  return '$cases ${cases == 1 ? 'caso' : 'casos'}';
}
