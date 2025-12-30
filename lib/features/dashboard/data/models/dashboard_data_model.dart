import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/dashboard_data.dart';
import 'historical_data_model.dart';
import 'prediction_data_model.dart';

part 'dashboard_data_model.freezed.dart';
part 'dashboard_data_model.g.dart';

/// Model que representa a resposta completa do endpoint /api/v1/dashboard/{city_id}.
///
/// JSON REAL retornado pela API Python:
/// ```json
/// {
///   "cidade": {
///     "ibge_codigo": "4106902",
///     "nome": "Curitiba",
///     "populacao": 1963726
///   },
///   "dados_historicos": [
///     {
///       "data": "2025-12-04",
///       "casos": 26,
///       "temperatura_media": 18.1,
///       "umidade_media": 83.9
///     }
///   ],
///   "predicao": {
///     "casos_estimados": 30,
///     "nivel_risco": "baixo",
///     "tendencia": "estavel",
///     "confianca": 0.5
///   }
/// }
/// ```
@freezed
class DashboardDataModel with _$DashboardDataModel {
  const DashboardDataModel._();

  /// Cria uma instância de [DashboardDataModel] com os dados necessários.
  const factory DashboardDataModel({
    @JsonKey(name: 'cidade') required CityInfoModel cityInfo,
    @JsonKey(name: 'dados_historicos')
    required List<HistoricalDataModel> historicalData,
    @JsonKey(name: 'predicao') required PredictionDataModel prediction,
  }) = _DashboardDataModel;

  /// Cria [DashboardDataModel] a partir do JSON da API
  factory DashboardDataModel.fromJson(Map<String, dynamic> json) =>
      _$DashboardDataModelFromJson(json);

  /// Converte model (Data) para entity (Domain)
  DashboardData toEntity() {
    final historicalEntities =
        historicalData.map((model) => model.toEntity()).toList();

    return DashboardData(
      historicalData: historicalEntities,
      prediction: prediction.toEntity(),
      currentWeek: historicalEntities.last,
      cityPopulation: cityInfo.population,
      cityIbgeCode: cityInfo.ibgeCode,
      cityName: cityInfo.nome,
    );
  }
}

/// Informações básicas da cidade na resposta da API
@freezed
class CityInfoModel with _$CityInfoModel {
  /// Cria instância de [CityInfoModel]
  const factory CityInfoModel({
    @JsonKey(name: 'ibge_codigo') required String ibgeCode,
    @JsonKey(name: 'nome') required String nome,
    @JsonKey(name: 'populacao') required int population,
  }) = _CityInfoModel;

  /// Cria [CityInfoModel] a partir do JSON
  factory CityInfoModel.fromJson(Map<String, dynamic> json) =>
      _$CityInfoModelFromJson(json);
}