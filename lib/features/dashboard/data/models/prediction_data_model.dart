import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/utils/enums/risk_level.dart';
import '../../domain/entities/prediction_data.dart';

part 'prediction_data_model.freezed.dart';
part 'prediction_data_model.g.dart';

/// Model que representa a predição da IA recebida da API Python.
///
/// JSON REAL retornado pela API:
/// ```json
/// {
///   "casos_estimados": 30,
///   "nivel_risco": "baixo",
///   "tendencia": "estavel",
///   "confianca": 0.5
/// }
/// ```
@freezed
class PredictionDataModel with _$PredictionDataModel {
  const PredictionDataModel._();

  const factory PredictionDataModel({
    @JsonKey(name: 'casos_estimados') required int casosEstimados,
    @JsonKey(name: 'nivel_risco') required String nivelRisco,
    @JsonKey(name: 'tendencia') required String tendencia,
    @JsonKey(name: 'confianca') required double confianca,
  }) = _PredictionDataModel;

  /// Cria [PredictionDataModel] a partir do JSON da API
  factory PredictionDataModel.fromJson(Map<String, dynamic> json) =>
      _$PredictionDataModelFromJson(json);

  /// Converte model (Data) para entity (Domain)
  PredictionData toEntity() {
    return PredictionData(
      estimatedCases: casosEstimados,
      riskLevel: _parseRiskLevel(nivelRisco),
      trend: tendencia,
      confidence: confianca,
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
        return RiskLevel.medium;
      case 'alto':
      case 'high':
      case 'muito_alto':
      case 'muito alto':
      case 'very_high':
        return RiskLevel.high;
      default:
        return RiskLevel.medium;
    }
  }
}
