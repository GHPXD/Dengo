import 'package:equatable/equatable.dart';

import 'historical_data.dart';
import 'prediction_data.dart';

/// Entidade agregadora que combina dados históricos + predição.
///
/// Representa a resposta completa do endpoint GET /api/dashboard
/// da API Python do Dengo.
class DashboardData extends Equatable {
  /// Dados históricos das últimas 12-24 semanas
  final List<HistoricalData> historicalData;

  /// Predição da IA para a próxima semana
  final PredictionData prediction;

  /// Dados da semana atual (última entrada do histórico)
  final HistoricalData currentWeek;

  /// População da cidade (para cálculos)
  final int cityPopulation;

  /// Código IBGE da cidade
  final String cityIbgeCode;

  /// Cria instância de [DashboardData] com dados completos
  const DashboardData({
    required this.historicalData,
    required this.prediction,
    required this.currentWeek,
    required this.cityPopulation,
    required this.cityIbgeCode,
  });

  /// Total de casos confirmados até a semana atual
  int get totalConfirmedCases {
    return historicalData.fold<int>(
      0,
      (sum, data) => sum + data.cases,
    );
  }

  /// Casos novos na última semana (comparado com semana anterior)
  int get newCasesThisWeek {
    if (historicalData.length < 2) return currentWeek.cases;

    final previousWeek = historicalData[historicalData.length - 2];
    return currentWeek.cases - previousWeek.cases;
  }

  @override
  List<Object?> get props => [
        historicalData,
        prediction,
        currentWeek,
        cityPopulation,
        cityIbgeCode,
      ];
}
