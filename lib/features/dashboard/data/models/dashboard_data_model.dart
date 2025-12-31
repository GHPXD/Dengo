import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/utils/enums/risk_level.dart';
import '../../domain/entities/dashboard_data.dart';
import '../../domain/entities/historical_data.dart';
import '../../domain/entities/prediction_data.dart';

part 'dashboard_data_model.freezed.dart';
part 'dashboard_data_model.g.dart';

/// Model que representa a resposta do endpoint /api/v1/dashboard?city_id={id}.
///
/// JSON retornado pela API (estrutura PLANA):
/// ```json
/// {
///   "city": "Curitiba",
///   "geocode": "4106902",
///   "state": "PR",
///   "population": 1773733,
///   "current_temp": 21.52,
///   "min_temp": 20.64,
///   "max_temp": 22.07,
///   "weather_desc": "nublado",
///   "weather_icon": "04n",
///   "risk_level": "moderado",
///   "predicted_cases": 60,
///   "trend": "estavel",
///   "historical_data": [
///     {"week_number": 202550, "date": "2025-12-06", "cases": 5}
///   ],
///   "last_updated": null
/// }
/// ```
@freezed
class DashboardDataModel with _$DashboardDataModel {
  const DashboardDataModel._();

  /// Cria um modelo de dados do dashboard a partir dos campos da API.
  const factory DashboardDataModel({
    /// Nome da cidade
    @JsonKey(name: 'city') required String city,

    /// Código IBGE
    @JsonKey(name: 'geocode') required String geocode,

    /// UF (estado)
    @JsonKey(name: 'state') required String state,

    /// População
    @JsonKey(name: 'population') required int population,

    /// Nível de risco: baixo, moderado, alto, muito_alto
    @JsonKey(name: 'risk_level') required String riskLevel,

    /// Casos previstos
    @JsonKey(name: 'predicted_cases') required int predictedCases,

    /// Tendência: subindo, estavel, caindo
    @JsonKey(name: 'trend') required String trend,

    /// Dados históricos
    @JsonKey(name: 'historical_data')
    required List<HistoricalDataPointModel> historicalData,

    /// Temperatura atual (pode ser null)
    @JsonKey(name: 'current_temp') double? currentTemp,

    /// Temperatura mínima (pode ser null)
    @JsonKey(name: 'min_temp') double? minTemp,

    /// Temperatura máxima (pode ser null)
    @JsonKey(name: 'max_temp') double? maxTemp,

    /// Descrição do clima (pode ser null)
    @JsonKey(name: 'weather_desc') String? weatherDesc,

    /// Ícone do clima (pode ser null)
    @JsonKey(name: 'weather_icon') String? weatherIcon,

    /// Última atualização (pode ser null)
    @JsonKey(name: 'last_updated') String? lastUpdated,
  }) = _DashboardDataModel;

  /// Cria um modelo a partir de JSON da API.
  factory DashboardDataModel.fromJson(Map<String, dynamic> json) =>
      _$DashboardDataModelFromJson(json);

  /// Converte model (Data) para entity (Domain)
  DashboardData toEntity() {
    // Filtra dados com week_number=0 (dados estimados/fantasmas)
    // e converte historical_data para entities
    final historicalEntities = historicalData
        .where((point) => point.weekNumber > 0) // Remove dados fantasmas
        .map((point) {
      return HistoricalData(
        date: DateTime.tryParse(point.date) ?? DateTime.now(),
        cases: point.cases,
        avgTemperature: currentTemp ?? 25.0,
        avgHumidity: 60.0, // Valor padrão, API não retorna
      );
    }).toList();

    // CORREÇÃO: Usa a segunda semana do histórico (última completa)
    // A primeira semana pode ter dados parciais se a semana ainda não acabou
    // Ex: Se hoje é terça, a semana atual só tem 2 dias de dados
    final currentWeek = historicalEntities.length > 1
        ? historicalEntities[1] // Segunda é a última completa
        : historicalEntities.isNotEmpty
            ? historicalEntities.first
            : HistoricalData(
                date: DateTime.now(),
                cases: 0,
                avgTemperature: currentTemp ?? 25.0,
                avgHumidity: 60.0,
              );

    return DashboardData(
      historicalData: historicalEntities,
      prediction: PredictionData(
        estimatedCases: predictedCases,
        riskLevel: _parseRiskLevel(riskLevel),
        trend: trend,
        confidence: 0.50, // Modelo com R² negativo - confiança baixa/moderada
      ),
      currentWeek: currentWeek,
      cityPopulation: population,
      cityIbgeCode: geocode,
      cityName: city,
    );
  }

  /// Converte string do backend para enum RiskLevel
  RiskLevel _parseRiskLevel(String level) {
    switch (level.toLowerCase()) {
      case 'baixo':
      case 'low':
        return RiskLevel.low;
      case 'medio':
      case 'médio':
      case 'medium':
      case 'moderado':
        return RiskLevel.medium;
      case 'alto':
      case 'high':
      case 'muito_alto':
      case 'muito alto':
      case 'very_high':
        return RiskLevel.high;
      default:
        return RiskLevel.low;
    }
  }
}

/// Ponto de dados históricos (estrutura simples da API).
@freezed
class HistoricalDataPointModel with _$HistoricalDataPointModel {
  /// Cria um ponto de dados históricos.
  const factory HistoricalDataPointModel({
    /// Número da semana epidemiológica.
    @JsonKey(name: 'week_number') required int weekNumber,

    /// Data do registro.
    @JsonKey(name: 'date') required String date,

    /// Número de casos.
    @JsonKey(name: 'cases') required int cases,
  }) = _HistoricalDataPointModel;

  /// Cria um ponto de dados a partir de JSON.
  factory HistoricalDataPointModel.fromJson(Map<String, dynamic> json) =>
      _$HistoricalDataPointModelFromJson(json);
}