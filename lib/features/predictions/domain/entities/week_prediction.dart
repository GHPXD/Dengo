import 'package:equatable/equatable.dart';

/// Nível de confiança da predição.
enum ConfidenceLevel {
  /// Confiança alta: o modelo tem alta certeza sobre esta previsão.
  high,

  /// Confiança média: previsão padrão, com margem de erro aceitável.
  medium,

  /// Confiança baixa: previsão incerta, margem de erro ampla.
  low;

  /// Retorna o nome amigável para exibição na UI.
  String get displayName {
    switch (this) {
      case ConfidenceLevel.high:
        return 'Alta';
      case ConfidenceLevel.medium:
        return 'Média';
      case ConfidenceLevel.low:
        return 'Baixa';
    }
  }
}

/// Entidade representando a predição de uma semana futura.
///
/// Usado para exibir a linha azul no gráfico (predições IA).
class WeekPrediction extends Equatable {
  /// Número da semana epidemiológica (1-53).
  final int weekNumber;

  /// Data de início da semana (domingo).
  final DateTime date;

  /// Casos preditos pela IA.
  final double predictedCases;

  /// Nível de confiança da predição.
  final ConfidenceLevel confidence;

  /// Limite inferior do intervalo de confiança.
  final double lowerBound;

  /// Limite superior do intervalo de confiança.
  final double upperBound;

  /// Construtor padrão com todos os campos obrigatórios.
  const WeekPrediction({
    required this.weekNumber,
    required this.date,
    required this.predictedCases,
    required this.confidence,
    required this.lowerBound,
    required this.upperBound,
  });

  @override
  List<Object?> get props => [
        weekNumber,
        date,
        predictedCases,
        confidence,
        lowerBound,
        upperBound,
      ];

  @override
  String toString() {
    return 'WeekPrediction(week: $weekNumber, cases: $predictedCases, confidence: ${confidence.displayName})';
  }
}