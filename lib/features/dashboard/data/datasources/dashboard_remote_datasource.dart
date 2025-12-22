import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../models/dashboard_data_model.dart';

/// DataSource para comunicação com a API Python do Dengo.
///
/// A API Python orquestra:
/// - Busca de dados climáticos (OpenWeather)
/// - Processamento de predição com IA (scikit-learn)
abstract class DashboardRemoteDataSource {
  /// Busca dados completos do dashboard.
  ///
  /// Endpoint: GET /api/v1/dashboard?city_id={cityId}
  ///
  /// Exemplo de resposta:
  /// ```json
  /// {
  ///   "cidade": {"ibge_codigo": "4106902", "nome": "Curitiba", "populacao": 1963726},
  ///   "dados_historicos": [{"data": "2025-12-04", "casos": 26, ...}],
  ///   "predicao": {"casos_estimados": 30, "nivel_risco": "baixo", ...}
  /// }
  /// ```
  Future<DashboardDataModel> getDashboardData(String cityId);
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final ApiClient apiClient;

  DashboardRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<DashboardDataModel> getDashboardData(String cityId) async {
    try {
      // Endpoint correto: GET /dashboard?city_id={cityId} (query param, não path)
      final response = await apiClient.dio.get(
        '/dashboard',
        queryParameters: {'city_id': cityId},
      );

      return DashboardDataModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Cidade não encontrada no servidor');
      } else if (e.response?.statusCode == 500) {
        throw Exception('Erro interno do servidor');
      } else {
        throw Exception('Erro ao buscar dados: ${e.message}');
      }
    } catch (e) {
      throw Exception('Erro desconhecido: $e');
    }
  }
}
