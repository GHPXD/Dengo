import '../../domain/entities/prediction_response.dart';
import 'historical_week_model.dart';
import 'week_prediction_model.dart';

/// Model representando resposta completa da API de predições.
///
/// Responsável por serialização/deserialização JSON da API.
class PredictionResponseModel extends PredictionResponse {
  /// Construtor padrão do Model.
  const PredictionResponseModel({
    required super.city,
    required super.geocode,
    required super.state,
    required super.historicalData,
    required super.predictions,
    required super.trend,
    required super.trendPercentage,
    required super.generatedAt,
    required super.modelName,
    required super.modelAccuracy,
    required super.modelMae,
  });

  /// Cria model a partir de JSON da API
  factory PredictionResponseModel.fromJson(Map<String, dynamic> json) {
    // Cast seguro para evitar 'avoid_dynamic_calls'
    final metadata = json['model_metadata'] as Map<String, dynamic>;

    return PredictionResponseModel(
      city: json['city'] as String,
      geocode: json['geocode'] as String,
      state: json['state'] as String,
      historicalData: (json['historical_data'] as List<dynamic>)
          .map((e) => HistoricalWeekModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      predictions: (json['predictions'] as List<dynamic>)
          .map((e) => WeekPredictionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      trend: _parseTrend(json['trend'] as String),
      trendPercentage: (json['trend_percentage'] as num).toDouble(),
      generatedAt: DateTime.parse(json['generated_at'] as String),
      modelName: metadata['model_name'] as String,
      modelAccuracy: (metadata['accuracy'] as num).toDouble(),
      modelMae: (metadata['mae'] as num).toDouble(),
    );
  }

  /// Parseia string de tendência para enum
  static TrendType _parseTrend(String value) {
    switch (value.toLowerCase()) {
      case 'ascending':
        return TrendType.ascending;
      case 'descending':
        return TrendType.descending;
      case 'stable':
        return TrendType.stable;
      default:
        return TrendType.stable;
    }
  }

  /// Converte model para JSON
  Map<String, dynamic> toJson() {
    return {
      'city': city,
      'geocode': geocode,
      'state': state,
      'historical_data': historicalData
          .map((h) => (h as HistoricalWeekModel).toJson())
          .toList(),
      'predictions': predictions
          .map((p) => (p as WeekPredictionModel).toJson())
          .toList(),
      'trend': trend.name,
      'trend_percentage': trendPercentage,
      'generated_at': generatedAt.toIso8601String(),
      'model_metadata': {
        'model_name': modelName,
        'accuracy': modelAccuracy,
        'mae': modelMae,
      },
    };
  }

  /// Converte para entidade de domínio
  PredictionResponse toEntity() {
    return PredictionResponse(
      city: city,
      geocode: geocode,
      state: state,
      historicalData: historicalData
          .map((h) => (h as HistoricalWeekModel).toEntity())
          .toList(),
      predictions: predictions
          .map((p) => (p as WeekPredictionModel).toEntity())
          .toList(),
      trend: trend,
      trendPercentage: trendPercentage,
      generatedAt: generatedAt,
      modelName: modelName,
      modelAccuracy: modelAccuracy,
      modelMae: modelMae,
    );
  }
}