import 'package:equatable/equatable.dart';

import '../../../../core/utils/enums/risk_level.dart';

/// Entidade que representa a predição gerada pela IA.
///
/// Essa predição é calculada pelo Backend Python usando:
/// - Dados climáticos do OpenWeather
/// - Modelo de Machine Learning (scikit-learn)
class PredictionData extends Equatable {
  /// Número estimado de casos
  final int estimatedCases;

  /// Nível de risco calculado pela IA
  final RiskLevel riskLevel;

  /// Tendência (estavel, crescente, decrescente)
  final String trend;

  /// Confiança da predição (0.0 - 1.0)
  /// - 0.9+: Alta confiança
  /// - 0.7-0.9: Média confiança
  /// - <0.7: Baixa confiança
  final double confidence;

  const PredictionData({
    required this.estimatedCases,
    required this.riskLevel,
    required this.trend,
    required this.confidence,
  });

  @override
  List<Object?> get props => [
        estimatedCases,
        riskLevel,
        trend,
        confidence,
      ];
}
