import 'package:equatable/equatable.dart';

/// Entidade representando dados históricos de uma semana epidemiológica.
///
/// Usado para exibir a linha verde no gráfico (casos reais confirmados).
class HistoricalWeek extends Equatable {
  /// Número da semana epidemiológica (1-53).
  final int weekNumber;

  /// Data de início da semana (domingo).
  final DateTime date;

  /// Casos confirmados de dengue nesta semana.
  final int cases;

  /// Construtor padrão com todos os campos obrigatórios.
  const HistoricalWeek({
    required this.weekNumber,
    required this.date,
    required this.cases,
  });

  @override
  List<Object?> get props => [weekNumber, date, cases];

  @override
  String toString() {
    return 'HistoricalWeek(week: $weekNumber, date: ${date.toIso8601String()}, cases: $cases)';
  }
}