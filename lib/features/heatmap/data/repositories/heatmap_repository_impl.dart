import '../../domain/entities/heatmap_data.dart';
import '../../domain/repositories/heatmap_repository.dart';
import '../datasources/heatmap_remote_datasource.dart';

/// Implementação do repositório de heatmap.
class HeatmapRepositoryImpl implements HeatmapRepository {
  final HeatmapRemoteDataSource _remoteDataSource;

  HeatmapRepositoryImpl({
    required HeatmapRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  Future<HeatmapData> getHeatmapData({
    required String state,
    required String period,
  }) async {
    try {
      final model = await _remoteDataSource.getHeatmapData(
        state: state,
        period: period,
      );
      return model.toEntity();
    } catch (e) {
      // Propaga a exceção para ser tratada pelo provider
      rethrow;
    }
  }
}
