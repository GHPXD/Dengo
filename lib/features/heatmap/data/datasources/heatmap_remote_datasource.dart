import '../../../../core/network/api_client.dart';
import '../models/heatmap_data_model.dart';

/// Data source para buscar dados do heatmap via API.
class HeatmapRemoteDataSource {
  final ApiClient _apiClient;

  /// Construtor que recebe o [ApiClient] via injeção de dependência.
  HeatmapRemoteDataSource({required ApiClient apiClient})
      : _apiClient = apiClient;

  /// Busca dados do heatmap da API.
  ///
  /// - [state]: Sigla do estado (ex: "PR")
  /// - [period]: Período - "week" ou "month"
  ///
  /// Retorna [HeatmapDataModel] com lista de cidades.
  Future<HeatmapDataModel> getHeatmapData({
    required String state,
    required String period,
  }) async {
    final response = await _apiClient.get(
      '/heatmap',
      queryParameters: {
        'state': state,
        'period': period,
      },
    );

    return HeatmapDataModel.fromJson(response.data as Map<String, dynamic>);
  }
}