import '../../domain/entities/week_prediction.dart';

/// Model representando predição de uma semana (camada de dados).
///
/// Responsável por serialização/deserialização JSON da API.
class WeekPredictionModel extends WeekPrediction {
  const WeekPredictionModel({
    required super.weekNumber,
    required super.date,
    required super.predictedCases,
    required super.confidence,
    required super.lowerBound,
    required super.upperBound,
  });

  /// Cria model a partir de JSON da API
  factory WeekPredictionModel.fromJson(Map<String, dynamic> json) {
    return WeekPredictionModel(
      weekNumber: json['week_number'] as int,
      date: DateTime.parse(json['date'] as String),
      predictedCases: (json['predicted_cases'] as num).toDouble(),
      confidence: _parseConfidence(json['confidence'] as String),
      lowerBound: (json['lower_bound'] as num).toDouble(),
      upperBound: (json['upper_bound'] as num).toDouble(),
    );
  }

  /// Parseia string de confiança para enum
  static ConfidenceLevel _parseConfidence(String value) {
    switch (value.toLowerCase()) {
      case 'high':
        return ConfidenceLevel.high;
      case 'medium':
        return ConfidenceLevel.medium;
      case 'low':
        return ConfidenceLevel.low;
      default:
        return ConfidenceLevel.medium;
    }
  }

  /// Converte model para JSON
  Map<String, dynamic> toJson() {
    return {
      'week_number': weekNumber,
      'date': date.toIso8601String().split('T')[0],
      'predicted_cases': predictedCases,
      'confidence': confidence.name,
      'lower_bound': lowerBound,
      'upper_bound': upperBound,
    };
  }

  /// Converte para entidade de domínio
  WeekPrediction toEntity() {
    return WeekPrediction(
      weekNumber: weekNumber,
      date: date,
      predictedCases: predictedCases,
      confidence: confidence,
      lowerBound: lowerBound,
      upperBound: upperBound,
    );
  }
}
