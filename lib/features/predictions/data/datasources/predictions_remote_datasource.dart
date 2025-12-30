import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../../../../core/network/api_client.dart';
import '../models/prediction_response_model.dart';

/// Data source remoto para buscar predições da API.
///
/// Responsável pela comunicação HTTP com o backend FastAPI.
class PredictionsRemoteDataSource {
  final ApiClient apiClient;
  final Logger _logger = Logger();

  PredictionsRemoteDataSource({required this.apiClient});

  /// Busca predições de dengue para um município.
  ///
  /// Endpoint: POST /api/v1/predictions/predict
  ///
  /// Throws:
  /// - DioException em caso de erro de rede/servidor
  Future<PredictionResponseModel> getPredictions({
    required String geocode,
    required int weeksAhead,
  }) async {
    try {
      _logger.d('🎯 Buscando predições: geocode=$geocode, weeks=$weeksAhead');

      final response = await apiClient.post(
        '/predictions/predict',
        data: {
          'geocode': geocode,
          'weeks_ahead': weeksAhead,
        },
      );

      _logger.i('✅ Predições recebidas: ${response.data['city']}');

      return PredictionResponseModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _logger.e('❌ Erro ao buscar predições: ${e.message}', error: e);
      rethrow;
    }
  }
}
