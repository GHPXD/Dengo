import '../entities/heatmap_data.dart';

/// Repositório para obter dados do heatmap.
abstract class HeatmapRepository {
  /// Busca dados do heatmap para um estado.
  ///
  /// - [state]: Sigla do estado (ex: "PR")
  /// - [period]: Período - "week" ou "month"
  ///
  /// Retorna [HeatmapData] com lista de cidades e coordenadas.
  Future<HeatmapData> getHeatmapData({
    required String state,
    required String period,
  });
}
