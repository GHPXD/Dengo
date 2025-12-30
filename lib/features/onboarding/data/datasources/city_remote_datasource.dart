import 'package:dio/dio.dart';

import '../models/city_model.dart';

/// Data Source remoto para buscar cidades da API.
///
/// Responsável apenas por fazer requisições HTTP e retornar dados brutos.
/// Não trata erros de negócio, apenas exceções técnicas (IOException, etc).
abstract class CityRemoteDataSource {
  /// Busca cidades na API por query.
  Future<List<CityModel>> searchCities(String query);

  /// Busca cidade específica por código IBGE.
  Future<CityModel> getCityByIbgeCode(String ibgeCode);
}

/// Implementation of [CityRemoteDataSource] using Dio.
class CityRemoteDataSourceImpl implements CityRemoteDataSource {
  /// Dio HTTP client for API requests.
  final Dio dio;

  /// Creates a [CityRemoteDataSourceImpl] with a Dio client.
  CityRemoteDataSourceImpl(this.dio);

  @override
  Future<List<CityModel>> searchCities(String query) async {
    try {
      // Chama endpoint real da API: /cities/search
      final response = await dio.get(
        '/cities/search',
        queryParameters: {
          'q': query,
          'uf': 'PR', // Buscando apenas Paraná por enquanto
          'limit': 20,
        },
      );

      // CORREÇÃO: Cast explícito de response.data para Map antes de acessar a chave
      final data = response.data as Map<String, dynamic>;
      final List<dynamic> results = data['results'] as List<dynamic>;

      // Converte para CityModel
      return results
          .map((json) => CityModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Em caso de erro, relança para o Repository tratar
      rethrow;
    }
  }

  @override
  Future<CityModel> getCityByIbgeCode(String ibgeCode) async {
    try {
      // Chama endpoint real da API: /cities/{ibge_code}
      final response = await dio.get('/cities/$ibgeCode');

      // CORREÇÃO: Cast explícito para garantir tipagem segura
      final data = response.data as Map<String, dynamic>;

      // Converte JSON para CityModel
      return CityModel.fromJson(data);
    } catch (e) {
      // Em caso de erro, relança para o Repository tratar
      rethrow;
    }
  }
}