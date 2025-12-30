import 'package:equatable/equatable.dart';

import 'historical_week.dart';
import 'week_prediction.dart';

/// Tendência dos casos de dengue.
enum TrendType {
  /// Tendência de aumento no número de casos.
  ascending,

  /// Número de casos estável.
  stable,

  /// Tendência de queda no número de casos.
  descending;

  /// Retorna o nome amigável para exibição na UI.
  String get displayName {
    switch (this) {
      case TrendType.ascending:
        return 'Crescente';
      case TrendType.stable:
        return 'Estável';
      case TrendType.descending:
        return 'Decrescente';
    }
  }

  /// Retorna o ícone (emoji) associado à tendência.
  String get icon {
    switch (this) {
      case TrendType.ascending:
        return '📈';
      case TrendType.stable:
        return '➡️';
      case TrendType.descending:
        return '📉';
    }
  }
}

/// Entidade representando a resposta completa da API de predições.
///
/// Combina dados históricos (linha verde) e predições futuras (linha azul).
class PredictionResponse extends Equatable {
  /// Nome do município.
  final String city;

  /// Código IBGE do município (7 dígitos).
  final String geocode;

  /// Sigla do estado (PR).
  final String state;

  /// Dados históricos das últimas 12 semanas (linha verde).
  final List<HistoricalWeek> historicalData;

  /// Predições das próximas 1-4 semanas (linha azul).
  final List<WeekPrediction> predictions;

  /// Tendência geral dos casos.
  final TrendType trend;

  /// Variação percentual da tendência.
  final double trendPercentage;

  /// Timestamp de geração da predição.
  final DateTime generatedAt;

  /// Nome do modelo de IA.
  final String modelName;

  /// Acurácia do modelo (0.0 - 1.0).
  final double modelAccuracy;

  /// MAE (Mean Absolute Error) do modelo.
  final double modelMae;

  /// Construtor padrão com todos os campos obrigatórios.
  const PredictionResponse({
    required this.city,
    required this.geocode,
    required this.state,
    required this.historicalData,
    required this.predictions,
    required this.trend,
    required this.trendPercentage,
    required this.generatedAt,
    required this.modelName,
    required this.modelAccuracy,
    required this.modelMae,
  });

  @override
  List<Object?> get props => [
        city,
        geocode,
        state,
        historicalData,
        predictions,
        trend,
        trendPercentage,
        generatedAt,
        modelName,
        modelAccuracy,
        modelMae,
      ];

  /// Total de semanas no gráfico (histórico + predições).
  int get totalWeeks => historicalData.length + predictions.length;

  /// Maior valor de casos (para escala do gráfico).
  double get maxCases {
    final historicalMax = historicalData.isEmpty
        ? 0.0
        : historicalData
            .map((h) => h.cases.toDouble())
            .reduce((a, b) => a > b ? a : b);

    final predictionsMax = predictions.isEmpty
        ? 0.0
        : predictions
            .map((p) => p.predictedCases)
            .reduce((a, b) => a > b ? a : b);

    return historicalMax > predictionsMax ? historicalMax : predictionsMax;
  }

  @override
  String toString() {
    return 'PredictionResponse($city, trend: ${trend.displayName}, historical: ${historicalData.length}, predictions: ${predictions.length})';
  }
}