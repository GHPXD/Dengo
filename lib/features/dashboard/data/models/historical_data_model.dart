import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/historical_data.dart';

part 'historical_data_model.freezed.dart';
part 'historical_data_model.g.dart';

/// Model que representa dados históricos recebidos da API Python.
///
/// JSON REAL retornado pela API:
/// ```json
/// {
///   "data": "2025-12-04",
///   "casos": 26,
///   "temperatura_media": 18.1,
///   "umidade_media": 83.9
/// }
/// ```
@freezed
class HistoricalDataModel with _$HistoricalDataModel {
  const HistoricalDataModel._();

  const factory HistoricalDataModel({
    @JsonKey(name: 'data') required String data,
    @JsonKey(name: 'casos') required int casos,
    @JsonKey(name: 'temperatura_media') required double temperaturaMedia,
    @JsonKey(name: 'umidade_media') required double umidadeMedia,
  }) = _HistoricalDataModel;

  /// Cria [HistoricalDataModel] a partir do JSON da API
  factory HistoricalDataModel.fromJson(Map<String, dynamic> json) =>
      _$HistoricalDataModelFromJson(json);

  /// Converte model (Data) para entity (Domain)
  HistoricalData toEntity() {
    return HistoricalData(
      date: DateTime.parse(data),
      cases: casos,
      avgTemperature: temperaturaMedia,
      avgHumidity: umidadeMedia,
    );
  }
}
